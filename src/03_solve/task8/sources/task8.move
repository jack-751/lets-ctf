/*
/// Module: task8
module task8::task8;
*/

// For Move coding conventions, see
// https://docs.sui.io/concepts/sui-move-concepts/conventions

module task8::task8;

use lets_move::lets_move::{Challenge, Flag, getRandomString};
use std::ascii::{String, string};
use std::hash;
use sui::bcs;
use sui::event;
use sui::random::{Self, Random};
use sui::transfer::share_object;

public struct FlagInfoEvent has copy, drop {
    step: u8,
    full_proof: vector<u8>,
    proof: vector<u8>,
    sender: vector<u8>,
    challenge: vector<u8>,
    hash: vector<u8>,
    prefix_sum: u32,
    i: u64,
}

public entry fun get_flag_info(
    proof: vector<u8>,
    github_id: String,
    challenge: &mut Challenge,
    rand: &Random,
    ctx: &mut TxContext,
) {
    let mut full_proof: vector<u8> = vector::empty<u8>();
    vector::append<u8>(&mut full_proof, proof);
    let sender_bytes = tx_context::sender(ctx).to_bytes();
    vector::append<u8>(&mut full_proof, sender_bytes);
    let challenge_bytes = bcs::to_bytes(challenge);
    vector::append<u8>(&mut full_proof, challenge_bytes);

    event::emit(FlagInfoEvent {
        step: 1,
        full_proof,
        proof,
        sender: sender_bytes,
        challenge: challenge_bytes,
        hash: vector::empty<u8>(),
        prefix_sum: 0,
        i: 0,
    });

    let hash: vector<u8> = hash::sha3_256(full_proof);

    event::emit(FlagInfoEvent {
        step: 2,
        full_proof,
        proof,
        sender: sender_bytes,
        challenge: challenge_bytes,
        hash,
        prefix_sum: 0,
        i: 0,
    });

    let mut prefix_sum: u32 = 0;
    let mut i: u64 = 0;

    while (i < 3) {
        prefix_sum = prefix_sum + (*vector::borrow(&hash, i) as u32);
        event::emit(FlagInfoEvent {
            step: 3,
            full_proof,
            proof,
            sender: sender_bytes,
            challenge: challenge_bytes,
            hash,
            prefix_sum,
            i,
        });
        i = i + 1;
    };
}
