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
  private stable var manifest = HashMap.empty<Principal, [Text]>();
  private stable var payIds = HashMap.empty<Text, [Address]>();

  public shared ({ caller }) func create(request : AddressRequest) : async () {
    if(request.payId.size() < 1) throw(Error.reject("Bad Request"));
    let payId = Utils.toLowerCase(request.payId);
    let payStringExist = _payStringExist(request.payId);
    if(payStringExist) throw(Error.reject("Paystring Already Exist"));
    let currentpayIdCount = payIdCount;
    payIdCount := payIdCount + 1;
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
    manifest := HashMap.insert(manifest, caller, pHash, pEqual, [payId]).0;
    payIds := HashMap.insert(payIds, payId, tHash, tEqual, Buffer.toArray(addresses)).0;

  };

  public shared ({ caller }) func update(payId:Text,request : AddressRequest) : async () {
    let _payId = Utils.toLowerCase(payId);
    let isOwner = await* _isOwner(caller,_payId);
    if (isOwner == false) throw(Error.reject("UnAuthorized"));
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
    payIds := HashMap.insert(payIds, _payId, tHash, tEqual, Buffer.toArray(addresses)).0;

  };

  public shared ({ caller }) func delete(payId:Text) : async () {
    assert (payIdCount > 0);
    if(payId.size() < 1) throw(Error.reject("Bad Request"));
    let currentpayIdCount = payIdCount;
    payIdCount := payIdCount - 1;
    let isOwner = await* _isOwner(caller,payId);
    if(isOwner == false) throw(Error.reject("UnAuthroized"));
    payIds := HashMap.remove(payIds, payId, tHash, tEqual).0;
  };

  public query func getPayIdCount(): async Nat32 {
    payIdCount
  };

  public query({caller}) func fetchPayIds(): async [Text] {
    _fetchPayIds(caller)
  };

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

  private func _payStringExist(payString:Text): Bool {
    let exist = HashMap.get(payIds,payString,tHash,tEqual);

    switch(exist){
      case(?exist) true;
      case(null) false;
    };
  };

  private func _isOwner(caller:Principal,payString:Text): async* Bool {
    let _payIds = _fetchPayIds(caller);
    let exist = Array.find(_payIds,func(e:Text):Bool{e == payString});
    switch(exist){
      case(?exist) true;
      case(null) false;
    };
  };

  private func _fetchPayIds(owner:Principal): [Text] {
    let exist = HashMap.get(manifest,owner,pHash,pEqual);
    switch(exist){
      case(?exist) exist;
      case(null) [];
    };
  };

  private func _blobResponse(blob : Blob) : Http.Response {
    let response : Http.Response = {
      status_code = 200;
      headers = [("Content-Type", "application/json")];
      body = blob;
      streaming_strategy = null;
    };
  };

  private func _headerResponse(key:Text,headers : HttpParser.Headers) : Http.Response {
    let originHeader = headers.get(key);
    var result = "";
    switch(originHeader){
      case(?originHeader){
        result := originHeader[0]
      };
      case(null){
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

    switch(versionHeader){
      case(?versionHeader){
        if(versionHeader[0] != Constants.Version) return Http.BAD_REQUEST();
      };
      case(null){
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
                headers = [("Content-Type", "application/json")];
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
