{ ... }:
{
  sops.secrets."resticprofile.yaml" = {
    path = "/Users/askielboe/.config/restic/profile.conf";
    mode = "0600";
  };
}
