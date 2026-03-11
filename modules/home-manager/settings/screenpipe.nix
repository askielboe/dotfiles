{ pkgs, private, ... }:

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
  # Sandbox profile: allow everything except outbound network to non-localhost.
  # Screenpipe only needs to listen on localhost:3030 and access local files.
  screenpipeSandbox = pkgs.writeText "screenpipe.sb" ''
    (version 1)
    (allow default)
    (deny network-outbound)
    (allow network-outbound (remote ip "127.0.0.1:*"))
    (allow network-outbound (remote ip "[::1]:*"))
    (allow network-outbound (remote unix-socket))
  '';
in
{
  launchd.agents.screenpipe = {
    enable = true;
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
