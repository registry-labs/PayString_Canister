import Int64 "mo:base/Int64";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Array "mo:base/Array";
import List "mo:base/List";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Option "mo:base/Option";
import Prim "mo:prim";
import Int "mo:base/Int";
import Int32 "mo:base/Int32";
import Nat32 "mo:base/Nat32";
import JSON "mo:json/JSON";
import Blob "mo:base/Blob";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import P "mo:base/Prelude";
import Address "../models/Address";
import AddressDetails "../models/AddressDetails";
import Constants "../Constants";

module {

    private type JSON = JSON.JSON;
    private type Address = Address.Address;
    private type AddressDetails = AddressDetails.AddressDetails;

    public func natToFloat(value : Nat) : Float {
        return Float.fromInt(value);
    };

    public func floatToNat(value : Float) : Nat {
        let int = Float.toInt(value);
        let text = Int.toText(int);
        return textToNat(text);
    };

    public func includesText(string : Text, term : Text) : Bool {
        let stringArray = Iter.toArray<Char>(toLowerCase(string).chars());
        let termArray = Iter.toArray<Char>(toLowerCase(term).chars());

        var i = 0;
        var j = 0;

        while (i < stringArray.size() and j < termArray.size()) {
            if (stringArray[i] == termArray[j]) {
                i += 1;
                j += 1;
                if (j == termArray.size()) { return true };
            } else {
                i += 1;
                j := 0;
            };
        };
        false;
    };

    public func toLowerCase(value : Text) : Text {
        let chars = Text.toIter(value);
        var lower = "";
        for (c : Char in chars) {
            lower := Text.concat(lower, Char.toText(Prim.charToLower(c)));
        };
        return lower;
    };

    public func nat32ToInt(value : Nat32) : Int {
        let int32 = Int32.fromNat32(value);
        Int32.toInt(int32);
    };

    public func textToNat32(txt : Text) : Nat32 {
        assert (txt.size() > 0);
        let chars = txt.chars();

        var num : Nat32 = 0;
        for (v in chars) {
            let charToNum = Char.toNat32(v) -48;
            assert (charToNum >= 0 and charToNum <= 9);
            num := num * 10 + charToNum;
        };

        num;
    };

    public func textToNat(txt : Text) : Nat {
        assert (txt.size() > 0);
        let chars = txt.chars();

        var num : Nat = 0;
        for (v in chars) {
            let charToNum = Char.toNat32(v) -48;
            assert (charToNum >= 0 and charToNum <= 9);
            num := num * 10 + Nat32.toNat(charToNum);
        };

        num;
    };

    public func unwrap<T>(x : ?T) : T = switch x {
        case null { P.unreachable() };
        case (?x_) { x_ };
    };

    public func addressToJSON(payId : Text, addresses : [Address]) : JSON {
        let map : HashMap.HashMap<Text, JSON> = HashMap.HashMap<Text, JSON>(
            0,
            Text.equal,
            Text.hash,
        );

        var addressesJSON : Buffer.Buffer<JSON> = Buffer.fromArray([]);

        let _payId = Text.concat(payId#"$",Constants.Domain);
        map.put("payId", #String(_payId));

        for (address in addresses.vals()) {
            let _map : HashMap.HashMap<Text, JSON> = HashMap.HashMap<Text, JSON>(
                0,
                Text.equal,
                Text.hash,
            );

            let addressDetails = _addressDetailaToJSON(address.addressDetails);

            _map.put("paymentNetwork", #String(address.paymentNetwork));
            _map.put("addressDetails", #Object(addressDetails));

            switch (address.addressDetailsType) {
                case (#CryptoAddress) {
                    _map.put("addressDetailsType", #String("CryptoAddressDetails"));
                };
                case (#FiatAddress) {
                    _map.put("addressDetailsType", #String("FiatAddressDetails"));
                };
            };

            switch (address.environment) {
                case (?environment) {
                    _map.put("environment", #String(environment));
                };
                case (_) {

                };
            };

            let json = #Object(Iter.toArray(_map.entries()));
            addressesJSON.add(json);
        };

        map.put("addresses", #Array(Buffer.toArray(addressesJSON)));

        #Object(Iter.toArray(map.entries()));
    };

    private func _addressDetailaToJSON(addressDetails : AddressDetails) : [(Text, JSON)] {
        let map : HashMap.HashMap<Text, JSON> = HashMap.HashMap<Text, JSON>(
            0,
            Text.equal,
            Text.hash,
        );

        switch (addressDetails) {
            case (#CryptoAddressDetails(value)) {
                map.put("address", #String(value.address));
                switch (value.tag) {
                    case (?tag) {
                        map.put("tag", #String(tag));
                    };
                    case (_) {

                    };
                };
            };
            case (#FiatAddressDetails(value)) {
                map.put("accountNumber", #String("accountNumber"));
                switch (value.routingNumber) {
                    case (?routingNumber) {
                        map.put("routingNumber", #String(routingNumber));
                    };
                    case (_) {

                    };
                };
            };
        };

        Iter.toArray(map.entries());
    };

    public func getCurrenyFromText(text:Text): {paymentNetwork:Text;environment:?Text} {
        let path = Iter.toArray(Text.tokens(text, #text("/")));
        let _path = Iter.toArray(Text.tokens(path[1], #text("+")));
        let value = Iter.toArray(Text.tokens(_path[0], #text("-")));
        let paymentNetwork = value[0];
        let environment = value[1];
        {
            paymentNetwork = paymentNetwork;
            environment = ?environment;
        }
    }
};
