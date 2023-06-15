import Principal "mo:base/Principal";
import Constants "../Constants";
module {
    
    public type Metadata = {
        mintId:Nat32;
        data:Blob;
    };

    public type AuctionRequest = {
        duration : Nat;
        mintId : Nat32;
        amount : Nat;
        token : Token;
    };

    public type Token = {
        #Dip20_EXT:Text;
        #Dip20:Text;
        #ICRC2:Text;
    };

    public func service() : actor {
        balance : shared query Principal -> async [Metadata];
        mint : shared (Blob, Principal) -> async Nat32;
        auction : shared AuctionRequest -> async ();
        auctionAndBid : shared (AuctionRequest, Principal) -> async ();
        symbolExist : shared query Blob -> async Bool;
    } {
        return actor (Constants.NFT_Canister) : actor {
            balance : shared query Principal -> async [Metadata];
            mint : shared (Blob, Principal) -> async Nat32;
            auction : shared AuctionRequest -> async ();
            auctionAndBid : shared (AuctionRequest, Principal) -> async ();
            symbolExist : shared query Blob -> async Bool;
        };
    };
}