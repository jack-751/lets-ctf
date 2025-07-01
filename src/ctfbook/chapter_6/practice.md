# 实践：分析状态管理逻辑漏洞

```
module chapter_6::vote {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer::{public_transfer, share_object, public_freeze_object};
    use sui::vec_map::{Self, VecMap};
    use sui::object_table::{Self, ObjectTable};
    use std::string::String;
    use sui::balance::Balance;

    public struct VOTE has drop {}

    public struct Votecap has key {
        id: UID,
        cap: TreasuryCap<VOTE>,
    }

    public struct Mintlist has key {
        id: UID,
        mintlist: VecMap<address, u64>,
    }

    public struct VoteStore has key {
        id: UID,
        proposals: ObjectTable<String, Proposal>,
        voters: VecMap<address, u64>,
    }

    public struct Proposal has key, store {
        id: UID,
        owner: address,
        votes: u64,
        locked_tokens: Balance<VOTE>,
        closed: bool,
    }

    const E_INVALID_AMOUNT: u64 = 1;
    const E_INVALID_PROPOSAL: u64 = 2;
    const E_ALREADY_MINTED: u64 = 3;
    const E_UNAUTHORIZED: u64 = 4;
    const E_PROPOSAL_CLOSED: u64 = 5;

    fun init(witness: VOTE, ctx: &mut TxContext) {
        let (treasury_cap, meta) = coin::create_currency(
            witness, 6, b"VOTE", b"VOTE", b"", option::none(), ctx
        );

        let vote_cap = Votecap { id: object::new(ctx), cap: treasury_cap };
        let mintlist = Mintlist { id: object::new(ctx), mintlist: vec_map::empty() };
        let store = VoteStore {
            id: object::new(ctx),
            proposals: object_table::new(ctx),
            voters: vec_map::empty(),
        };


        public_freeze_object(meta);
        share_object(vote_cap);
        share_object(mintlist);
        share_object(store);
    }

    public entry fun mint(
        vote_cap: &mut Votecap,
        mint_list: &mut Mintlist,
        ctx: &mut TxContext
    ) {
        let addr = tx_context::sender(ctx);
        assert!(!vec_map::contains(&mint_list.mintlist, &addr), E_ALREADY_MINTED);
        let coin = coin::mint(&mut vote_cap.cap, 100, ctx);
        vec_map::insert(&mut mint_list.mintlist, addr, 100);
        public_transfer(coin, addr);
    }

    public entry fun create_proposal(
        store: &mut VoteStore,
        name: String,
        ctx: &mut TxContext
    ) {
        assert!(!object_table::contains(&store.proposals, name), E_INVALID_PROPOSAL);
        let proposal = Proposal {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            votes: 0,
            locked_tokens: zero<VOTE>(),
            closed: false,
        };
        object_table::add(&mut store.proposals, name, proposal);
    }

    public entry fun vote(
        store: &mut VoteStore,
        vote_coin: Coin<VOTE>,
        proposal_name: String,
        ctx: &mut TxContext
    ) {
        assert!(vote_coin.value() > 0, E_INVALID_AMOUNT);
        assert!(object_table::contains(&store.proposals, proposal_name), E_INVALID_PROPOSAL);
        let proposal = object_table::borrow_mut(&mut store.proposals, proposal_name);
        let sender = tx_context::sender(ctx);
        let amount = coin::into_balance(vote_coin);
        if (vec_map::contains(&store.voters, &sender)) {
            let voter_amount = vec_map::get_mut(&mut store.voters, &sender);
            *voter_amount = *voter_amount + amount.value();
        } else {
            vec_map::insert(&mut store.voters, sender, amount.value());
        };
        proposal.votes = proposal.votes + amount.value();
        proposal.locked_tokens.join(amount);
    }

    public entry fun close_proposal(
        store: &mut VoteStore,
        proposal_name: String,
        ctx: &mut TxContext
    ) {
        assert!(object_table::contains(&store.proposals, proposal_name), E_INVALID_PROPOSAL);
        let proposal = object_table::borrow_mut(&mut store.proposals, proposal_name);
        let sender = tx_context::sender(ctx);
        assert!(sender == proposal.owner, E_UNAUTHORIZED);
        assert!(!proposal.closed, E_PROPOSAL_CLOSED);
        proposal.closed = true;
        let coin = coin::from_balance(proposal.locked_tokens.withdraw_all(), ctx);
        public_transfer(coin, sender);
    }
}
```