import Address "Address";

module {
    
    private type Address = Address.Address;

    public type AddressRequest = {
        payId:Text;
        addresses:[Address];
    };
}