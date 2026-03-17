{ pkgs, lib, private, ... }:

# Screenpipe: AI screen & audio memory running as a local service.
#
# Network sandbox: all outbound traffic is blocked except localhost.
# Screenpipe physically cannot send data to external services.
# Uses macOS sandbox-exec (deprecated but still functional, no replacement for CLI tools).
#
# Screen Recording permission (macOS):
#   The nix store binary does NOT appear in System Settings UI even when granted.
#   After a nix store path change (version update, nixpkgs update), re-grant manually:
#     1. System Settings > Privacy & Security > Screen & System Audio Recording
#     2. Click "+" under "Screen & System Audio Recording"
#     3. Cmd+Shift+G in the Finder dialog
#     4. Paste: /nix/store/...-screenpipe-<version>/bin  (find path via: readlink $(which screenpipe) or check launchd plist)
#     5. Select the "screenpipe" binary, click Open
#   The binary will NOT show in the list afterward — this is a macOS bug with nix store paths.
#   Verify it's working via: curl http://localhost:3030/health
#
# Logs: ~/Library/Logs/screenpipe.{log,err.log}
# Update: just update-screenpipe

let
  # Pre-fetched models so screenpipe never needs internet access
  models = {
    wespeaker = pkgs.fetchurl {
      url = "https://github.com/screenpipe/screenpipe/raw/refs/heads/main/crates/screenpipe-audio/models/pyannote/wespeaker_en_voxceleb_CAM++.onnx";
      hash = "sha256-xG+tELX4HhqkpgwWJxQghXcJNlUHbFRQ+MRp5SLsVO8=";
    };
    segmentation = pkgs.fetchurl {
      url = "https://github.com/screenpipe/screenpipe/raw/refs/heads/main/crates/screenpipe-audio/models/pyannote/segmentation-3.0.onnx";
      hash = "sha256-t4/EgRO7Rv0keuaprqc3B5VQxkdjjblh334OHp9Lpi4=";
    };
    whisper = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q8_0.bin";
      hash = "sha256-MX62nBFnPJ3h4fDUWbJTmZgE7HGsTCPBfs9fviTiWaE=";
    };
  };

  # Sandbox profile: allow everything except outbound network to non-localhost.
  # Screenpipe only needs to listen on localhost:3030 and access local files.
  screenpipeSandbox = pkgs.writeText "screenpipe.sb" ''
    (version 1)
    (allow default)
    (deny network-outbound)
    (allow network-outbound (remote ip "localhost:*"))
    (allow network-outbound (remote unix-socket))
  '';

  plistPath = "${private.user.homeDirectory}/Library/LaunchAgents/com.screenpipe.daemon.plist";

  uid = "$(id -u)";
  reload = ''
    launchctl bootout gui/${uid}/com.screenpipe.daemon 2>/dev/null || true
    sleep 1
    launchctl bootstrap gui/${uid} "${plistPath}"
  '';

  sed = "${pkgs.lib.getExe pkgs.gnused}";

  # Toggle scripts: patch the launchd plist to add/remove flags, then reload
  sp-mic-on = pkgs.writeShellScriptBin "sp-mic-on" ''
    ${sed} -i 's/ --disable-audio//' "${plistPath}"
    ${sed} -i 's/ --language [a-z]*//' "${plistPath}"
    ${reload}
    echo "screenpipe: audio enabled (auto-detect language)"
  '';
  sp-mic-on-da = pkgs.writeShellScriptBin "sp-mic-on-da" ''
    ${sed} -i 's/ --disable-audio//' "${plistPath}"
    ${sed} -i 's/ --language [a-z]*//' "${plistPath}"
    ${sed} -i 's/--disable-telemetry/--disable-telemetry --language danish/' "${plistPath}"
    ${reload}
    echo "screenpipe: audio enabled (danish)"
  '';
  sp-mic-on-en = pkgs.writeShellScriptBin "sp-mic-on-en" ''
    ${sed} -i 's/ --disable-audio//' "${plistPath}"
    ${sed} -i 's/ --language [a-z]*//' "${plistPath}"
    ${sed} -i 's/--disable-telemetry/--disable-telemetry --language english/' "${plistPath}"
    ${reload}
    echo "screenpipe: audio enabled (english)"
  '';
  sp-mic-on-de = pkgs.writeShellScriptBin "sp-mic-on-de" ''
    ${sed} -i 's/ --disable-audio//' "${plistPath}"
    ${sed} -i 's/ --language [a-z]*//' "${plistPath}"
    ${sed} -i 's/--disable-telemetry/--disable-telemetry --language german/' "${plistPath}"
    ${reload}
    echo "screenpipe: audio enabled (german)"
  '';
  sp-mic-off = pkgs.writeShellScriptBin "sp-mic-off" ''
    if ! grep -q 'disable-audio' "${plistPath}"; then
      ${sed} -i 's/ --language [a-z]*//' "${plistPath}"
      ${sed} -i 's/--disable-telemetry/--disable-telemetry --disable-audio/' "${plistPath}"
    fi
    ${reload}
    echo "screenpipe: audio disabled"
  '';

  python = pkgs.python3.withPackages (ps: [ ps.rumps ]);

  screenpipe-menubar = pkgs.writeShellScriptBin "screenpipe-menubar" ''
    export PATH="${pkgs.lib.makeBinPath [ sp-mic-on sp-mic-on-da sp-mic-on-en sp-mic-on-de sp-mic-off ]}:$PATH"
    exec ${python}/bin/python3 ${./screenpipe-menubar.py}
  '';
