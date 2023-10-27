import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";
import Time "mo:base/Time";
import Constants "../Constants";
module {

    public type Metadata = {
        mintId : Nat32;
        data : Blob;
    };

    public type AuctionRequest = {
        duration : Nat;
        mintId : Nat32;
        amount : Nat;
        token : Token;
    };

    public type Token = {
        #Dip20_EXT : Text;
        #Dip20 : Text;
        #ICRC2 : Text;
    };

    public type Offer = {
        icp : Nat;
        token : ?Token;
        createdAt : Time.Time;
        mintId : Nat32;
        recipient : Principal;
        seller : Principal;
        expiration : ?Time.Time;
        buyer : Principal;
        offerId : Nat32;
        amount : Nat;
    };

    public type Auction = {
        end : Time.Time;
        token : Token;
        createdAt : Time.Time;
        mintId : Nat32;
        amount : Nat;
    };

    public type Bid = { offer : Offer; owner : Principal };

    public func service() : actor {
        balance : shared query Principal -> async [Metadata];
        mint : shared (Blob, Principal) -> async Nat32;
        auction : shared AuctionRequest -> async ();
        auctionAndBid : shared (AuctionRequest, Principal) -> async ();
        symbolExist : shared query Blob -> async Bool;
        fetchBids : shared query Blob -> async [Bid];
        getOwner : shared query Nat32 -> async Principal;
        getWinningBid : shared query Nat32 -> async ?Offer;
        fetchAuctions : shared query () -> async [Auction];
        transfer : shared (Principal, Nat32) -> async ();
    } {
        return actor (Constants.NFT_Canister) : actor {
            balance : shared query Principal -> async [Metadata];
            mint : shared (Blob, Principal) -> async Nat32;
            auction : shared AuctionRequest -> async ();
            auctionAndBid : shared (AuctionRequest, Principal) -> async ();
            symbolExist : shared query Blob -> async Bool;
            fetchBids : shared query Blob -> async [Bid];
            getOwner : shared query Nat32 -> async Principal;
            getWinningBid : shared query Nat32 -> async ?Offer;
            fetchAuctions : shared query () -> async [Auction];
            transfer : shared (Principal, Nat32) -> async ();
        };
    };
};
