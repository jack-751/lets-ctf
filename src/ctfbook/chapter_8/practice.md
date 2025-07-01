# 实践：多步骤综合挑战

## 示例合约

`chapter_8::auth` 代码
```
module chapter_8::auth {
    use sui::transfer::{share_object};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use chapter_8::vote::{VOTE, VotingSystem, is_authorized as vote_authorized};
    use std::type_name::{Self, TypeName};
    use sui::transfer::public_transfer;

    public struct Credential<phantom T> has key, store {
        id: UID,
        verified: bool,
        fee_paid: Balance<T>,
        coin_type: TypeName,
    }

    public struct Auth has key {
        id: UID,
        authorized: bool,
        admin: address,
        min_fee: u64,
        vote_dependency: Option<address>,
        valid_coin_type: TypeName,
    }

    fun init(ctx: &mut TxContext) {
        let auth = Auth {
            id: object::new(ctx),
            admin: ctx.sender(),
            authorized: false,
            min_fee: 50,
            vote_dependency: option::none(),
            valid_coin_type: type_name::get<Coin<VOTE>>(),
        };
        share_object(auth);
    }

    public fun register<T>(
        auth: &mut Auth,
        payment: Coin<T>,
        vote_system: &mut VotingSystem,
        ctx: &mut TxContext
    ): Credential<T> {
        let amount = coin::value(&payment);

        assert!(amount >= auth.min_fee, 1);

        if (option::is_some(&auth.vote_dependency)) {
            let dep_addr = option::borrow(&auth.vote_dependency);
            assert!(vote_authorized(vote_system) && tx_context::sender(ctx) == *dep_addr, 2);
        };

        let coin_type = type_name::get<Coin<T>>();
        let fee_balance = coin::into_balance<T>(payment);
        let credential = Credential {
            id: object::new(ctx),
            verified: false,
            fee_paid: fee_balance,
            coin_type,
        };

        credential
    }

    #[allow(lint(self_transfer))]
    public fun verify<T>(
        auth: &mut Auth,
        credential: &mut Credential<T>,
        vote_system: &mut VotingSystem,
        payment: Coin<T>,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&credential.fee_paid) > auth.min_fee, 3);
        assert!(coin::value(&payment) >= auth.min_fee, 4);

        if (vote_authorized(vote_system) && type_name::get<Coin<T>>() == credential.coin_type) {
            credential.verified = true;
            auth.authorized = true;
            balance::join(&mut credential.fee_paid, coin::into_balance(payment));
        }else{
            public_transfer(payment, ctx.sender());
        }
    }

    public fun add_self_to_dependency(auth: &mut Auth, ctx: &mut TxContext) {
        if (option::is_none(&auth.vote_dependency)) {
            auth.vote_dependency = option::some(tx_context::sender(ctx));
        }
    }

    public fun is_authorized(auth: &Auth): bool {
        auth.authorized
    }

    public fun is_verified<T>(credential: &Credential<T>): bool {
        credential.verified
    }
}
```

`chapter_8::flag_vault` 代码`
```
module chapter_8::flag_vault {
    use sui::event::emit;
    use chapter_8::vote::VotingSystem;
    use chapter_8::auth::Auth;
    use std::string::{Self, String};

    public struct FlagEvent has copy, drop {
        flag: String,
        sender: address,
    }

    public entry fun get_flag(system: &VotingSystem, auth: &Auth, ctx: &mut TxContext) {
        assert!(chapter_8::vote::is_authorized(system) && chapter_8::auth::is_authorized(auth), 1);
        let sender = tx_context::sender(ctx);
        emit(FlagEvent { flag: string::utf8(b"CTF{All_Chapters_Combined}"), sender });
    }
}
```

`chapter_8::math_utils` 代码
```
module chapter_8::math_utils {
    public fun calculate_weight(amount: u256): u256 {
        let (weight, overflow) = check(amount);
        if (overflow) {
            999999999
        } else {
            weight
        }
    }

