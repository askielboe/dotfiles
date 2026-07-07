{ pkgs, ... }:
{
  # ActivityWatch editor watcher. Sends heartbeats (edited file + language) to
  # aw-server on 127.0.0.1:5600, creating an aw-watcher-vim_<host> bucket. It
  # auto-starts on VimEnter and needs only curl (present on macOS); commands
  # :AWStart / :AWStop / :AWStatus control it. No config needed for the defaults.
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.aw-watcher-vim ];
}
