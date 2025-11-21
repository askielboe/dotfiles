{ config, pkgs, ... }:

let
  masAppIds = builtins.attrValues config.homebrew.masApps;
  masAppIdString = builtins.concatStringsSep " " (map builtins.toString masAppIds);
in
{
  homebrew.masApps = {
    "1Blocker" = 1365531024;
    "1Password for Safari" = 1569813296;
    Bear = 1091189122;
    DaisyDisk = 411643860;
    Keynote = 409183694;
    LookAway = 6747192301;
    Magnet = 441258766;
    Messenger = 1480068668;
    "Microsoft Excel" = 462058435;
    "Microsoft OneNote" = 784801555;
    "Microsoft Word" = 462054704;
    TestFlight = 899247664;
    "Things 3" = 904280696;
    Xcode = 497799835;
  };

  home-manager.users.askielboe.home.packages = with pkgs; [
    mas
  ];

  launchd.user.agents.thingsmacsandboxhelper = {
    command = "/Applications/ThingsMacSandboxHelper.app/Contents/MacOS/ThingsMacSandboxHelper";
    serviceConfig = {
      RunAtLoad = true;
      StandardOutPath = "/tmp/thingsmacsandboxhelper.log";
      StandardErrorPath = "/tmp/thingsmacsandboxhelper.log";
    };
  };

  system.activationScripts.masCleanup = {
    text = ''
      echo "Checking for unmanaged Mac App Store apps..."

      MANAGED_IDS="${masAppIdString}"

      INSTALLED=$(mas list 2>/dev/null | awk '{print $1}')

      for id in $INSTALLED; do
        if ! echo "$MANAGED_IDS" | grep -q "$id"; then
          APP_NAME=$(mas list 2>/dev/null | grep "^$id" | awk '{$1=""; print $0}' | xargs)
          echo "Uninstalling unmanaged app: $APP_NAME ($id)"
          mas uninstall "$id" 2>/dev/null || true
        fi
      done
    '';
  };
}
