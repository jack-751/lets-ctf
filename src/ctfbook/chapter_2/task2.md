# Task2

## 任务代码
以下是待分析的 Move 合约，完整代码请查看 [挑战合约](https://github.com/hoh-zone/lets-ctf/tree/main/src/ctfbook/chapter_2/task2)：
```
PackageID: 0xd26a14084af49f68d4612ef0815518c251f7a0459eaf2cbcb2757efafad442c5 
Challenge ObjectID: 0x22c1330b43313cee7f0ca0ce36965343c1ae40577d80a4ffa8ab12986f50dea1
```

```move
module task2::task2 {
    use sui::event;
    use sui::random::{Random, generate_u64, new_generator};
    use sui::clock::{Self, Clock};
    use std::hash;
    use std::string::String;

    const E_WRONG_STAGE: u64 = 1;
    const E_COOLDOWN: u64 = 2;
    const E_MAX_ATTEMPTS_EXCEEDED: u64 = 3;

    public struct Challenge has key {
        id: UID,
        owner: address,
        secret_hash: vector<u8>,
        attempts: u64,
        max_attempts: u64,
        last_attempt_time: u64,
        is_solved: bool,
        stage: u64,
        target_score: u64,
        current_score: u64,
        bonus_multiplier: u64,
        guess_round: u64,
        round_hash: vector<u8>,
        seed: u64,
    }

    public struct FlagEvent has copy, drop {
        flag: vector<u8>,
        github_id: String
    }

    public struct ScoreEvent has copy, drop {
        score: u64,
    }

    fun init(ctx: &mut TxContext) {
        let secret = b"LetsMoveCTF";
        let secret_hash = hash::sha3_256(secret);
        let challenge = Challenge {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            secret_hash: secret_hash,
            attempts: 0,
            max_attempts: 50,
            last_attempt_time: 0,
            is_solved: false,
            stage: 1,
            target_score: 100,
            current_score: 0,
            bonus_multiplier: 0,
            guess_round: 1,
            round_hash: secret_hash,
            seed: 0,
        };
        transfer::share_object(challenge);
    }

    public entry fun submit_score(challenge: &mut Challenge, score: u64, clock: &Clock) {
        assert!(challenge.stage == 1, E_WRONG_STAGE);
        let current_time = clock::timestamp_ms(clock);
        assert!(current_time >= challenge.last_attempt_time + 5000, E_COOLDOWN);
        challenge.attempts = challenge.attempts + 1;
        assert!(challenge.attempts < challenge.max_attempts, E_MAX_ATTEMPTS_EXCEEDED);
        let time_factor = (current_time - challenge.last_attempt_time) / 1000;
        let attempt_penalty = challenge.attempts * 2;
        let adjusted_score = if (score > attempt_penalty) {
            score - attempt_penalty
        } else {
            0
        };
        let final_score = adjusted_score * challenge.bonus_multiplier + time_factor;
        challenge.current_score = challenge.current_score + final_score;
        challenge.last_attempt_time = current_time;
        event::emit(ScoreEvent { score: challenge.current_score });
        if (challenge.current_score >= challenge.target_score) {
            challenge.stage = 2;
            challenge.attempts = 0;
        };
    }

    #[allow(lint(public_random))]
    public entry fun submit_guess(challenge: &mut Challenge, randomseed: &Random, guess: vector<u8>, clock: &Clock, ctx: &mut TxContext) {
        assert!(challenge.stage == 2, E_WRONG_STAGE);
        let mut random_gen = new_generator(randomseed, ctx);
        let seed = generate_u64(&mut random_gen);
        let current_time = clock::timestamp_ms(clock);
        assert!(current_time >= challenge.last_attempt_time + 5000, E_COOLDOWN);
        assert!(challenge.attempts < challenge.max_attempts, E_MAX_ATTEMPTS_EXCEEDED);
        challenge.attempts = challenge.attempts + 1;
        let mut guess_data = guess;
        vector::append(&mut guess_data, to_bytes(current_time));
        vector::append(&mut guess_data, to_bytes(challenge.attempts));
        let random = hash::sha3_256(guess_data);
        let prefix_length = challenge.guess_round * 2;
        if (compare_hash_prefix(&random, &challenge.round_hash, prefix_length)) {
            challenge.guess_round = challenge.guess_round + 1;
            let mut new_hash_data = random;
            vector::append(&mut new_hash_data, to_bytes(challenge.seed + challenge.guess_round));
            challenge.round_hash = hash::sha3_256(new_hash_data);
            challenge.seed = seed;
            if (challenge.guess_round > 3) {
                challenge.is_solved = true;
                challenge.stage = 3;
                challenge.guess_round = 1;
                challenge.attempts = 0;
            };
        };
        challenge.last_attempt_time = current_time;
    }

    public entry fun get_flag(challenge: &mut Challenge,github_id: String, _: &mut TxContext) {
        assert!(challenge.stage == 3 && challenge.is_solved, E_WRONG_STAGE);
        reset_challenge(challenge);
        event::emit(FlagEvent { flag: b"flag{LetsMoveCTF_chapter_2}" ,github_id});
    }

    public fun reset_challenge(challenge: &mut Challenge) {
        challenge.attempts = 0;
        challenge.last_attempt_time = 0;
        challenge.is_solved = false;
        challenge.stage = 1;
        challenge.current_score = 0;
        challenge.bonus_multiplier = 1;
        challenge.guess_round = 1;
        challenge.round_hash = challenge.secret_hash;
    }

    fun to_bytes(value: u64): vector<u8> {
        let mut bytes = vector::empty<u8>();
        let mut i = 0;
        while (i < 8) {
            vector::push_back(&mut bytes, ((value >> (i * 8)) & 0xFF as u8));
            i = i + 1;
        };
        bytes
    }

    fun compare_hash_prefix(hash1: &vector<u8>, hash2: &vector<u8>, n: u64): bool {
        if (vector::length(hash1) < n || vector::length(hash2) < n) {
            return false
        };
        let mut i = 0;
        while (i < n) {
            if (*vector::borrow(hash1, i) != *vector::borrow(hash2, i)) {
                return false
            };
            i = i + 1;
        };
        true
    }
}
```