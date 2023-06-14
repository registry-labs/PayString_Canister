module {
    public let Domain = "awesome.com";
    public let Version = "1.0";
    public let Default_Headers = [
        ("Content-Type", "application/json"),
        ("Access-Control-Allow-Origin", "*"),
        ("Access-Control-Allow-Credentials", "true"),
        ("Access-Control-Allow-Headers","PayID-Version, Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers"),
        ("Access-Control-Allow-Methods", "GET,HEAD,OPTIONS,POST,PUT")];
}