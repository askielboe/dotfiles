{ lib, pkgs, nixpkgs-unstable, private, ... }:
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
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  home.homeDirectory = private.user.homeDirectory;

  home.file = {
    ".config/ghostty/config".source = ./dotfiles/ghostty/config;
  };

  home.shellAliases = {
    bw = "bwbio";
    o = "open .";
    cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";
    bearcli = "/Applications/Bear.app/Contents/MacOS/bearcli";
  };

  programs.ssh.matchBlocks = {
    "github.com".identityFile = "~/.ssh/id_ed25519-github";
    "flextribe".identityFile = "~/.ssh/id_ed25519-github";
    "storagebox-restic".identityFile = "~/.ssh/id_ed25519-storagebox";
    "garage-hetzner".identityFile = "~/.ssh/id_ed25519-hetzner-garage";
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

  home.packages = with pkgs; [
    unstable.colima # lima dependency is EOL in stable
    ripsecrets # Find secrets
    transmission_4
    yt-dlp

    # Casks managed via brew-nix (pinned in flake.lock)
    brewCasks.vlc
    brewCasks.signal
  ];

}
