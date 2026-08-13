_: {
  launchd.user.agents = {
    # noTunes (homebrew cask, see settings/homebrew.nix) is a menu-bar-only agent
    # that watches NSWorkspace launch notifications and terminates Music.app the
    # moment anything starts it — a media key, a Bluetooth device reconnecting and
    # sending Play, a music:/itms: link. It only works while it is running, so run
    # it from launchd rather than a hand-added Login Item: RunAtLoad covers login,
    # KeepAlive means Music can't be un-blocked by quitting noTunes (the menu bar
    # icon's enable/disable toggle still works — that's a preference, not a quit).
    #
    # No `replacement` default is set, so a blocked launch opens nothing at all.
    notunes.serviceConfig = {
      ProgramArguments = [ "/Applications/noTunes.app/Contents/MacOS/noTunes" ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
