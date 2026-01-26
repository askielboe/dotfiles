{ config, ... }:
{
  homebrew.casks = [ "hammerspoon" ];

  launchd.user.agents.hammerspoon = {
    serviceConfig = {
      Label = "org.hammerspoon.Hammerspoon";
      ProgramArguments = [ "/Applications/Hammerspoon.app/Contents/MacOS/Hammerspoon" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  system.defaults.CustomUserPreferences = {
    "org.hammerspoon.Hammerspoon" = {
      MJConfigFile = "${config.users.users.askielboe.home}/.config/hammerspoon/init.lua";
    };
  };

  home-manager.users.askielboe.xdg.configFile."hammerspoon/init.lua".text = ''
    hs.hotkey.bind({"shift", "alt"}, "4", function()
      hs.shortcuts.run("Screenshot to Things")
    end)
  '';
}
