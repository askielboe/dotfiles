{ pkgs, ... }:
{
  home.file.".claude/settings.json".text = builtins.toJSON {
    statusLine = {
      type = "command";
      command = ''
        input=$(cat);
        model=$(echo "$input" | jq -r '.model.display_name');
        dir=$(echo "$input" | jq -r '.workspace.current_dir');
        branch=$(cd "$dir" 2>/dev/null && git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no git');
        tokens=$(echo "$input" | jq -r 'if .usage then "\(.usage.input_tokens // 0) / \(.usage.output_tokens // 0)" else "n/a" end');
        echo "$model | $branch | $tokens | $dir"
      '';
    };
    alwaysThinkingEnabled = true;
    mcpServers = {
      serena = {
        command = "${pkgs.nix}/bin/nix";
        args = [
          "run"
          "github:oraios/serena"
          "--"
          "start-mcp-server"
          "--transport"
          "stdio"
        ];
      };
    };
  };
}
