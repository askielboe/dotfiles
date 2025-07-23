{ ... }:
{
  networking = {
    computerName = "swaggermis";
    hostName = "swaggermis";
    localHostName = "swaggermis";
    knownNetworkServices = [
      "Wi-Fi"
    ];
    dns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  system.defaults.alf = {
    globalstate = 1;
    stealthenabled = 1;
  };
}
