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

    // Terraform / IaC (providers re-fetched by `terraform init`)
    .terraform
    *.tfstate
    *.tfstate.*

    // More build caches / outputs
    .zig-cache
    zig-out
    .build
    .swiftpm
    .dart_tool
    _build
    bower_components
    coverage
    htmlcov
    .nyc_output
    .eslintcache
    .stylelintcache
    *.tsbuildinfo
    .angular
    .vercel
    .netlify
    .expo

    // Backup directories (NAS is sync, not backup)
    backups
    backup
    ai1wm-backups
    updraft
    updraftplus
    updraftplus-export
    wp-snapshots

    // Archives
    *.zip
    *.tar
    *.tar.gz
    *.tgz
    *.gz
    *.bz2
    *.xz
    *.7z
    *.rar
    *.dmg
    *.iso
    *.wpress

    // Database dumps / files (note: *.sql kept on purpose — schema migrations)
    *.bak
    *.dump
    *.sqlite
    *.sqlite3
    *.db
    *.duckdb

    // Media
    *.mp4
    *.mov
    *.mkv
    *.avi
    *.webm
    *.mp3
    *.wav
    *.flac
    *.m4a
    *.aac

    // ML models / large data
    *.gguf
    *.safetensors
    *.ckpt
    *.pt
    *.pth
    *.onnx
    *.h5
    *.pkl
    *.npy
    *.npz
    *.parquet
    *.arrow

    // Compiled binaries
    *.a
    *.o
    *.so
    *.dylib
    *.dll
    *.class
    *.jar

    // Git history (NAS is inter-machine sync, not backup — push to remote for history)
    .git
  '';
}
