# 实践：签到挑战

## 题目描述
在本实践环节，你将分析一个 Sui Move 签到合约，通过计算哈希值调用函数，获取隐藏的 flag。flag 是一个格式为 `CTF{xxx}` 的字符串，将在正确输入时通过事件输出。目标是体验 Move 代码分析和基本 CTF 解题流程。

## 示例代码
以下是待分析的 Move 合约：

github: [chapter_1](https://github.com/hoh-zone/lets-ctf/tree/main/src/ctfbook/chapter_1/challenge/chapter_1)

```move
module chapter_1::check_in {
    use std::string::{Self, String};
    use std::bcs;
    use std::hash::sha3_256;
    use sui::event;

    //testnet
    //PackageID:0x335297860a807291254b20f8a0dea30d72d5e17d2e6f8058e42d5b9c72f0f0ef
    public struct FlagEvent has copy, drop {
        sender: address,
        flag: String,
        success: bool
    }

    public entry fun get_flag(
        flag: vector<u8>,
        github_id: String,
        ctx: &mut TxContext
    ) {
        let mut bcs_input = bcs::to_bytes(&string::utf8(b"LetsMoveCTF"));
        vector::append<u8>(&mut bcs_input, *github_id.as_bytes());
        let expected_hash = sha3_256(bcs_input);

        if (flag == expected_hash) {
            event::emit(FlagEvent {
                sender: tx_context::sender(ctx),
                flag: string::utf8(b"CTF{WelcomeToMoveCTF}"),
                success: true
            });
        } else {
            event::emit(FlagEvent {
                sender: tx_context::sender(ctx),
                flag: string::utf8(b"Try again!"),
                success: false
            });
        }
    }
}
```

## 任务目标
阅读代码，理解哈希验证逻辑。

计算正确的 flag 输入并运行代码，获取 flag。

## 解题思路
1、找到如何获取flag的代码块：
```move
##其中 `flag == expected_hash` 为获取flag的条件
if (flag == expected_hash) {
    event::emit(FlagEvent {
        sender: tx_context::sender(ctx),
        flag: string(b"CTF{WelcomeToMoveCTF}"),
        success: true
    });
} else {
    event::emit(FlagEvent {
        sender: tx_context::sender(ctx),
        flag: string(b"Try again!"),
        success: false
    });
}
```
2、如何满足 `flag == expected_hash` 条件？
```move
let mut bcs_input = bcs::to_bytes(&string(b"LetsMoveCTF"));
vector::append<u8>(&mut bcs_input, *github_id.as_bytes());
let expected_hash = sha3_256(bcs_input);
```
代码块中 expected_hash 为 `LetsMoveCTF` + 用户输入的`github_id` 转换为bytes然后sha3_256 进行编码，所以flag传入也需要是expected_hash的这个结果。

3、进行解题

这里采用的是合约的方式进行解题。

github: [solve_chapter_1](https://github.com/hoh-zone/lets-ctf/tree/main/src/ctfbook/chapter_1/challenge/solve_chapter_1)
首先创建合约:

`sui move new solve_chapter_1 && cd solve_chapter_1`

修改 `Move.toml` 文件导入题目合约,如果是本地与题目同目录则添加 `local` 方式:
```
[package]
name = "solve_chapter_1"
edition = "2024.beta" # edition = "legacy" to use legacy (pre-2024) Move
# license = ""           # e.g., "MIT", "GPL", "Apache 2.0"
# authors = ["..."]      # e.g., ["Joe Smith (joesmith@noemail.com)", "John Snow (johnsnow@noemail.com)"]

[dependencies]
chapter_1 = { local = "../chapter_1" }

# For remote import, use the `{ git = "...", subdir = "...", rev = "..." }`.
# Revision can be a branch, a tag, and a commit hash.
# MyRemotePackage = { git = "https://some.remote/host.git", subdir = "remote/path", rev = "main" }

# For local dependencies use `local = path`. Path is relative to the package root
# Local = { local = "../path/to" }

# To resolve a version conflict and force a specific version for dependency
# override use `override = true`
# Override = { local = "../conflicting/version", override = true }

[addresses]
solve_chapter_1 = "0x0"

# Named addresses will be accessible in Move as `@name`. They're also exported:
# for example, `std = "0x1"` is exported by the Standard Library.
# alice = "0xA11CE"

[dev-dependencies]
# The dev-dependencies section allows overriding dependencies for `--test` and
# `--dev` modes. You can introduce test-only dependencies here.
# Local = { local = "../path/to/dev-build" }

[dev-addresses]
# The dev-addresses section allows overwriting named addresses for the `--test`
# and `--dev` modes.
# alice = "0xB0B"

```

然后编写解题合约 `solve_chapter_1.move`:

```move
module solve_chapter_1::solve{
    use chapter_1::check_in::get_flag;
    use std::string;
    use std::bcs;
    use std::hash::sha3_256;

    //testnet
    //PackageID: 0xef6b4139ec1b0fda23e06c4a30c9e91150b72c38530e4517152e591001c5c433 
    public entry fun solve_get_flag(ctx: &mut TxContext){
        let github_id = string::utf8(b"hoh-zone");
        let mut bcs_input = bcs::to_bytes(&string::utf8(b"LetsMoveCTF"));
        vector::append<u8>(&mut bcs_input, *github_id.as_bytes());
        let flag_hash = sha3_256(bcs_input);
        get_flag(flag_hash, github_id, ctx);  
    }
}
```

发布合约: 

`sui client publish`

发布成功后调用合约：
```bash
sui client call --package 0xef6b4139ec1b0fda23e06c4a30c9e91150b72c38530e4517152e591001c5c433 --module solve --function solve_get_flag
```

最终结果可以看到终端输出的Events内成功获取flag：
```bash
╭───────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Transaction Block Events                                                                              │
├───────────────────────────────────────────────────────────────────────────────────────────────────────┤
│  ┌──                                                                                                  │
│  │ EventID: EjQiJnPZRqen1TSSkNiUaRaEQYSmhshJYHctn3uUt1V5:0                                            │
│  │ PackageID: 0xef6b4139ec1b0fda23e06c4a30c9e91150b72c38530e4517152e591001c5c433                      │
│  │ Transaction Module: solve                                                                          │
│  │ Sender: 0x90abb670800b4015229d30f5d010faef0c347e1d9650c9acebe2c012be7eb724                         │
│  │ EventType: 0x335297860a807291254b20f8a0dea30d72d5e17d2e6f8058e42d5b9c72f0f0ef::check_in::FlagEvent │
│  │ ParsedJSON:                                                                                        │
│  │   ┌─────────┬────────────────────────────────────────────────────────────────────┐                 │
│  │   │ flag    │ CTF{WelcomeToMoveCTF}                                              │                 │
│  │   ├─────────┼────────────────────────────────────────────────────────────────────┤                 │
│  │   │ sender  │ 0x90abb670800b4015229d30f5d010faef0c347e1d9650c9acebe2c012be7eb724 │                 │
│  │   ├─────────┼────────────────────────────────────────────────────────────────────┤                 │
│  │   │ success │ true                                                               │                 │
│  │   └─────────┴────────────────────────────────────────────────────────────────────┘                 │
│  └──                                                                                                  │
╰───────────────────────────────────────────────────────────────────────────────────────────────────────╯
```