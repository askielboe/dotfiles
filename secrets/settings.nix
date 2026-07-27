# Non-sensitive user/machine settings needed at nix EVAL time. Everything in
# this file is already de-facto public: git author metadata carries name/email,
# committed literal paths carry username/homeDirectory, and the signing key is
# the public half. Anything sensitive (ssh hosts, 1Password account/item IDs,
# clickhouse endpoint) lives sops-encrypted in secrets/secrets.yaml and is
# decrypted at activation by sops-nix — never at eval, which is what keeps the
# flake pure.
{
  user = {
    name = "Andreas Skielboe";
    email = "skielboe@gmail.com";
    username = "askielboe";
    homeDirectory = "/Users/askielboe";
    signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUk1npSjpgOHYCDusD19DG+YcnG1lc79VLZBpSqNaHZ";
  };

  accounts.awsProfiles = {
    default = {
      region = "eu-west-1";
    };
    work = {
      # Deliberately neutral profile name: the real org name stays out of the
      # public repo. The credential_process wiring for both profiles lives in
      # the sops-managed ~/.aws/credentials (secrets.yaml key aws-credentials).
      name = "work";
      region = "eu-central-1";
    };
  };
}
