{
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home = {
    packages = [ unstable.codex ];
    file.".codex/AGENTS.md".text = ''
      ## Code hygiene

      - Comments explain why, never what.
      - Do not create documentation unless explicitly requested.
      - Do not duplicate information across code, comments, and documentation.
      - Before adding an abstraction or helper, search for an existing one.
      - Prefer deletion and consolidation over addition.
      - When modifying code, remove code and comments made obsolete by the change.
      - Do not preserve obsolete compatibility paths unless required.

      ## Autonomy

      - When a request includes implementation, run in-scope commands and edit in-scope files without asking for confirmation.
    '';

    # The desktop app mutates this file, so keep its state and enforce only these defaults.
    activation.codexFullAccess = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/.codex/config.toml"
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$cfg")"
      tmp="$(${pkgs.coreutils}/bin/mktemp "$cfg.XXXXXX")"

      if [ -f "$cfg" ]; then
        input="$cfg"
      else
        input=/dev/null
      fi

      if ${pkgs.yq-go}/bin/yq -p toml -o toml '
        .approval_policy = "never" |
        .sandbox_mode = "danger-full-access" |
        .notice.hide_full_access_warning = true |
        .apps._default.default_tools_approval_mode = "approve" |
        .apps._default.destructive_enabled = true |
        .apps._default.open_world_enabled = true
      ' "$input" > "$tmp"; then
        ${pkgs.coreutils}/bin/chmod 600 "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$cfg"
      else
        ${pkgs.coreutils}/bin/rm -f "$tmp"
        echo "⚠️  Codex config isn't valid TOML; left it untouched." >&2
      fi
    '';
  };
}
