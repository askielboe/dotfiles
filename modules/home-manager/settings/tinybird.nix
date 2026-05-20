{
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    (lib.hiPrio (
      pkgs.writeShellApplication {
        name = "tb";
        runtimeInputs = [
          pkgs.uv
          pkgs.python311
        ];
        text = ''
          exec uv tool run --quiet --from tinybird --python 3.11 tb "$@"
        '';
      }
    ))
  ];
}
