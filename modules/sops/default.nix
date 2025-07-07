{
  sops = {
    age.keyFile = "/Users/askielboe/.config/nix/modules/sops/age/keys.txt";
    defaultSopsFile = ./.sops.yaml;
    secrets = {
      anthropic_api_key = {
        sopsFile = ./secrets/anthropic.yaml;
      };
    };
  };
}
