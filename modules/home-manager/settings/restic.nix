{ pkgs, ... }:
{
  services.restic = {
    enable = true;

    backups.work = {
      repository = "sftp:askielboe@192.168.1.10:/home/restic";
      passwordFile = "/Users/askielboe/.restic/work";
      paths = [ "/Users/askielboe/work" ];
      exclude = [ "node_modules" ];
    };
  };
}
