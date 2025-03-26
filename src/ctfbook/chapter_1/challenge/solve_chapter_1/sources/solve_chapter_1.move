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
