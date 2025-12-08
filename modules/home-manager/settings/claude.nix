{ pkgs, lib, ... }:
let
  ccplugins = builtins.fetchGit {
    url = "https://github.com/brennercruvinel/CCPlugins";
    ref = "main";
    rev = "b02d67e33091abff7cef3c98465fc1fa5f96ba46";
  };
in
{
  home.file.".claude/settings.json".text = builtins.toJSON {
    model = "claude-sonnet-4-5-20250929";
    statusLine = {
      type = "command";
      command = ''
        input=$(cat);
        model=$(echo "$input" | jq -r '.model.display_name');
        dir=$(echo "$input" | jq -r '.workspace.current_dir');
        branch=$(cd "$dir" 2>/dev/null && git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no git');
        cost=$(echo "$input" | jq -r 'if .cost.total_cost_usd then "$\(.cost.total_cost_usd)" else "$0.00" end');
        echo "$model | $branch | $cost | $dir"
      '';
    };
    alwaysThinkingEnabled = true;
  };

  home.file.".claude/commands".source = "${ccplugins}/commands";

  home.file."Library/Application Support/Claude/claude_desktop_config.json".text = builtins.toJSON {
    globalShortcut = "Alt+Space";
    mcpServers = {
      bear = {
        command = "/etc/profiles/per-user/askielboe/bin/node";
        args = [ "/Users/askielboe/repos/bear-notes-mcp/dist/index.js" ];
        env = { };
      };
      trainerroad-transcripts = {
        command = "${pkgs.uv}/bin/uv";
        args = [ "run" "--directory" "/Users/askielboe/work/trainerroad-transcribe" "mcp_server.py" ];
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
