{ ... }:
{
  environment = {
    variables = {
      SOPS_AGE_KEY_FILE = "$HOME/.config/nix/modules/sops/age/keys.txt";
      AIDER_ATTRIBUTE_AUTHOR = "false";
    };
  };
}
