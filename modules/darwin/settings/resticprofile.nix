{ pkgs, lib, ... }:
let
  resticprofile-stable =
    pkgs.runCommand "resticprofile-stable"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta = {
          mainProgram = "resticprofile";
        };
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${pkgs.resticprofile}/bin/resticprofile $out/bin/resticprofile
      '';
in
{
  environment.systemPackages = with pkgs; [
    resticprofile-stable
    (writeShellScriptBin "resticprofile-fda-setup" ''
      echo "For scheduled restic backups, you MUST grant Full Disk Access to BOTH:"
      echo ""
      echo "1. REQUIRED: /bin/bash (LaunchAgent execution)"
      echo "2. REQUIRED: ${resticprofile-stable}/bin/resticprofile (backup tool)"
      echo ""
      echo "Steps:"
      echo "1. Open System Settings → Privacy & Security → Full Disk Access"
      echo "2. Click + button, press Cmd+Shift+G, navigate to /bin, select 'bash'"
      echo "3. Click + button, press Cmd+Shift+G, paste: ${resticprofile-stable}/bin"
      echo "4. Select 'resticprofile' and enable it"
      echo ""
      echo "Both are required - without bash, LaunchAgent can't execute; without"
      echo "resticprofile, the backup tool can't read your home directory files."
    '')
  ];

}
