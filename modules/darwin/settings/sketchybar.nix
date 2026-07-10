{ pkgs, ... }:
let
  # One-time interactive login that mints a user:profile-scoped OAuth token for
  # the claude_usage item and writes it to ~/.local/state/claude-usage/oauth.json.
  # That token rotates on refresh, so it lives outside the read-only nix store
  # (the plugin refreshes it in place); nothing sensitive is committed. Run
  # `claude-usage-login` once after a switch. writeShellApplication runs
  # shellcheck on the body and injects the runtime deps onto its PATH.
  claude-usage-login = pkgs.writeShellApplication {
    name = "claude-usage-login";
    runtimeInputs = [
      pkgs.openssl
      pkgs.curl
      pkgs.jq
      pkgs.coreutils
    ];
    text = builtins.readFile ./claude-usage-login.sh;
  };

  # One-time interactive OAuth login for the `gchat` sketchybar item (Google Chat
  # unread indicator). Run `gchat-login <label>` once per account; it runs
  # Google's loopback OAuth flow and writes a refresh token to
  # ~/.local/state/gchat/<label>.json, which plugins/gchat.py refreshes in place
  # (rotating, so kept out of the read-only nix store). Stdlib-only Python, so
  # the wrapper just puts python3 on PATH and execs the script from the store.
  #
  # GOOGLE CLOUD SETUP (once, both accounts are Workspace so this is the easy
  # path — Internal consent, non-expiring refresh tokens):
  #   1. console.cloud.google.com -> create/pick a project.
  #   2. APIs & Services -> Library -> enable "Google Chat API".
  #   3. APIs & Services -> OAuth consent screen -> User type "Internal".
  #   4. Add scopes: chat.spaces.readonly, chat.messages.readonly,
  #      chat.users.readstate.readonly (all read-only), plus openid + email
  #      (non-sensitive; lets gchat-login record which account each token is, so
  #      its bar chip can deep-link to that account via ?authuser=<email>).
  #   5. Credentials -> Create credentials -> OAuth client ID -> "Desktop app".
  #      Note the client ID and secret.
  #   6. After `hs`, run once per account (paste the id/secret when prompted, or
  #      export GCHAT_CLIENT_ID / GCHAT_CLIENT_SECRET first):
  #         gchat-login work-a
  #         gchat-login work-b
  gchat-login = pkgs.writeShellApplication {
    name = "gchat-login";
    runtimeInputs = [ pkgs.python3 ];
    text = ''exec python3 ${./gchat-login.py} "$@"'';
  };

  # Launch wrapper for the system-stats provider agent below. Resolves the live
  # enN interface list at startup instead of hardcoding names that macOS
  # re-enumerates (see the script for the full rationale). writeShellApplication
  # runs shellcheck on the body; the script uses only absolute system paths, so
  # it needs nothing on PATH.
  stats-provider-launch = pkgs.writeShellApplication {
    name = "stats-provider-launch";
    text = builtins.readFile ./stats-provider-launch.sh;
  };
in
{
  # https://felixkratz.github.io/SketchyBar/
  # Status bar replacing the macOS menu bar, showing AeroSpace workspaces.
  # Runs as a launchd user agent managed by nix-darwin. With `config` left
  # unset, the agent reads the standard ~/.config/sketchybar/sketchybarrc,
  # which home-manager symlinks from modules/home-manager/dotfiles/sketchybar.
  # AeroSpace pushes workspace changes to the bar via exec-on-workspace-change
  # in aerospace.toml.
  services.sketchybar = {
    enable = true;
    # All must be on the agent's PATH, which plugin scripts inherit:
    #   sketchybar-app-font — icon_map.sh (app name -> glyph) for the front_app plugin
    #   openpomodoro-cli    — `pomodoro status` for the pomodoro center plugin
    #   jq / curl           — claude-usage.sh (OAuth token refresh + /api/oauth/usage)
    #   python3             — gchat.py (Google Chat unread poller, stdlib only)
    extraPackages = [
      pkgs.sketchybar-app-font
      pkgs.openpomodoro-cli
      pkgs.jq
      pkgs.curl
      pkgs.python3
    ];
  };

  # One-time OAuth login CLIs (see the let bindings): `claude-usage-login` mints
  # the claude_usage token; `gchat-login <label>` mints a Google Chat token per
  # account for the gchat item.
  environment.systemPackages = [
    claude-usage-login
    gchat-login
  ];

  # System-stats provider (brew: joncrangle/tap/sketchybar-system-stats). It
  # pushes the `system_stats` event to the bar every 5s over mach messages,
  # feeding the cpu/disk/network items (see stats.sh). Run as its own launchd
  # agent — NOT backgrounded from sketchybarrc — so it isn't a child of
  # sketchybar's KeepAlive process group, which launchd reaps at login and
  # would silently kill the stats. KeepAlive restarts it if it ever dies;
  # ordering vs. sketchybar is irrelevant since it re-pushes every 5s.
  #
  # Launched via stats-provider-launch (above), which resolves the current enN
  # interfaces at startup rather than naming them here: the provider aborts if a
  # named interface is missing, and macOS re-enumerates dock/USB Ethernet to a
  # new enN over time (the old en17 disappeared and silently killed the stats).
  launchd.user.agents.sketchybar-stats-provider = {
    serviceConfig = {
      ProgramArguments = [ "${stats-provider-launch}/bin/stats-provider-launch" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
    };
  };

  # The font those glyphs render in.
  fonts.packages = [ pkgs.sketchybar-app-font ];

  # Auto-hide the macOS menu bar so sketchybar owns the top edge. Hovering at
  # the top still reveals it (Stats, MeetingBar etc. stay reachable).
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;
}
