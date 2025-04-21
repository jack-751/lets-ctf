# 实践：识别与修复简单漏洞

## 题目描述

在本实践环节，你将审计一个简单的 Sui Move 合约 chapter_2::simple_challenge，目标是识别其中的漏洞并提出修复建议。合约实现了一个简单的“计数挑战”：用户可以通过提交计数（increment_count）来增加计数器，达到目标值后领取奖励（claim_reward）。奖励是共享的，任何人都可以领取。然而，合约存在一些隐藏漏洞，其中一个可能导致运行时报错，你需要找到这些漏洞，分析其影响，并提出修复建议。

## 示例代码

以下是 chapter_2::simple_challenge 模块的代码：

move

```text
module chapter_2::simple_challenge {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;

    public struct Challenge has key {
        id: UID,
        owner: address,
        count: u64,
        target_count: u64,
        reward: u64,
        total_rewards_claimed: u64,
        total_attempts: u64,
    }

    public struct RewardEvent has copy, drop {
        reward: u64,
    }

    fun init(ctx: &mut TxContext) {
        let challenge = Challenge {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            count: 0,
            target_count: 10,
            reward: 1000,
            total_rewards_claimed: 0,
            total_attempts: 0,
        };
        transfer::share_object(challenge);
    }

    public entry fun increment_count(challenge: &mut Challenge) {
        challenge.total_attempts = challenge.total_attempts + 1;
        challenge.count = challenge.count + 1;
    }

    public entry fun claim_reward(challenge: &mut Challenge, ctx: &mut TxContext) {
        if (challenge.count >= challenge.target_count) {
            challenge.total_rewards_claimed = challenge.total_rewards_claimed + challenge.reward;
            event::emit(RewardEvent { reward: challenge.reward });
            challenge.count = 0;
        };
    }
}
```