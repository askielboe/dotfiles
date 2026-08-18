{
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

      - When a request includes implementation, edit in-scope files without asking for confirmation.
    '';
  };
}
