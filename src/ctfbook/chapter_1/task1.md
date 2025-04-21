# Task1

## 任务代码
以下是待分析的 Move 合约，完整代码请查看 [挑战合约](https://github.com/hoh-zone/lets-ctf/tree/main/src/ctfbook/chapter_1/task1)：
```
PackageID: 0xcd6050b4e93c5bdc7149f2bf0b69202ec297bf1532d500e896dbefcd15d811f4 
Challenge ObjectID: 0xf5dc0a1701384ff0ff6697ae9de37ee0cc832ff1fd511232aca7d0fff282d026
```

```move
module task1::task1 {
    use std::bcs;
    use std::hash::sha3_256;
    use std::string::{Self, String};
    use sui::event;
    use sui::random::{Self, Random};
    use sui::transfer::share_object;

    const EINVALID_HASH: u64 = 0;
    const EINVALID_MAGIC: u64 = 1;
    const EINVALID_SEED: u64 = 2;

    public struct FlagEvent has copy, drop {
        sender: address,
        flag: String,
        attempt_count: u64,
        github_id: String,
        success: bool
    }

    public struct Challenge has key {
        id: UID,
        secret: String,
        attempt_count: u64,
        last_seed: u64
    }

    fun init(ctx: &mut TxContext) {
        let challenge = Challenge {
            id: object::new(ctx),
            secret: string::utf8(b"MoveCTF_task1"),
            attempt_count: 0,
            last_seed: 0
        };
        share_object(challenge);
    }

    public entry fun get_flag(
        hash_input: vector<u8>,
        github_id: String,
        magic_number: u64,
        seed: u64,
        challenge: &mut Challenge,
        rand: &Random,
        ctx: &mut TxContext
    ) {
        let mut bcs_input = bcs::to_bytes(&challenge.secret);
        vector::append(&mut bcs_input, *github_id.as_bytes());
        let expected_hash = sha3_256(bcs_input);
        assert!(hash_input == expected_hash, EINVALID_HASH);

        challenge.attempt_count = challenge.attempt_count + 1;

        let expected_magic = (challenge.attempt_count * challenge.attempt_count + challenge.last_seed) % 1000 + seed;
        assert!(magic_number == expected_magic, EINVALID_MAGIC);

        let secret_bytes = *string::as_bytes(&challenge.secret);
        let secret_len = vector::length(&secret_bytes);
        assert!(seed == secret_len * 2, EINVALID_SEED);

        challenge.secret = getRandomString(rand, ctx);
        challenge.last_seed = seed;

        event::emit(FlagEvent {
            sender: tx_context::sender(ctx),
            flag: string::utf8(b"CTF{MoveCTF-Task1}"),
            github_id,
            attempt_count: challenge.attempt_count,
            success: true
        });
    }

    fun getRandomString(rand: &Random, ctx: &mut TxContext): String {
        let mut gen = random::new_generator(rand, ctx);
        let mut str_len = random::generate_u8_in_range(&mut gen, 4, 32);
        let mut rand_vec: vector<u8> = b"";
        while (str_len != 0) {
            let rand_num = random::generate_u8_in_range(&mut gen, 34, 126);
            vector::push_back(&mut rand_vec, rand_num);
            str_len = str_len - 1;
        };
        string::utf8(rand_vec)
    }
}
```