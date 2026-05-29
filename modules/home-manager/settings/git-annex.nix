{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.git-annex;

  remoteOpts = types.submodule {
    options = {
      type = mkOption {
        type = types.str;
        description = "Type of the remote (e.g. rsync, s3)";
      };
      encryption = mkOption {
        type = types.str;
        default = "none";
        description = "Encryption setting for the remote";
      };
      exporttree = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable export tree mode";
      };
      rsyncurl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "URL for rsync remotes";
      };
    };
  };

  repoOpts = types.submodule {
    options = {
      path = mkOption {
        type = types.str;
        description = "Path to the repository";
      };
      remotes = mkOption {
        type = types.attrsOf remoteOpts;
        default = { };
        description = "Remote configurations for this repository";
      };
    };
  };
in
{
  options.programs.git-annex = {
    enable = mkEnableOption "git-annex";

    rootPath = mkOption {
      type = types.str;
      default = "~/annex";
      description = "Root path for git-annex repositories";
    };

    repositories = mkOption {
      type = types.attrsOf repoOpts;
      default = { };
      description = "Git-annex repository configurations";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.git-annex ];

    home.shellAliases = {
      ga = "git annex";
      gaa = "git annex add";
      gas = "git annex sync";
      gag = "git annex get";
      gap = "git annex copy --to";
    };
  };
}
