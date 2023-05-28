import Address "Address";
import Text "mo:base/Text";

module {

    private type Address = Address.Address;

    public type PaymentInformation = {
        addresses: [Address];
        payId:?Text;
        memo:?Text;
    }
}