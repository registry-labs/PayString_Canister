import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Prim "mo:⛔";
import Prelude "mo:base/Prelude";

module Http {
    public type StreamingCallbackHttpResponse = {
        body : Blob;
        token : ?Token;
    };

    public type Token = {
        // Add whatever fields you'd like
        arbitrary_data : Text;
    };

    public type CallbackStrategy = {
        callback : shared query (Token) -> async StreamingCallbackHttpResponse;
        token : Token;
    };

    public type StreamingStrategy = {
        #Callback : CallbackStrategy;
    };

    public type HeaderField = (Text, Text);

    public type HttpResponse = {
        status_code : Nat16;
        headers : [HeaderField];
        body : Blob;
        streaming_strategy : ?StreamingStrategy;
        upgrade : ?Bool;
    };

    public type HttpRequest = {
        method : Text;
        url : Text;
        headers : [HeaderField];
        body : Blob;
    };

    public func isGzip(x : HeaderField) : Bool {
        Text.map(x.0, Prim.charToLower) == "accept-encoding" and Text.contains(Text.map(x.1, Prim.charToLower), #text "gzip");
    };
};
