import Principal "mo:base/Principal";
import HashMap "mo:stable/HashMap";
import HashMapPrim "mo:base/HashMap";
import StableBuffer "mo:stable-buffer/StableBuffer";
import JSON "mo:json/JSON";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Nat32 "mo:base/Nat32";
import List "mo:base/List";
import HttpParser "mo:http-parser";
import Option "mo:base/Option";
import Utils "./common/Utils";
import Http "./common/http";
import Error "mo:base/Error";
import AddressRequest "models/AddressRequest";
import Address "models/Address";
import Constants "Constants";
import FemaleNames "common/FemaleNames";
import FemaleNames2 "common/FemaleNames2";
import MaleNames "common/MaleNames";
import NFT "./services/NFT";
import DIP20 "./services/Dip20";
import Prim "mo:⛔";
import Prelude "mo:base/Prelude";
import Nat "mo:base/Nat";
import Blob "mo:base/Blob";

actor class PayString() = this {

  let pHash = Principal.hash;
  let pEqual = Principal.equal;

  let tHash = Text.hash;
  let tEqual = Text.equal;

  let n32Hash = func(a : Nat32) : Nat32 { a };
  let n32Equal = Nat32.equal;

  private type JSON = JSON.JSON;
  private type AddressRequest = AddressRequest.AddressRequest;
  private type Address = Address.Address;

  private stable var payIdCount : Nat32 = 1;
  //private stable var manifest = HashMap.empty<Principal, [Text]>();
  private stable var payIds = HashMap.empty<Text, [Address]>();
  private stable var earlyAccess = StableBuffer.init<(Principal)>();
  private stable var prices = HashMap.empty<Nat32, Nat>();

  //private let day = 86400;
  private var auctionTime = 60 * 2;

  

  public query func getAuctionTime() : async Nat {
    auctionTime
  };

  public shared ({caller}) func setAuctionTime(value:Nat) : async () {
    await* _isEarlyAccess(caller);
    auctionTime := value
  };
  
  public shared ({ caller }) func addEarlyAccess(principal:Principal) : async () {
    await* _isEarlyAccess(caller);
    StableBuffer.add(earlyAccess, principal);
  };

  public shared ({ caller }) func setPrice(symbolSize : Nat32, price : Nat) : async () {
    await* _isEarlyAccess(caller);
    prices := HashMap.insert(prices, symbolSize, n32Hash, n32Equal, price).0;
  };

  public shared ({ caller }) func auction(payId : Text) : async Nat32 {
    await* _isEarlyAccess(caller);
    assert (caller != Principal.fromText("2vxsx-fae"));
    let nftCanister = Principal.fromText(Constants.NFT_Canister);
    let allowance = await DIP20.service(Constants.WICP_Canister).allowance(caller, nftCanister);
    let price = _getPrice(payId);
    if (allowance < price) throw (Error.reject("Insufficient Allowance"));
    let blob = Text.encodeUtf8(Utils.toLowerCase(payId));
    let mintId = await NFT.service().mint(blob, Principal.fromActor(this));
    let auctionRequest = {
      duration = auctionTime;
      mintId = mintId;
      amount = price;
      token = #Dip20(Constants.WICP_Canister);
    };
    await NFT.service().auctionAndBid(auctionRequest, caller);
    mintId;
  };

  public shared ({ caller }) func delete(payId : Text, address : Address) : async () {
    assert (caller != Principal.fromText("2vxsx-fae"));
    let _payId = Utils.toLowerCase(payId);
    await _isOwner(caller, _payId);
    var _addresses = _getPayId(_payId, "payid", null);
    _addresses := Array.filter(
      _addresses,
      func(e : Address) : Bool {
        let value1 = Text.concat(e.paymentNetwork, Utils.unwrap(e.environment));
        let value2 = Text.concat(address.paymentNetwork, Utils.unwrap(address.environment));
        value1 != value2;
      },
    );
    payIds := HashMap.insert(payIds, _payId, tHash, tEqual, _addresses).0;
  };

  public shared ({ caller }) func deleteAll(payId : Text) : async () {
    assert (caller != Principal.fromText("2vxsx-fae"));
    let _payId = Utils.toLowerCase(payId);
    await _isOwner(caller, _payId);
    payIds := HashMap.insert(payIds, _payId, tHash, tEqual, []).0;
  };

  public shared ({ caller }) func add(payId : Text, address : Address) : async () {
    assert (caller != Principal.fromText("2vxsx-fae"));
    let _payId = Utils.toLowerCase(payId);
    await _isOwner(caller, _payId);
    var _addresses = _getPayId(_payId, "payid", null);
    _addresses := Array.filter(
      _addresses,
      func(e : Address) : Bool {
        let value1 = Text.concat(e.paymentNetwork, Utils.unwrap(e.environment));
        let value2 = Text.concat(Utils.toLowerCase(address.paymentNetwork), Utils.toLowerCase(Utils.unwrap(address.environment)));
        value1 != value2;
      },
    );

    let _address = {
      paymentNetwork = Utils.toLowerCase(address.paymentNetwork);
      environment = ?Utils.toLowerCase(Utils.unwrap(address.environment));
      addressDetailsType = address.addressDetailsType;
      addressDetails = address.addressDetails;
    };

    _addresses := Array.append(_addresses, [_address]);
    payIds := HashMap.insert(payIds, _payId, tHash, tEqual, _addresses).0;
  };

  public query func payStringExist(payString : Text) : async Bool {
    _payStringExist(payString);
  };

  public query func getPrice(name : Text) : async Nat {
    _getPrice(name);
  };

  public query func getPayId(payId : Text, paymentNetwork : Text, environment : ?Text) : async [Address] {
    _getPayId(payId, paymentNetwork, environment);
  };

  private func _getPayId(payId : Text, paymentNetwork : Text, environment : ?Text) : [Address] {
    let exist = HashMap.get(payIds, payId, tHash, tEqual);
    switch (exist) {
      case (?exist) {
        if (paymentNetwork == "payid") {
          exist;
        } else {
          let address = Array.filter(
            exist,
            func(e : Address) : Bool {
              Utils.toLowerCase(e.paymentNetwork) == Utils.toLowerCase(paymentNetwork) and e.environment == environment
            },
          );
        };
      };
      case (_) { [] };
    };
  };

  private func _isMaleName(name : Text) : Bool {
    let exist = Array.find(
      MaleNames.names,
      func(e : Text) : Bool {
        Utils.toLowerCase(name) == Utils.toLowerCase(e);
      },
    );
    switch (exist) {
      case (?exist) {
        return true;
      };
      case (null) {
        return false;
      };
    };
  };

  private func _isFemaleName(name : Text) : Bool {
    let exist = Array.find(
      FemaleNames.names,
      func(e : Text) : Bool {
        Utils.toLowerCase(name) == Utils.toLowerCase(e);
      },
    );
    switch (exist) {
      case (?exist) {
        return true;
      };
      case (null) {
        return false;
      };
    };
  };

  private func _isFemaleName2(name : Text) : Bool {
    let exist = Array.find(
      FemaleNames2.names,
      func(e : Text) : Bool {
        Utils.toLowerCase(name) == Utils.toLowerCase(e);
      },
    );
    switch (exist) {
      case (?exist) {
        return true;
      };
      case (null) {
        return false;
      };
    };
  };

  public query func getPayIdCount() : async Nat32 {
    payIdCount;
  };

  private func _getPrice(name : Text) : Nat {

    /*if (_isMaleName(name)) {
      return 10000000000;
    } else if (_isFemaleName(name)) {
      return 10000000000;
    } else if (_isFemaleName2(name)) {
      return 10000000000;
    };*/

    let exist = HashMap.get(prices, Nat32.fromNat(name.size()), n32Hash, n32Equal);
    switch (exist) {
      case (?exist) exist;
      //case (_) 300000000;
      case (_) 1000;
    };
  };

  private func _isEarlyAccess(principal : Principal) : async* () {
    let earlyAccessArray = StableBuffer.toArray(earlyAccess);
    let exist = Array.find(earlyAccessArray, func(e : Principal) : Bool { e == principal });
    switch (exist) {
      case (?exist) {};
      case (_) {
        throw (Error.reject("UnAuthorized"));
      };
    };
  };

  private func _payStringExist(payString : Text) : Bool {
    let exist = HashMap.get(payIds, payString, tHash, tEqual);

    switch (exist) {
      case (?exist) true;
      case (null) false;
    };
  };

  private func _isOwner(caller : Principal, payString : Text) : async () {
    if (payString.size() < 1) throw (Error.reject("Bad Request"));
    let blob = Text.encodeUtf8(Utils.toLowerCase(payString));
    let metadataList = await NFT.service().balance(caller);
    let exist = Array.find(metadataList, func(e : NFT.Metadata) : Bool { e.data == blob });
    switch (exist) {
      case (?exist) {};
      case (null) throw (Error.reject("Not Authorized"));
    };
  };

  public query func http_request(req : Http.HttpRequest) : async Http.HttpResponse {
    switch (req.method, req.url) {
      case ("GET", _) {
        let path = Iter.toArray(Text.tokens(req.url, #text("/")));
        if (path.size() == 1) {
          let payId = path[0];
          _payIdResponse(payId, req.headers);
        } else {
          let path = Iter.toArray(Text.tokens(req.url, #text("/")));
          {
            status_code = 400;
            headers = [];
            body = Text.encodeUtf8(path[0]);
            streaming_strategy = null;
            upgrade = null;
          };
        };
      };
      case ("OPTIONS", _) {
        {
          status_code = 204;
          headers = [("Access-Control-Allow-Headers", "*")];
          body = Blob.fromArray([]);
          streaming_strategy = null;
          upgrade = null;
        };
      };
      case ("POST", _) {
        {
          status_code = 204;
          headers = [];
          body = "";
          streaming_strategy = null;
          upgrade = ?true;
        };
      };
      case _ {
        {
          status_code = 400;
          headers = [];
          body = "Invalid request";
          streaming_strategy = null;
          upgrade = null;
        };
      };
    };
  };

  public func http_request_update(req : Http.HttpRequest) : async Http.HttpResponse {
    switch (req.method) {
      case ("POST") {
        counter += 1;
        {
          status_code = 201;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8("Counter updated to " # Nat.toText(counter) # "\n");
          streaming_strategy = null;
          upgrade = null;
        };
      };
      case _ {
        {
          status_code = 400;
          headers = [];
          body = "Invalid request";
          streaming_strategy = null;
          upgrade = null;
        };
      };
    };
  };

  private func _blobResponse(blob : Blob) : HttpParser.HttpResponse {
    let response : HttpParser.HttpResponse = {
      status_code = 200;
      headers = [("Content-Type", "application/json")];
      body = blob;
      streaming_strategy = null;
    };
  };

  private func _natResponse(value : Nat) : HttpParser.HttpResponse {
    let json = #Number(value);
    let blob = Text.encodeUtf8(JSON.show(json));
    let response : HttpParser.HttpResponse = {
      status_code = 200;
      headers = [("Content-Type", "application/json")];
      body = blob;
    };
  };

  private func _payIdResponse(payId : Text, headers : [Http.HeaderField]) : Http.HttpResponse {
    let _headers = HashMapPrim.fromIter<Text, Text>(headers.vals(), 0, Text.equal, Text.hash);
    var acceptHeader : ?Text = null;
    var versionHeader : ?Text = null;
    for (header in headers.vals()) {
      switch (header.0) {
        case ("accept") {
          acceptHeader := ?header.1;
        };
        case ("payid-version") {
          versionHeader := ?header.1;
        };
        case (_) {

        };
      };
    };

    switch (versionHeader) {
      case (?versionHeader) {
        if (versionHeader != Constants.Version) {
          return {
            status_code = 400;
            headers = [];
            body = Text.encodeUtf8(versionHeader);
            streaming_strategy = null;
            upgrade = null;
          };
        };
      };
      case (null) {

      };
    };

    var addressBuffer : Buffer.Buffer<JSON> = Buffer.fromArray([]);
    var json : JSON = #Null;
    switch (acceptHeader) {
      case (?acceptHeader) {
        let currency = Utils.getCurrenyFromText(acceptHeader);
        let exist = HashMap.get(payIds, payId, tHash, tEqual);
        switch (exist) {
          case (?exist) {
            if (Utils.toLowerCase(currency.paymentNetwork) == "payid") {
              json := Utils.addressToJSON(payId, exist);
              let blob = Text.encodeUtf8(JSON.show(json));
              return {
                status_code = 200;
                headers = Constants.Default_Headers;
                body = blob;
                streaming_strategy = null;
                upgrade = null;
              };
            };
            let address = Array.find(
              exist,
              func(e : Address) : Bool {
                Utils.toLowerCase(e.paymentNetwork) == Utils.toLowerCase(currency.paymentNetwork) and e.environment == currency.environment
              },
            );
            switch (address) {
              case (?address) {
                json := Utils.addressToJSON(payId, [address]);
              };
              case (_) {
                return {
                  status_code = 404;
                  headers = [];
                  body = "Not Found";
                  streaming_strategy = null;
                  upgrade = null;
                };
              };
            };
          };
          case (_) {
            return {
              status_code = 404;
              headers = [];
              body = "Not Found";
              streaming_strategy = null;
              upgrade = null;
            };
          };
        };
        let blob = Text.encodeUtf8(JSON.show(json));
        let response : Http.HttpResponse = {
          status_code = 200;
          headers = [("Content-Type", "application/json")];
          body = blob;
          streaming_strategy = null;
          upgrade = null;
        };
      };
      case (_) {
        return {
          status_code = 400;
          headers = [];
          body = "Invalid request";
          streaming_strategy = null;
          upgrade = null;
        };
      };
    };
  };

  var counter = 0;

  public query func getCounter() : async Nat {
    counter;
  };
};
