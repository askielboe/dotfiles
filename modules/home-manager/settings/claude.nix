{
  pkgs,
  private,
  ...
}:
let
  statuslineScript = pkgs.writeShellScript "claude-statusline" ''
    input=$(cat)
    DIR=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.project_dir')
    echo "$DIR"
  '';
  icons = {
    bear = pkgs.fetchurl {
      url = "https://bear.app/images/logo.png";
      sha256 = "sha256-gTh0ZcXCLALMlmQmKeW66eCpQD+AySs2/+fOLyoN+uQ=";
    };
    granola = pkgs.fetchurl {
      url = "https://www.granola.ai/favicon.ico";
      sha256 = "sha256-5TEt+YrhKezY4nZ5//D8dvvJr79yTsWj/tmFHgtXoAc=";
    };
    things = pkgs.fetchurl {
      url = "https://culturedcode.com/favicon.ico";
      sha256 = "sha256-AdJQOdKrwWLAelVP6FaLNdFIW3ncTG57WO9s6+CtTWw=";
    };
  };
in
{
  home.file.".claude/settings.json".text = builtins.toJSON {
    model = "claude-opus-4-6";
    alwaysThinkingEnabled = true;
    permissions = {
      allow = [ "*" ];
      deny = [ ];
    };
    statusLine = {
      type = "command";
      command = "${statuslineScript}";
    };
  };

  home.file."Library/Application Support/Claude/claude_desktop_config.json".text = builtins.toJSON {
    globalShortcut = "Alt+Space";
    mcpServers = {
      bear = {
        command = "${pkgs.mcp-bear}/bin/mcp-bear";
        args = [
          "--token"
          private.apiKeys.bear
        ];
        env = { };
        iconPath = "${icons.bear}";
      };
      granola = {
        command = "${pkgs.mcp-granola}/bin/granola-mcp-server";
        args = [ ];
        env = { };
        iconPath = "${icons.granola}";
      };
      things = {
        command = "${pkgs.mcp-things}/bin/things-mcp";
        args = [ ];
        env = { };
        iconPath = "${icons.things}";
      };
    };
    preferences = {
      menuBarEnabled = true;
      quickEntryShortcut = {
        accelerator = "Alt+Space";
      };
    };
  };
}
