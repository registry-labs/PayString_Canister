import Principal "mo:base/Principal";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";

module {

    public func service(canister : Text) : actor {
        test : query () -> async [Nat8];
    } {
        return actor (canister) : actor {
            test : query () -> async [Nat8];
        };
    };
};