    fun check(n: u256): (u256, bool) {
        let mask = 0xff - 1;
        if (n > mask) {
            (0, true)
        } else {
            (n, false)
        }
    }
}
```

`chapter_8::vote` 代码
```
module chapter_8::vote {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer::{share_object, public_freeze_object};
    use sui::balance::Balance;
    use sui::vec_map::{Self, VecMap};
    use sui::table::{Self, Table};
    use chapter_8::math_utils;

    public struct VOTE has drop {}

    public struct Votecap has key {
        id: UID,
        cap: TreasuryCap<VOTE>,
    }

    public struct Mintlist has key {
        id: UID,
        mintlist: VecMap<address, u64>,
        reset_count: u64,
        max_resets: u64,
    }

    public struct VotingSystem has key {
        id: UID,
        balance: Balance<VOTE>,
        vote_list: Table<address, u64>,
        is_authorized: bool,
    }

    fun init(witness: VOTE, ctx: &mut TxContext) {
        let (treasury_cap, meta) = coin::create_currency(witness, 6, b"VOTE", b"VOTE", b"", option::none(), ctx);
        let mut vote_cap = Votecap { id: object::new(ctx), cap: treasury_cap };
        let mintlist = Mintlist { id: object::new(ctx), mintlist: vec_map::empty(), reset_count: 0, max_resets: 3 };
        let coin = coin::mint(&mut vote_cap.cap, 10000, ctx);
        let balance = coin::into_balance(coin);
        let system = VotingSystem { id: object::new(ctx), balance, vote_list: table::new(ctx), is_authorized: false };
        public_freeze_object(meta);
        share_object(vote_cap);
        share_object(mintlist);
        share_object(system);
    }

    public fun mint(vote_cap: &mut Votecap, mint_list: &mut Mintlist, ctx: &mut TxContext): Coin<VOTE> {
        let addr = tx_context::sender(ctx);
        assert!(!vec_map::contains(&mint_list.mintlist, &addr) || mint_list.reset_count < mint_list.max_resets, 1);
        if (vec_map::contains(&mint_list.mintlist, &addr)) {
            vec_map::remove(&mut mint_list.mintlist, &addr);
            mint_list.reset_count = mint_list.reset_count + 1;
        };
        let coin = coin::mint(&mut vote_cap.cap, 100, ctx);
        vec_map::insert(&mut mint_list.mintlist, addr, 100);
        coin
    }

    public entry fun vote(system: &mut VotingSystem, vote_coin: Coin<VOTE>, ctx: &mut TxContext) {
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

    public fun withdraw(system: &mut VotingSystem, ctx: &mut TxContext): Coin<VOTE> {
        let amount = *table::borrow(&system.vote_list, ctx.sender());
        let coin = coin::from_balance(system.balance.split(amount), ctx);
        coin
    }

    public fun is_authorized(system: &VotingSystem): bool {
        system.is_authorized
    }
}
```


## 解题合约

`solve_chapter_8::solve` 代码
```
module solve_chapter_8::solve{

    use chapter_8::vote::{mint, vote, withdraw, Votecap, Mintlist, VotingSystem, VOTE};
    use chapter_8::flag_vault::get_flag;
    use chapter_8::auth::{register, add_self_to_dependency , verify};
    use chapter_8::auth::Auth;
    use sui::transfer::public_transfer;

    #[allow(lint(self_transfer))]
    public fun solve(
        vote_cap: &mut Votecap,
        mint_list: &mut Mintlist,
        system: &mut VotingSystem,
        auth: &mut Auth,
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
        add_self_to_dependency(auth,ctx);

        let mut cet = register<VOTE>(auth,coin3, system,ctx);
        let coin4 = withdraw(system, ctx);
        verify<VOTE>(auth,&mut cet,system,coin4,ctx);

        get_flag(system, auth, ctx);

        public_transfer(cet, ctx.sender());
    }
}
```