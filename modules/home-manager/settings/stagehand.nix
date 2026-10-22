{ lib, pkgs, ... }:
let
  browse = pkgs.callPackage ./stagehand { };
in
{
  home.packages = [ browse ];

  home.file =
    lib.genAttrs
      [
        ".agents/skills/browse"
        ".claude/skills/browse"
        ".pi/agent/skills/browse"
        ".config/hax/skills/browse"
      ]
      (_: {
        source = "${browse}/lib/browse/node_modules/browse/skills/browse";
      });
}
