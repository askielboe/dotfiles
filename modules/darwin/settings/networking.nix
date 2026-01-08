{ private, ... }:
{
  networking = {
    computerName = private.machine.computerName;
    hostName = private.machine.computerName;
    localHostName = private.machine.computerName;
    knownNetworkServices = [
      "Wi-Fi"
    ];
    dns = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    applicationFirewall = {
      enable = true;
      enableStealthMode = true;
    };
  };
}
