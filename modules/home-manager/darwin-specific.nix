{
  pkgs,
  nixpkgs-unstable,
  private,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home = {
    inherit (private.user) homeDirectory;

    file = {
      ".config/ghostty/config" = {
        source = ./dotfiles/ghostty/config;
        # Ghostty reloads config on SIGUSR2 (>= 1.2). pgrep/pkill -f can't see
        # the argv of the LaunchServices-spawned process, so resolve the PID via
        # ps. No-op when Ghostty isn't running. Window-chrome settings (e.g.
        # titlebar style) still only apply to new windows.
        onChange = ''
          for pid in $(/bin/ps ax -o pid=,comm= | /usr/bin/awk '$2 == "/Applications/Ghostty.app/Contents/MacOS/ghostty" {print $1}'); do
            /bin/kill -USR2 "$pid" || true
          done
        '';
      };
      ".aerospace.toml" = {
        source = ./dotfiles/aerospace/aerospace.toml;
        # Adopt the pre-existing hand-managed file: overwrite it with the
        # symlink on first switch instead of failing with "file in the way".
        force = true;
        # AeroSpace only re-reads its config on demand; no-op if it isn't running.
        onChange = "/opt/homebrew/bin/aerospace reload-config || true";
      };
      # Back/forward through AeroSpace workspace *visit* history (nvim <C-o>/<C-i>
      # style) — AeroSpace has no native command for this. aerospace.toml drives
      # it: exec-on-workspace-change records visits, alt-shift-o = back,
      # alt-shift-i = forward. Referenced from the toml by this absolute path.
      ".config/aerospace/workspace-history.sh" = {
        source = ./dotfiles/aerospace/workspace-history.sh;
        executable = true;
      };
      # Google Chat unread poller (neutral, UI-less library). home-manager links
      # it to ~/.local/lib/gchat/gchat.py; the SwiftBar item below imports it from
      # there. gchat-login (modules/darwin/settings/gchat.nix) writes the
      # per-account OAuth state it reads under ~/.local/state/gchat/.
      ".local/lib/gchat/gchat.py".source = ./dotfiles/gchat/gchat.py;
      # Google Chat unread indicator for the NATIVE macOS menu bar. The plugin
      # imports the neutral poller above (~/.local/lib/gchat/gchat.py) as a
      # library — zero API/OAuth duplication. The ".1m." in the filename is
      # SwiftBar's refresh cadence (1 min). SwiftBar itself is app-owned: point
      # its Plugin Folder at ~/.config/swiftbar/plugins once (SwiftBar prefs, or
      # `defaults write com.ambar.SwiftBar PluginDirectory ~/.config/swiftbar/plugins`).
      ".config/swiftbar/plugins/gchat.1m.py" = {
        source = ./dotfiles/swiftbar/gchat.1m.py;
        executable = true;
      };
    };

    shellAliases = {
      o = "open .";
      cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";
      bearcli = "/Applications/Bear.app/Contents/MacOS/bearcli";
      # openpomodoro-cli. zsh expands these as prefixes, so
      # `poms "Write the report"` → `pomodoro start "Write ..."`.
      pom = "pomodoro"; # base, for status/history/amend/repeat/clear
      poms = "pomodoro start"; # start a Pomodoro (pass the task description)
      pomf = "pomodoro finish"; # finish early, count it toward the daily goal
      pomc = "pomodoro cancel"; # cancel/abandon the current Pomodoro
      pomb = "pomodoro break"; # take a break (blocks: live countdown in the shell)
    };

    packages = with pkgs; [
      nh # nix-helper: drives `hs` — nvd package diff, elevation only for activation
      unstable.colima # lima dependency is EOL in stable
      ripsecrets # Find secrets
      gitleaks # Secret scanner — backs the .githooks/pre-commit hook
      transmission_4
      yt-dlp
    ];
  };

  programs.ssh.settings = {
    "github.com".IdentityFile = "~/.ssh/id_ed25519-github";
    "flextribe".IdentityFile = "~/.ssh/id_ed25519-github";
    "storagebox-restic".IdentityFile = "~/.ssh/id_ed25519-storagebox";
    "garage-hetzner".IdentityFile = "~/.ssh/id_ed25519-hetzner-garage";
  };

  programs.zsh.initContent = ''
    hs() {
      # Pre-step: (re)build the standalone nixvim child flake (nvim/) so the
      # main eval consumes a prebuilt store path (settings/nvim.nix) instead of
      # re-running nixvim's ~11s module eval. The content-hash guard makes the
      # no-op case cost milliseconds and self-heals a GC'd root ([ -e ] follows
      # the symlink, so a dangling out-link triggers a rebuild). MUST build the
      # path: ref (not ./nvim) so only nvim/ contents key the child's eval
      # cache, and MUST stay pure (no --impure) so that cache can hit at all.
      local nvroot="$HOME/.config/nix/.gc-roots/nvim-aarch64-darwin"
      local nvhash
      nvhash=$(nix hash path "$HOME/.config/nix/nvim") || return
      if [ ! -e "$nvroot" ] || [ "$(cat "$nvroot.hash" 2>/dev/null)" != "$nvhash" ]; then
        mkdir -p "$HOME/.config/nix/.gc-roots"
        nix build "path:$HOME/.config/nix/nvim" --out-link "$nvroot" || return
        # `>|` not `>`: this runs under the user's interactive zsh, which has
        # noclobber set — a plain `>` onto the existing hash file fails, leaving
        # it stale so the line-106 guard never matches and every hs rebuilds.
        print -r -- "$nvhash" >| "$nvroot.hash"
      fi
      # nh (nix-helper) builds as your user, prints an nvd package diff, and only
      # elevates (sudo) for the activation step. Pure eval: settings.nix and the
      # sops-encrypted secrets.yaml are tracked in-tree (allowUnfree is set at
      # every in-flake nixpkgs import, so no NIXPKGS_ALLOW_UNFREE needed). Keep
      # the bare-path flake ref (git auto-detect): a path: ref would copy
      # gitignored files — including the age key — into the world-readable store.
      # Extra args pass through: `hs -u` also updates flake inputs, `hs --dry`
      # previews without activating, `hs -a` asks before activating.
      nh darwin switch ~/.config/nix -H ${private.user.username} "$@"
    }
  '';

  # Bear MCP bridge: expose the local `bearcli mcp-server` (stdio) as Streamable
  # HTTP on 127.0.0.1:9099 so the k3s gateway can proxy to it remotely (Tailscale
  # egress → https://mcp.skielboe.com/bear/mcp). bearcli only runs on macOS, so
  # this must live on this machine. Works only while the Mac is awake/logged in.
  #
  # Tailnet exposure is declarative: the nix-darwin module
  # modules/darwin/settings/tailscale.nix enables tailscaled and asserts
  #   tailscale serve --bg --tcp 9099 tcp://127.0.0.1:9099
  # which makes this device reachable at <device>:9099 on the tailnet — the
  # endpoint the cluster's Tailscale egress targets. Only `sudo tailscale up`
  # (login) is manual, and only once.
  launchd.agents.bear-mcp-bridge = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.uv}/bin/uvx" # uv ships uvx; fetches+caches mcp-proxy from PyPI on first run
        # mcp-proxy 0.12.0 (latest) requires `mcp>=1.17.0` with no upper bound, but
        # SDK 2.0.0 dropped `mcp.server.lowlevel.server.request_ctx`, which
        # proxy_server.py imports at module load. Unpinned, uvx resolves 2.x and the
        # agent crash-loops on ImportError (silently: the gateway then reports Bear as
        # "no tools available" rather than broken). Drop the pin once mcp-proxy > 0.12.0
        # supports SDK 2.x.
        "--with"
        "mcp<2"
        "mcp-proxy"
        "--host"
        "127.0.0.1"
        "--port"
        "9099"
        "--"
        "/Applications/Bear.app/Contents/MacOS/bearcli"
        "mcp-server"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${private.user.homeDirectory}/Library/Logs/bear-mcp-bridge.out.log";
      StandardErrorPath = "${private.user.homeDirectory}/Library/Logs/bear-mcp-bridge.err.log";
      EnvironmentVariables = {
        HOME = private.user.homeDirectory; # uv cache lives under $HOME
        PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
