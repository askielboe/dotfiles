{
  pkgs,
  lib,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}:
let
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
  pythonSet =
    (pkgs.callPackage pyproject-nix.build.packages { python = pkgs.python312; }).overrideScope
      (
        lib.composeManyExtensions [
          pyproject-build-systems.overlays.wheel
          (workspace.mkPyprojectOverlay { sourcePreference = "wheel"; })
          (final: prev: {
            # These legacy sdists omit their setuptools build requirement.
            pybars3 = prev.pybars3.overrideAttrs (old: {
              nativeBuildInputs =
                (old.nativeBuildInputs or [ ]) ++ final.resolveBuildSystem { setuptools = [ ]; };
            });
            pymeta3 = prev.pymeta3.overrideAttrs (old: {
              nativeBuildInputs =
                (old.nativeBuildInputs or [ ]) ++ final.resolveBuildSystem { setuptools = [ ]; };
            });
          })
        ]
      );
  virtualenv = pythonSet.mkVirtualEnv "basic-memory-env" workspace.deps.default;
in
pkgs.runCommand "basic-memory-0.23.2" { meta.mainProgram = "bm"; } ''
  mkdir -p "$out/bin"
  ln -s ${virtualenv}/bin/bm "$out/bin/bm"
  ln -s ${virtualenv}/bin/basic-memory "$out/bin/basic-memory"
''
