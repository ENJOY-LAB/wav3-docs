module wav3::NFT {

    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::option;
    use std::vector;

    use aptos_framework::block;
    use aptos_framework::account;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_std::table::{Self, Table};
    use aptos_token::token::{Self, TokenDataId};

    const ECOLLECTION_ALREADY_EXISTS: u64 = 1;
    const EIMAGE_URI_TOO_LONG: u64 = 2;
    const EANIMATION_URI_TOO_LONG: u64 = 3;
    const EWEBSITE_URI_TOO_LONG: u64 = 4;
    const ETOKEN_DATA_ALREADY_EXISTS: u64 = 5;
    const ECOLLECTION_NOT_PUBLISHED: u64 = 6;
    const ENOT_A_MULTI_EDITION: u64 = 7;
    const ESOCIAL_MEDIA_ALREADY_REGISTER: u64 = 8;
    const ESOCIAL_MEDIA_NOT_REGISTER: u64 = 9;
    const ECOLLECTIONS_NOT_PUBLISHED: u64 = 10;
    const EUTF_CONVERT_ERROR: u64 = 11;

    const MAX_URI_LENGTH: u64 = 512;

    struct CollectionExtend has store {
        social_media: SimpleMap<String, String>,
        symbol: String,
        image_uri: String,
        animation_uri: String,
        website: String,
        standard_version: u64,
        commercial_standard: String,
        update_block_height: u64,
        royalty_policy: String,
        multi_edtion: bool
    }

    struct TokenDataExtend has store {
        image_uri: String,
        animation_uri: String,
        image_checksum: u64,
        mutability_config: MutabilityConfig,
        update_block_height: u64
    }

    struct MutabilityConfig has copy, drop, store {
        image_uri: bool
    }

    /// Represent collection and token metadata for a creator
    struct Collections has key {
        collection_extend_data: Table<String, CollectionExtend>,
        token_extend_data: Table<TokenDataId, TokenDataExtend>
    }

    public entry fun create_collection(
        creator: &signer,
        name: String,
        description: String,
        maximum: u64,
        mutate_setting: vector<bool>,
        symbol: String,
        image_uri: String,
        animation_uri: String,
        website: String,
        standard_version: u64,
        commercial_standard: String,
        royalty_policy: String,
        multi_edtion: bool
    ) acquires Collections {
        let account_addr = signer::address_of(creator);
        if (!exists<Collections>(account_addr)) {
            move_to(
                creator,
                Collections{
                    collection_extend_data: table::new(),
                    token_extend_data: table::new(),
                },
            )
        };
        let collection_extend_data = &mut borrow_global_mut<Collections>(account_addr).collection_extend_data;
        assert!(
            !table::contains(collection_extend_data, name),
            error::already_exists(ECOLLECTION_ALREADY_EXISTS),
        );

        let uri = get_collection_uri(account_addr, name);
        token::create_collection(creator, name, description, uri, maximum, mutate_setting);

        assert!(string::length(&image_uri) <= MAX_URI_LENGTH, error::invalid_argument(EIMAGE_URI_TOO_LONG));
        assert!(string::length(&animation_uri) <= MAX_URI_LENGTH, error::invalid_argument(EANIMATION_URI_TOO_LONG));
        assert!(string::length(&website) <= MAX_URI_LENGTH, error::invalid_argument(EWEBSITE_URI_TOO_LONG));

        table::add(collection_extend_data, name, CollectionExtend {
            social_media: simple_map::create<String, String>(),
            symbol,
            image_uri,
            animation_uri,
            website,
            standard_version,
            commercial_standard,
            update_block_height: block::get_current_block_height(),
            royalty_policy,
            multi_edtion
        });
    }

    public entry fun create_tokendata(
        account: &signer,
        collection: String,
        name: String,
        description: String,
        maximum: u64,
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        token_mutate_config_vec: vector<bool>,
        property_keys: vector<String>,
        property_values: vector<vector<u8>>,
        property_types: vector<String>,
        image_uri: String,
        animation_uri: String,
        image_checksum: u64,
        mutability_config_vec: vector<bool>,
    ) acquires Collections {
        let account_addr = signer::address_of(account);
        assert!(
            exists<Collections>(account_addr),
            error::not_found(ECOLLECTIONS_NOT_PUBLISHED),
        );
        let uri = get_token_uri(account_addr, collection, name);
        let token_mutate_config = token::create_token_mutability_config(&token_mutate_config_vec);
        let token_data_id = token::create_tokendata(
            account,
            collection,
            name,
            description,
            maximum,
            uri,
            royalty_payee_address,
            royalty_points_denominator,
            royalty_points_numerator,
            token_mutate_config,
            property_keys,
            property_values,
            property_types,
        );
        let collections = borrow_global_mut<Collections>(account_addr);
        assert!(string::length(&image_uri) <= MAX_URI_LENGTH, error::invalid_argument(EIMAGE_URI_TOO_LONG));
        assert!(string::length(&animation_uri) <= MAX_URI_LENGTH, error::invalid_argument(EANIMATION_URI_TOO_LONG));
        assert!(
            table::contains(&collections.collection_extend_data, collection),
            error::already_exists(ECOLLECTION_NOT_PUBLISHED),
        );
        assert!(
            !table::contains(&collections.token_extend_data, token_data_id),
            error::already_exists(ETOKEN_DATA_ALREADY_EXISTS),
        );
        let mutability_config = create_token_mutability_config(mutability_config_vec);

        table::add(&mut collections.token_extend_data, token_data_id, TokenDataExtend {
            image_uri,
            animation_uri,
            image_checksum,
            mutability_config,
            update_block_height: block::get_current_block_height() 
        });
    }

    public entry fun mint_nft(
        account: &signer,
        collection_name: String,
        token_name: String,
        properties: String
    ) acquires Collections {
        let addr = signer::address_of(account);
        let token_data_id = token::create_token_data_id(addr, collection_name, token_name);
        let collections = borrow_global<Collections>(addr);
        let collection_extend_data = table::borrow(& collections.collection_extend_data, collection_name);
        if (!collection_extend_data.multi_edtion) {
            let res_opt =token::get_token_supply(addr, token_data_id);
            let cur_supply = option::extract(&mut res_opt);
            assert!(cur_supply < 2, ENOT_A_MULTI_EDITION);
        };
        let token_id = token::mint_token(account, token_data_id, 1);
        let keys = vector<String>[string::utf8(b"properties")];
        let values = vector[*string::bytes(&properties)];
        let types = vector<String>[string::utf8(b"string")];
        let _token_id = token::mutate_one_token(
            account,
            addr,
            token_id,
            keys,
            values,
            types
        );
    }

    public entry fun add_social_media(
        account: &signer,
        collection: String,
        social_media_type: String,
        social_media: String
    ) acquires Collections {
        let addr = signer::address_of(account);
        let collections = borrow_global_mut<Collections>(addr);
        let collection_extend_data = table::borrow_mut(
            &mut  collections.collection_extend_data, collection
        );
        assert!(
            !simple_map::contains_key(&collection_extend_data.social_media, &social_media_type),
            ESOCIAL_MEDIA_ALREADY_REGISTER
        );
        simple_map::add(&mut collection_extend_data.social_media, social_media_type, social_media);
    }

    public fun create_token_mutability_config(mutability_vec: vector<bool>): MutabilityConfig {
        let image_uri_update = vector::pop_back(&mut mutability_vec);
        MutabilityConfig {
            image_uri: image_uri_update
        }
    }

    public entry fun update_social_media(
        account: &signer,
        collection: String,
        social_media_type: String,
        social_media: String
    ) acquires Collections {
        let addr = signer::address_of(account);
        let collections = borrow_global_mut<Collections>(addr);
        let collection_extend_data = table::borrow_mut(
            &mut collections.collection_extend_data, collection
        );
        assert!(
            simple_map::contains_key(&collection_extend_data.social_media, &social_media_type),
            ESOCIAL_MEDIA_NOT_REGISTER
        );
        let social_meida_ref = simple_map::borrow_mut(
            &mut collection_extend_data.social_media,
            &social_media_type
        );
        *social_meida_ref = social_media;
    }

    fun get_collection_uri(creator: address, collection: String): String {
        let addr_string = address_to_string(creator);
        let uri = string::utf8(b"nft://");
        string::append(&mut uri, addr_string);
        string::append(&mut uri, string::utf8(b"/"));
        string::append(&mut uri, collection);
        uri
    }

    fun get_token_uri(creator: address, collection: String, token_name: String): String {
        let addr_string = address_to_string(creator);
        let uri = string::utf8(b"nft://");
        string::append(&mut uri, addr_string);
        string::append(&mut uri, string::utf8(b"/"));
        string::append(&mut uri, collection);
        string::append(&mut uri, string::utf8(b"/"));
        string::append(&mut uri, token_name);
        uri
    }

    fun address_to_string(addr: address): String {
        let authentication_vec = account::get_authentication_key(addr);
        let address_utf8_vec = vector::empty<u8>();
        let i = 0;
        while(i < 32) {
            let val = *vector::borrow(&authentication_vec, i);
            let high_4 = val >> 4;
            let low_4 = val << 4 >> 4;
            vector::push_back(&mut address_utf8_vec, hex_to_utf8(high_4));
            vector::push_back(&mut address_utf8_vec, hex_to_utf8(low_4));
            i = i + 1;
        };
        string::utf8(address_utf8_vec)
    }

    fun hex_to_utf8(num: u8): u8 {
        assert!(num < 16, error::invalid_argument(EUTF_CONVERT_ERROR));
        if (num == 0) {
            48
        } else if (num == 1) {
            49
        } else if (num == 2) {
            50
        } else if (num == 3) {
            51
        } else if (num == 4) {
            52
        } else if (num == 5) {
            53
        } else if (num == 6) {
            54
        } else if (num == 7) {
            55
        } else if (num == 8) {
            56
        } else if (num == 9) {
            57
        } else if (num == 10) {
            97
        } else if (num == 11) {
            98
        } else if (num == 12) {
            99
        } else if (num == 13) {
            100
        } else if (num == 14) {
            101
        } else {
            102
        }
    }
}