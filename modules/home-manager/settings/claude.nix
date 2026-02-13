{
  pkgs,
  private,
  ...
}:
let
  icons = {
    bear = pkgs.fetchurl {
      url = "https://bear.app/images/logo.png";
      sha256 = "sha256-gTh0ZcXCLALMlmQmKeW66eCpQD+AySs2/+fOLyoN+uQ=";
    };
    granola = pkgs.fetchurl {
      url = "https://www.granola.ai/favicon.ico";
      sha256 = "sha256-5TEt+YrhKezY4nZ5//D8dvvJr79yTsWj/tmFHgtXoAc=";
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
    };
    preferences = {
      menuBarEnabled = true;
      quickEntryShortcut = {
        accelerator = "Alt+Space";
      };
    };
  };
}
