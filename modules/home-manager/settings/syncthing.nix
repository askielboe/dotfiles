{ config, ... }:
let
  workDir = "${config.home.homeDirectory}/work";
in
{
  services.syncthing = {
    enable = true;
    settings = {
      devices.dobby = {
        id = "2GITK5Q-6R76XLR-TT6QK2F-LN3LMUS-OTMZDZW-3PJQ55A-547ASZJ-WCLADAS";
      };
      folders.work = {
        id = "work";
        label = "Work";
        path = workDir;
        devices = [ "dobby" ];
      };
    };
  };

  home.file."work/.stignore".text = ''
    // Node
    node_modules
    .next
    .nuxt
    .turbo
    .parcel-cache

    // Rust
    target

    // Python
    __pycache__
    *.pyc
    .venv
    venv
    .mypy_cache
    .pytest_cache
    .ruff_cache
    .tox
    dist
    build
    *.egg-info

    // iOS / CocoaPods / Xcode
    Pods
    DerivedData
    *.xcuserstate
    xcuserdata

    // JS/TS build output
    .cache
    .vite
    .svelte-kit
    .astro
    out

    // Go
    vendor

    // Java / Gradle / Maven
    .gradle
    .mvn

    // Editor / OS junk
    .DS_Store
    .idea
    .vscode
    *.swp
    *.swo

    // Direnv / Nix
    .direnv
    result
    result-*

    // Devbox
    .devbox

    // Git history (NAS is inter-machine sync, not backup — push to remote for history)
    .git
  '';
}
