{
  config,
  lib,
  pkgs,
  ...
}:
let
  workDir = "${config.home.homeDirectory}/work";

  # Every entry below is regenerable, re-fetchable, or explicitly "not backup"
  # (see "NAS is sync, not backup"). None of it is precious, so all of it is
  # marked deletable: each pattern is prefixed at build time with Syncthing's
  # `(?d)` (see `deletableIgnores`). That lets Syncthing remove these ignored
  # leftovers when their parent directory is deleted on another device, instead
  # of getting stuck with "directory has been deleted on a remote device but
  # contains ignored files".
  rawIgnores = ''
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

    // Serena (LSP symbol caches, regenerated on demand)
    .serena

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

    // Reinstallable / regenerated trees (anchored to folder root).
    // These three dominated the file count (~347k files, 72% of the folder)
    // and are backups or re-pullable, not source — see "NAS is sync, not backup".
    /tm/tm-backup
    /tm/tm-wiki
    /tm/wp-live-pull

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

  # Prefix every real pattern (not blank lines, not `//` comments) with `(?d)`.
  deletableIgnores = lib.concatStringsSep "\n" (
    map (
      line: if line == "" || lib.hasPrefix "//" line then line else "(?d)" + line
    ) (lib.splitString "\n" rawIgnores)
  );

  # Syncthing never syncs `.stignore` itself, but a file it `#include`s syncs
  # like any other content. So the real pattern list is materialized into the
  # folder as the regular file `.stignore-shared`, and each device's local
  # `.stignore` just `#include`s it — edit patterns once here, they reach every
  # device. This MUST be a real file: a `home.file` symlink would sync to the
  # other devices as a broken `/nix/store/...` link (the iPad/iPhone can't run
  # Nix), so the `#include` would error there.
  sharedIgnoreFile = pkgs.writeText "stignore-shared" deletableIgnores;
in
{
  services.syncthing = {
    enable = true;
    settings = {
      devices.dobby = {
        id = "2GITK5Q-6R76XLR-TT6QK2F-LN3LMUS-OTMZDZW-3PJQ55A-547ASZJ-WCLADAS";
      };
      devices.iPad = {
        id = "B7KB52P-BABHWTI-FG7GJCP-G36WKBZ-4A457YJ-ABHI46G-H3AXPPK-M6O7WA6";
      };
      devices.iPhone = {
        id = "TESBHC6-PRKMVOA-D7U4JKF-EGL7NOE-3IUY33N-LIQDAHI-2KHY2GQ-ABBB7AB";
      };
      folders.work = {
        id = "work";
        label = "Work";
        path = workDir;
        devices = [
          "dobby"
          "iPad"
          "iPhone"
        ];
      };
    };
  };

  # Local bootstrap only — never synced between devices. Just pulls in the
  # shared, synced pattern list. Edit patterns in `rawIgnores` above, not here.
  home.file."work/.stignore".text = ''
    // Bootstrap only — Syncthing never syncs .stignore itself. The real,
    // shared pattern list lives in .stignore-shared (a synced regular file),
    // generated from syncthing.nix. Edit patterns there, not here.
    #include .stignore-shared
  '';

  # Materialize .stignore-shared as a REAL file (not a symlink) so Syncthing
  # syncs it as content to dobby/iPad/iPhone. A brand-new device still needs
  # this one `#include .stignore-shared` line added to its local `.stignore` by
  # hand once (Nix can't reach the phones); after that, every pattern change
  # propagates automatically via the synced file.
  home.activation.syncthingSharedIgnore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/install -Dm0644 ${sharedIgnoreFile} ${workDir}/.stignore-shared
  '';
}
