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

  launchd.user.agents = {
    resticprofile-home-storagebox = {
      serviceConfig = {
        ProgramArguments = [
          "${resticprofile-stable}/bin/resticprofile"
          "--config"
          "/Users/askielboe/.config/restic/profiles.yaml"
          "home-storagebox.backup"
        ];
        StartCalendarInterval = {
          Minute = 0; # Every hour at minute 0
        };
        StandardOutPath = "/Users/askielboe/.config/restic/home-storagebox.log";
        StandardErrorPath = "/Users/askielboe/.config/restic/home-storagebox.log";
        ProcessType = "Background";
        TimeOut = 1200;
        EnvironmentVariables = {
          SSH_AUTH_SOCK = "/Users/askielboe/Library/Group Containers/2BUA8C4S2C.com.1passwordb3/t/agent.sock";
        };
      };
    };

    resticprofile-home-gdrive = {
      serviceConfig = {
        ProgramArguments = [
          "${resticprofile-stable}/bin/resticprofile"
          "--config"
          "/Users/askielboe/.config/restic/profiles.yaml"
          "home-motosumo-gdrive.backup"
        ];
        StartCalendarInterval = {
          Minute = 20; # Every hour at minute 20
        };
        StandardOutPath = "/Users/askielboe/.config/restic/home-motosumo-gdrive.log";
        StandardErrorPath = "/Users/askielboe/.config/restic/home-motosumo-gdrive.log";
        ProcessType = "Background";
        TimeOut = 1200;
      };
    };

    resticprofile-home-onedrive = {
      serviceConfig = {
        ProgramArguments = [
          "${resticprofile-stable}/bin/resticprofile"
          "--config"
          "/Users/askielboe/.config/restic/profiles.yaml"
          "home-onedrive.backup"
        ];
        StartCalendarInterval = {
          Minute = 40; # Every hour at minute 40
        };
        StandardOutPath = "/Users/askielboe/.config/restic/home-onedrive.log";
        StandardErrorPath = "/Users/askielboe/.config/restic/home-onedrive.log";
        ProcessType = "Background";
        TimeOut = 1200;
      };
    };
  };
}
