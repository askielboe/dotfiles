{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Private Host blocks (hostnames, users, ports of personal machines) come
    # from the sops-decrypted fragment, kept out of the public repo AND the
    # nix store. Rendered at the top of ~/.ssh/config; ssh is first-value-wins
    # per option, so these blocks take precedence while the `Host *` block
    # below still supplies IdentityAgent. A missing file (before the first
    # sops-nix activation) is not an ssh error.
    includes = [ "config.d/private" ];
    settings = {
      "*" = {
        IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentitiesOnly = true;
      };
      "flextribe" = {
        HostName = "github.com";
        User = "git";
        IdentitiesOnly = true;
      };
    };
  };
}
