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

  private stable var payStringId : Nat32 = 1;
  private stable var manifest = HashMap.empty<Principal, Text>();
  private stable var payStrings = HashMap.empty<Text, [Address]>();

  public shared ({ caller }) func create(request : AddressRequest) : async () {
    let currentPayStringId = payStringId;
    payStringId := payStringId + 1;
    let addresses : Buffer.Buffer<Address> = Buffer.fromArray([]);
    for (address in request.addresses.vals()) {
      var environment:?Text = null;
      switch(address.environment){
        case(?_environment) environment := ?Utils.toLowerCase(_environment);
        case(_){

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
    manifest := HashMap.insert(manifest, caller, pHash, pEqual, request.payId).0;
    payStrings := HashMap.insert(payStrings, request.payId, tHash, tEqual, Buffer.toArray(addresses)).0;

  };

  public shared ({ caller }) func delete() : async () {
    assert (payStringId > 0);
    let currentPayStringId = payStringId;
    payStringId := payStringId - 1;
    let exist = HashMap.get(manifest, caller, pHash, pEqual);
    switch (exist) {
      case (?exist) {
        manifest := HashMap.remove(manifest, caller, pHash, pEqual).0;
        payStrings := HashMap.remove(payStrings, exist, tHash, tEqual).0;
      };
      case (_) {

      };
    };
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
        };
      };
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
    let _headers = headers.get("Accept");
    var addressBuffer : Buffer.Buffer<JSON> = Buffer.fromArray([]);
    var json : JSON = #Null;
    switch (_headers) {
      case (?_headers) {
        if (_headers.size() < 1) return Http.BAD_REQUEST();
        let currency = Utils.getCurrenyFromText(_headers[0]);
        let exist = HashMap.get(payStrings, payId, tHash, tEqual);
        switch (exist) {
          case (?exist) {
            if (currency.paymentNetwork == "payid") json := Utils.addressToJSON(payId, exist);
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
