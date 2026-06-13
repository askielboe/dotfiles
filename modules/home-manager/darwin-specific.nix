{
  pkgs,
  nixpkgs-unstable,
  private,
  ...
}:
let
  # Wrapper that pre-trusts the current directory so Claude never shows the trust dialog
  claude-wrapper = pkgs.writeShellScript "claude-trust-dir" ''
    CLAUDE_JSON="$HOME/.claude/.claude.json"
    DIR="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)"
    if [ -f "$CLAUDE_JSON" ]; then
      tmp=$(mktemp)
      ${pkgs.jq}/bin/jq --arg dir "$DIR" '
        .projects[$dir] = (.projects[$dir] // {}) |
        .projects[$dir].hasTrustDialogAccepted = true |
        .projects[$dir].hasClaudeMdExternalIncludesApproved = true |
        .projects[$dir].hasClaudeMdExternalIncludesWarningShown = true
      ' "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
    fi
  '';
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home = {
    inherit (private.user) homeDirectory;

    file = {
      ".config/ghostty/config".source = ./dotfiles/ghostty/config;
    };

    shellAliases = {
      bw = "bwbio";
      o = "open .";
      cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";
      bearcli = "/Applications/Bear.app/Contents/MacOS/bearcli";
    };

    packages = with pkgs; [
      unstable.colima # lima dependency is EOL in stable
      ripsecrets # Find secrets
      transmission_4
      yt-dlp
    ];
  };

  programs.ssh.settings = {
    "github.com".IdentityFile = "~/.ssh/id_ed25519-github";
    "flextribe".IdentityFile = "~/.ssh/id_ed25519-github";
    "storagebox-restic".IdentityFile = "~/.ssh/id_ed25519-storagebox";
    "garage-hetzner".IdentityFile = "~/.ssh/id_ed25519-hetzner-garage";
  };

  programs.zsh.initContent = ''
    hs() {
      echo "darwin-rebuild switch --flake"
      export NIXPKGS_ALLOW_UNFREE=1
      sudo -E darwin-rebuild switch --flake ~/.config/nix/'.#${private.user.username}' --impure
      exec $SHELL
    }

    claude() {
      ${claude-wrapper}
      command claude "$@"
    }
  '';

  # Bear MCP bridge: expose the local `bearcli mcp-server` (stdio) as Streamable
  # HTTP on 127.0.0.1:9099 so the k3s gateway can proxy to it remotely (Tailscale
  # egress → https://mcp.skielboe.com/bear/mcp). bearcli only runs on macOS, so
  # this must live on this machine. Works only while the Mac is awake/logged in.
  #
  # Tailnet exposure is declarative: the nix-darwin module
  # modules/darwin/settings/tailscale.nix enables tailscaled and asserts
  #   tailscale serve --bg --tcp 9099 tcp://127.0.0.1:9099
  # which makes this device reachable at <device>:9099 on the tailnet — the
  # endpoint the cluster's Tailscale egress targets. Only `sudo tailscale up`
  # (login) is manual, and only once.
  launchd.agents.bear-mcp-bridge = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.uv}/bin/uvx" # uv ships uvx; fetches+caches mcp-proxy from PyPI on first run
        "mcp-proxy"
        "--host"
        "127.0.0.1"
        "--port"
        "9099"
        "--"
        "/Applications/Bear.app/Contents/MacOS/bearcli"
        "mcp-server"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${private.user.homeDirectory}/Library/Logs/bear-mcp-bridge.out.log";
      StandardErrorPath = "${private.user.homeDirectory}/Library/Logs/bear-mcp-bridge.err.log";
      EnvironmentVariables = {
        HOME = private.user.homeDirectory; # uv cache lives under $HOME
        PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
