import Principal "mo:base/Principal";
import HashMap "mo:stable/HashMap";
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
  private stable var admins = StableBuffer.init<(Principal)>();
  private stable var prices = HashMap.empty<Nat32, Nat>();

  StableBuffer.add(admins, Principal.fromText("j26ec-ix7zw-kiwcx-ixw6w-72irq-zsbyr-4t7fk-alils-u33an-kh6rk-7qe"));
  StableBuffer.add(admins, Principal.fromText("ve3v4-o7xuv-ijejl-vcyfx-hjy3b-owwtx-jte2k-2bciw-spskd-jgmvd-rqe"));

  public shared ({ caller }) func setPrice(symbolSize : Nat32, price : Nat) : async () {
    await* _isAdmin(caller);
    prices := HashMap.insert(prices, symbolSize, n32Hash, n32Equal, price).0;
  };

  public shared ({ caller }) func auction(payId : Text) : async Nat32 {
    let nftCanister = Principal.fromText(Constants.NFT_Canister);
    //let allowance = await DIP20.service(Constants.WICP_Canister).allowance(caller,nftCanister);
    let price = _getPrice(payId);
    //if(allowance < price) throw(Error.reject("Insufficient Allowance"));
    let day = 86400;
    let blob = Text.encodeUtf8(Utils.toLowerCase(payId));
    let mintId = await NFT.service().mint(blob, Principal.fromActor(this));
    let auctionRequest = {
      duration = day * 3;
      mintId = mintId;
      amount = price;
      token = #Dip20(Constants.WICP_Canister);
    };
    await NFT.service().auctionAndBid(auctionRequest,caller);
    mintId;
  };

  public shared ({ caller }) func update(request : AddressRequest) : async () {
    await _isOwner(caller, request.payId);
    let payId = Utils.toLowerCase(request.payId);
    let addresses : Buffer.Buffer<Address> = Buffer.fromArray([]);
    for (address in request.addresses.vals()) {
      var environment : ?Text = null;
      switch (address.environment) {
        case (?_environment) environment := ?Utils.toLowerCase(_environment);
        case (_) {

        };
      };
      let _address : Address = {
        paymentNetwork = Utils.toLowerCase(address.paymentNetwork);
        environment = environment;
        addressDetailsType = address.addressDetailsType;
        addressDetails = address.addressDetails;
      };
      addresses.add(_address);
    };
    payIds := HashMap.insert(payIds, payId, tHash, tEqual, Buffer.toArray(addresses)).0;

  };

  public shared ({ caller }) func add(payId : Text, addresses : [Address]) : async () {
    let _payId = Utils.toLowerCase(payId);
    await _isOwner(caller, _payId);
    var _addresses = _getPayId(_payId, "payid", null);
    let addressBuffer : Buffer.Buffer<Address> = Buffer.fromArray([]);
    for (address in addresses.vals()) {
      var environment : ?Text = null;
      switch (address.environment) {
        case (?_environment) environment := ?Utils.toLowerCase(_environment);
        case (_) {

        };
      };
      let _address : Address = {
        paymentNetwork = Utils.toLowerCase(address.paymentNetwork);
        environment = environment;
        addressDetailsType = address.addressDetailsType;
        addressDetails = address.addressDetails;
      };
      addressBuffer.add(_address);
    };
    _addresses := Array.append(_addresses,Buffer.toArray(addressBuffer));
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
        if(paymentNetwork == "payid"){
          exist
        }else{
          let address = Array.filter(
          exist,
          func(e : Address) : Bool {
             e.paymentNetwork == paymentNetwork and e.environment == environment
          },
        );
        }
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

  /*public query ({ caller }) func fetchPayIds() : async [Text] {
    _fetchPayIds(caller);
  };*/

  public query func http_request(request : HttpParser.HttpRequest) : async HttpParser.HttpResponse {
    let req = HttpParser.parse(request);
    let { url } = req;
    let { headers } = req;
    let { path } = url;

    switch (req.method, path.original) {
      case (_) {
        let path = Iter.toArray(Text.tokens(url.original, #text("/")));
        if (path.size() == 2) {
          let payId = path[1];
          _payIdResponse(payId, headers);
        } else {
          return Http.BAD_REQUEST();
          //return _headerResponse("Origin",headers);
        };
      };
    };

  };

  private func _getPrice(name : Text) : Nat {

    if (_isMaleName(name)) {
      return 10000000000;
    } else if (_isFemaleName(name)) {
      return 10000000000;
    } else if (_isFemaleName2(name)) {
      return 10000000000;
    };

    let exist = HashMap.get(prices, Nat32.fromNat(name.size()), n32Hash, n32Equal);
    switch (exist) {
      case (?exist) exist;
      case (_) 300000000;
    };
  };

  private func _isAdmin(principal : Principal) : async* () {
    let adminArray = StableBuffer.toArray(admins);
    let exist = Array.find(adminArray, func(e : Principal) : Bool { e == principal });
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
      case (null) throw(Error.reject("Not Authorized"));
    };
  };

  /*private func _fetchPayIds(owner : Principal) : [Text] {
    let exist = HashMap.get(manifest, owner, pHash, pEqual);
    switch (exist) {
      case (?exist) exist;
      case (null)[];
    };
  };*/

  private func _blobResponse(blob : Blob) : Http.Response {
    let response : Http.Response = {
      status_code = 200;
      headers = [("Content-Type", "application/json")];
      body = blob;
      streaming_strategy = null;
    };
  };

  private func _headerResponse(key : Text, headers : HttpParser.Headers) : Http.Response {
    let originHeader = headers.get(key);
    var result = "";
    switch (originHeader) {
      case (?originHeader) {
        result := originHeader[0];
      };
      case (null) {
        return Http.BAD_REQUEST();
      };
    };
    let response : Http.Response = {
      status_code = 200;
      headers = [("Content-Type", "application/json")];
      body = Text.encodeUtf8(result);
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

  private func _payIdResponse(payId : Text, headers : HttpParser.Headers) : HttpParser.HttpResponse {
    let acceptHeader = headers.get("Accept");
    let versionHeader = headers.get("PayID-Version");

    switch (versionHeader) {
      case (?versionHeader) {
        if (versionHeader[0] != Constants.Version) return Http.BAD_REQUEST();
      };
      case (null) {
        return Http.BAD_REQUEST();
      };
    };

    var addressBuffer : Buffer.Buffer<JSON> = Buffer.fromArray([]);
    var json : JSON = #Null;
    switch (acceptHeader) {
      case (?acceptHeader) {
        if (acceptHeader.size() < 1) return Http.BAD_REQUEST();
        let currency = Utils.getCurrenyFromText(acceptHeader[0]);
        let exist = HashMap.get(payIds, payId, tHash, tEqual);
        switch (exist) {
          case (?exist) {
            if (currency.paymentNetwork == "payid") {
              json := Utils.addressToJSON(payId, exist);
              let blob = Text.encodeUtf8(JSON.show(json));
              return {
                status_code = 200;
                headers = Constants.Default_Headers;
                body = blob;
              };
            };
            let address = Array.find(
              exist,
              func(e : Address) : Bool {
                e.paymentNetwork == currency.paymentNetwork and e.environment == currency.environment
              },
            );
            switch (address) {
              case (?address) {
                json := Utils.addressToJSON(payId, [address]);
              };
              case (_) {
                return return Http.NOT_FOUND();
              };
            };
          };
          case (_) {
            return return Http.NOT_FOUND();
          };
        };
        let blob = Text.encodeUtf8(JSON.show(json));
        let response : HttpParser.HttpResponse = {
          status_code = 200;
          headers = [("Content-Type", "application/json")];
          body = blob;
        };
      };
      case (_) return Http.BAD_REQUEST();
    };
  };

};
