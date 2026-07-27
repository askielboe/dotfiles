{
  networking = {
    # computerName/hostName/localHostName are deliberately NOT nix-managed:
    # the machine name is kept out of the public repo. macOS persists the
    # names in SCPreferences, so the existing values survive activations;
    # set them once on a new machine with `scutil --set {ComputerName,HostName,LocalHostName} <name>`.
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