in
{
  home.packages = [ sp-mic-on sp-mic-on-da sp-mic-on-en sp-mic-on-de sp-mic-off screenpipe-menubar ];

  # Symlink pre-fetched models into the locations screenpipe expects
  home.activation.screenpipeModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Audio models
    mkdir -p "$HOME/Library/Caches/screenpipe/models"
    ln -sf "${models.wespeaker}" "$HOME/Library/Caches/screenpipe/models/wespeaker_en_voxceleb_CAM++.onnx"
    ln -sf "${models.segmentation}" "$HOME/Library/Caches/screenpipe/models/segmentation-3.0.onnx"

    # Whisper model — place in existing snapshot dir or create one
    WHISPER_BASE="$HOME/.cache/huggingface/hub/models--ggerganov--whisper.cpp"
    SNAP_DIR=$(ls -d "$WHISPER_BASE/snapshots"/*/ 2>/dev/null | head -1)
    if [ -z "$SNAP_DIR" ]; then
      SNAP_DIR="$WHISPER_BASE/snapshots/nix"
      mkdir -p "$SNAP_DIR"
    fi
    ln -sf "${models.whisper}" "$SNAP_DIR/ggml-large-v3-turbo-q8_0.bin"
  '';
  launchd.agents.screenpipe-menubar = {
    enable = false;
    config = {
      Label = "com.screenpipe.menubar";
      ProgramArguments = [ "${screenpipe-menubar}/bin/screenpipe-menubar" ];
      EnvironmentVariables = {
        HOME = private.user.homeDirectory;
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${private.user.homeDirectory}/Library/Logs/screenpipe-menubar.log";
      StandardErrorPath = "${private.user.homeDirectory}/Library/Logs/screenpipe-menubar.err.log";
    };
  };

  launchd.agents.screenpipe = {
    enable = false;
    config = {
      Label = "com.screenpipe.daemon";
      ProgramArguments = [
        "/usr/bin/sandbox-exec"
        "-f"
        (builtins.toString screenpipeSandbox)
        "${pkgs.screenpipe}/bin/screenpipe"
        "--disable-telemetry"
        "--disable-audio"
      ];
      EnvironmentVariables = {
        HOME = private.user.homeDirectory;
        PATH = "${pkgs.ffmpeg}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${private.user.homeDirectory}/Library/Logs/screenpipe.log";
      StandardErrorPath = "${private.user.homeDirectory}/Library/Logs/screenpipe.err.log";
    };
  };
}
