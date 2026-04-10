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

    local savedMousePos = nil

    hs.hotkey.bind({"shift", "alt"}, "f", function()
      local portal = hs.application.get("Portal")
      if portal and portal:isFrontmost() then
        local win = portal:mainWindow()
        if win and win:isFullScreen() then
          win:setFullScreen(false)
        end
        -- Pause Portal
        hs.eventtap.event.newSystemKeyEvent("PLAY", true):post()
        hs.eventtap.event.newSystemKeyEvent("PLAY", false):post()
        portal:hide()
        if savedMousePos then
          hs.mouse.absolutePosition(savedMousePos)
          savedMousePos = nil
        end
        hs.shortcuts.run("Disable Do Not Disturb")
      else
        hs.shortcuts.run("Enable Do Not Disturb")
        -- Hide all windows on all screens
        for _, app in ipairs(hs.application.runningApplications()) do
          if app:kind() == 1 and app:name() ~= "Portal" and app:name() ~= "Finder" then
            app:hide()
          end
        end
        if not portal then
          portal = hs.application.open("Portal")
        end
        if portal then
          portal:activate()
          local win = portal:mainWindow()
          if win and not win:isFullScreen() then
            win:setFullScreen(true)
          end
        end
        -- Play Portal
        hs.eventtap.event.newSystemKeyEvent("PLAY", true):post()
        hs.eventtap.event.newSystemKeyEvent("PLAY", false):post()
        -- Move cursor off-screen to hide it
        savedMousePos = hs.mouse.absolutePosition()
        hs.mouse.absolutePosition({x = -10000, y = -10000})
      end
    end)
  '';
}
