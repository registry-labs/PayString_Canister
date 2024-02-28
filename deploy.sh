dfx deploy --network ic ic_siwe_provider --argument $'(
    record {
        domain = "theregistry.app";
        uri = "https://theregistry.app";
        salt = "hZBYmrI((epoT9xaCj7mex9VUA8uCmEI";
        chain_id = opt 1;
        scheme = opt "http";
        statement = opt "Connect your wallet to the registry";
        sign_in_expires_in = opt 300000000000;
        session_expires_in = opt 604800000000000;
        targets = opt vec {
            "vrnop-riaaa-aaaan-qdzrq-cai";
            "qbu4y-iaaaa-aaaan-qdvda-cai";
            "utozz-siaaa-aaaam-qaaxq-cai";
            "chr3s-fyaaa-aaaan-qlvea-cai";
            "ryjl3-tyaaa-aaaaa-aaaba-cai";
            "bjgo7-hiaaa-aaaan-qlzca-cai";
        };
    }
)'


dfx deploy ic_siwe_provider --network ic --mode reinstall --argument $'(
    record {
        domain = "theregistry.app";
        uri = "https://theregistry.app";
        salt = "hZBYmrI((epoT9xaCj7mex9VUA8uCmEI";
        chain_id = opt 1;
        scheme = opt "http";
        statement = opt "Connect your wallet to the registry";
        sign_in_expires_in = opt 300000000000;
        session_expires_in = opt 604800000000000;
        targets = opt vec {
            "vrnop-riaaa-aaaan-qdzrq-cai";
            "qbu4y-iaaaa-aaaan-qdvda-cai";
            "utozz-siaaa-aaaam-qaaxq-cai";
            "chr3s-fyaaa-aaaan-qlvea-cai";
            "ryjl3-tyaaa-aaaaa-aaaba-cai";
            "bjgo7-hiaaa-aaaan-qlzca-cai";
        };
    }
)'