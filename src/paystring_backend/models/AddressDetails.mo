import FiatAddressDetails "FiatAddressDetails";
import CryptoAddressDetails "CryptoAddressDetails";

module {

    private type CryptoAddressDetails = CryptoAddressDetails.CryptoAddressDetails;
    private type FiatAddressDetails = FiatAddressDetails.FiatAddressDetails;

    public type AddressDetails = {
        #CryptoAddressDetails:CryptoAddressDetails;
        #FiatAddressDetails:FiatAddressDetails
    }
}