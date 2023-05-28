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

  public shared({caller}) func create(request:AddressRequest): async () {
    let currentPayStringId = payStringId;
    payStringId := payStringId + 1;
    manifest := HashMap.insert(manifest,caller,pHash,pEqual,request.payId).0;
    payStrings := HashMap.insert(payStrings,request.payId,tHash,tEqual,request.addresses).0;
  };

  public shared({caller}) func delete(): async () {
    assert(payStringId > 0);
    let currentPayStringId = payStringId;
    payStringId := payStringId - 1;
    let exist = HashMap.get(manifest,caller,pHash,pEqual);
    switch(exist){
      case(?exist){
        manifest := HashMap.remove(manifest,caller,pHash,pEqual).0;
        payStrings := HashMap.remove(payStrings,exist,tHash,tEqual).0;
      };
      case(_){

      }
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
          let blob = Text.encodeUtf8(path[1]);
          _blobResponse(blob);
        }else{
         return return Http.BAD_REQUEST();
        }
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

  private func _payIdResponse(url : HttpParser.URL) : HttpParser.HttpResponse {
    let search = url.queryObj.get("query");
    var tokensBuffer : Buffer.Buffer<JSON> = Buffer.fromArray([]);
    let json = #Array(Buffer.toArray(tokensBuffer));
    let blob = Text.encodeUtf8(JSON.show(json));
    let response : HttpParser.HttpResponse = {
      status_code = 200;
      headers = [("Content-Type", "application/json")];
      body = blob;
    };
  };
  
};
