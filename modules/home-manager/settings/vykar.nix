{ config, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.file.".config/vykar/config.yaml".text = ''
    repositories:
      - label: "work-samsung-1tb"
        url: "/Volumes/Samsung-1TB/vykar/work"

    sources:
      - label: "work"
        path: "${home}/work"

    encryption:
      mode: auto
      passcommand: "/opt/homebrew/bin/op read 'op://Private/vykar-work/password'"

    compression:
      algorithm: lz4

    exclude_patterns:
      - ".DS_Store"
      - "*.tmp"
      - "*.log"
      - ".cache/"
      - "__pycache__/"
      - "node_modules/"
      - "target/"
      - ".venv/"
      - ".direnv/"

    exclude_if_present:
      - ".nobackup"
      - "CACHEDIR.TAG"

    git_ignore: false

    retention:
      keep_daily: 7
      keep_weekly: 4
      keep_monthly: 3
  '';
}
