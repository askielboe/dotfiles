{ pkgs }:

pkgs.writeShellScriptBin "voice-mode" ''
  export DYLD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
    pkgs.portaudio
  ]}:$DYLD_LIBRARY_PATH"

  export PATH="${pkgs.ffmpeg}/bin:$PATH"

  exec ${pkgs.uv}/bin/uvx voice-mode "$@"
''
