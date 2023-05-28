import AddressDetailsType "AddressDetailsType";
import AddressDetails "AddressDetails";

module {

    private type AddressDetailsType = AddressDetailsType.AddressDetailsType;
    private type AddressDetails = AddressDetails.AddressDetails;

    public type Address = {
        paymentNetwork: Text;
        environment: ?Text;
        addressDetailsType: AddressDetailsType;
        addressDetails: AddressDetails
    };
}