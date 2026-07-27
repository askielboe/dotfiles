{
  pkgs,
  nixpkgs-unstable,
  private,
  ...
}:
let
  # Wrapper that pre-trusts the current directory so Claude never shows the trust dialog
  claude-wrapper = pkgs.writeShellScript "claude-trust-dir" ''
    CLAUDE_JSON="$HOME/.claude/.claude.json"
    DIR="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)"
    if [ -f "$CLAUDE_JSON" ]; then
      tmp=$(mktemp)
      ${pkgs.jq}/bin/jq --arg dir "$DIR" '
        .projects[$dir] = (.projects[$dir] // {}) |
        .projects[$dir].hasTrustDialogAccepted = true |
        .projects[$dir].hasClaudeMdExternalIncludesApproved = true |
        .projects[$dir].hasClaudeMdExternalIncludesWarningShown = true
      ' "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
    fi
  '';
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
      bw = "bwbio";
      o = "open .";
      cfgutil = "/Applications/Apple\ Configurator.app/Contents/MacOS/cfgutil";
      bearcli = "/Applications/Bear.app/Contents/MacOS/bearcli";
      # Start/stop the on-demand local MLX server (launchd.agents.pi-mlx-server).
      mlx-up = "launchctl start org.nix-community.home.pi-mlx-server";
      mlx-down = "launchctl stop org.nix-community.home.pi-mlx-server";
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
        print -r -- "$nvhash" > "$nvroot.hash"
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

    claude() {
      ${claude-wrapper}
      command claude "$@"
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

  # On-demand local MLX inference server so `pim` (see settings/pi.nix) has a
  # model on :11434 without running the extension's /mlx-start in a pi session.
  # Reuses what the extension already built — no second pip install, no re-download:
  #   - venv python: ~/.pi/agent/pi-mlx-models/venv/bin/python3   (built by /mlx-init)
  #   - HF_HOME:     ~/.pi/agent/pi-mlx-models/models             (the 15 GB /mlx-start cached)
  # This is the exact invocation the extension itself spawns. While it's running,
  # do NOT also use /mlx-start — it would fight for :11434.
  #
  # On-demand: RunAtLoad/KeepAlive are off, so nothing loads at login — the model
  # is ~16 GB resident only while the server runs. Start/stop with the mlx-up /
  # mlx-down aliases below; first request after mlx-up waits ~30-60s for the model
  # to load. For an always-on server instead, set RunAtLoad = true and KeepAlive
  # = true (keeps ~16 GB of your 32 GB committed from login).
  launchd.agents.pi-mlx-server = {
    enable = true;
    config = {
      ProgramArguments = [
        "${private.user.homeDirectory}/.pi/agent/pi-mlx-models/venv/bin/python3"
        "-m"
        "mlx_lm.server"
        "--model"
        "mlx-community/Qwen3.6-27B-4bit" # keep in sync with settings/pi.nix
        "--host"
        "127.0.0.1"
        "--port"
        "11434"
      ];
      RunAtLoad = false; # on-demand: don't load 16 GB at login
      KeepAlive = false; # so `launchctl stop` (mlx-down) actually frees the RAM
      StandardOutPath = "${private.user.homeDirectory}/Library/Logs/pi-mlx-server.out.log";
      StandardErrorPath = "${private.user.homeDirectory}/Library/Logs/pi-mlx-server.err.log";
      EnvironmentVariables = {
        HOME = private.user.homeDirectory;
        # Point at the cache the extension already populated, else it re-downloads ~16 GB.
        HF_HOME = "${private.user.homeDirectory}/.pi/agent/pi-mlx-models/models";
        TRANSFORMERS_CACHE = "${private.user.homeDirectory}/.pi/agent/pi-mlx-models/models";
        HF_HUB_DISABLE_TELEMETRY = "1";
        PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
