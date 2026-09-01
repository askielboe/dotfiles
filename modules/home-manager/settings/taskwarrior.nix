{ config, ... }:
{
  # Taskwarrior 3 config, managed declaratively. Home Manager writes these keys to
  # a Nix-store fragment (~/.config/task/home-manager-taskrc) and prepends an
  # `include` for it to the real, still-writable ~/.config/task/taskrc — so `task
  # config` keeps working and secrets can stay OUT of the (world-readable) store.
  #
  # Sync server: taskchampion-sync-server at task.skielboe.com (see k3s repo,
  # sk-taskchampion/). Task data is end-to-end encrypted; the server only stores
  # ciphertext. The client_id + encryption_secret live in 1Password and are set
  # imperatively (they must not land in the Nix store or git):
  #   task config sync.server.client_id  "$(op read 'op://Private/TaskChampion Sync/client-id')"
  #   task config sync.encryption_secret "$(op read 'op://Private/TaskChampion Sync/encryption-secret')"
  #   task sync
  programs.taskwarrior = {
    enable = true;
    package = null; # taskwarrior3 itself is installed via settings/packages.nix

    # Keep the database where it already lives (~/.task), NOT the module's XDG
    # default (~/.local/share/task) — otherwise Taskwarrior opens an empty DB.
    dataLocation = "${config.home.homeDirectory}/.task";

    # Non-secret keys only — this fragment is world-readable in /nix/store.
    config = {
      news.version = "3.4.1";
      sync.server.url = "https://task.skielboe.com";

      # taskwarrior-tui: press "f" on a task to add a follow-up that depends on it
      uda."taskwarrior-tui".shortcuts."2" = "~/.config/taskwarrior-tui/shortcut-scripts/follow-up.sh";
      uda."taskwarrior-tui".keyconfig.shortcut2 = "f";
    };
  };

}
