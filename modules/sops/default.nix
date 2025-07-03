{
  sops = {
    age.keyFile = "/Users/askielboe/.config/nix/modules/sops/age/keys.txt";
    defaultSopsFile = ./.sops.yaml;
    secrets = {
      "resticprofile.yaml" = {
        sopsFile = ./secrets/resticprofile.yaml;
      };
    };
  };
}
