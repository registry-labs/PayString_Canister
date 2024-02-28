dfx deploy ic_siwe_provider --argument $'(
    record {
        domain = "127.0.0.1";
        uri = "http://127.0.0.1:5173";
        salt = "qbu4y-iaaaa-aaaan-qdvda-cai";
        chain_id = opt 1;
        scheme = opt "http";
        statement = opt "Login to the app";
        sign_in_expires_in = opt 300000000000;       # 5 minutes
        session_expires_in = opt 604800000000000;    # 1 week
        targets = opt vec {
            "'$(dfx canister id ic_siwe_provider)'"; # Must be included
            "'$(dfx canister id qbu4y-iaaaa-aaaan-qdvda-cai)'";  # Allow identity to be used with this canister
        };
    }
)'