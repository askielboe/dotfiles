{ pkgs, lib, ... }:
let
  ccplugins = builtins.fetchGit {
    url = "https://github.com/brennercruvinel/CCPlugins";
    ref = "main";
    rev = "b02d67e33091abff7cef3c98465fc1fa5f96ba46";
  };

  serenaConfig = {
    gui_log_window = false;
    web_dashboard = true;
    web_dashboard_open_on_launch = false;
    log_level = 20;
    trace_lsp_communication = false;
    ls_specific_settings = { };
    tool_timeout = 240;
    excluded_tools = [ ];
    included_optional_tools = [ ];
    default_max_tool_answer_chars = 150000;
    token_count_estimator = "CHAR_COUNT";
    language_backend = "LSP";
    projects = [
      "/Users/askielboe/.config/nix"
      "/Users/askielboe/work/bear-related"
      "/Users/askielboe/work/budget"
      "/Users/askielboe/work/k3s"
      "/Users/askielboe/work/motosumo/commons"
      "/Users/askielboe/work/ms/mrs-warehouse"
    ];
  };

  yamlFormat = pkgs.formats.yaml { };
in
{
  home.file.".claude/settings.json".text = builtins.toJSON {
    model = "claude-opus-4-5-20251101";
    statusLine = {
      type = "command";
      command = ''
        input=$(cat);
        model=$(echo "$input" | jq -r '.model.display_name');
        usage=$(echo "$input" | jq '.context_window.current_usage');
        if [ "$usage" != "null" ]; then
          tokens=$(echo "$usage" | jq -r '(.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)');
        else
          tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0');
        fi
        max_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // 200000');
        tokens_k=$((tokens / 1000));
        max_k=$((max_tokens / 1000));
        pct=$((tokens * 100 / max_tokens));
        dir=$(echo "$input" | jq -r '.workspace.current_dir');
        branch=$(cd "$dir" 2>/dev/null && git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no git');
        echo "$model | ''${tokens_k}k/''${max_k}k ($pct%) | $branch | $dir"
      '';
    };
    alwaysThinkingEnabled = true;
    permissions = {
      allow = [ "*" ];
      deny = [ ];
    };
  };

  home.file.".claude/commands".source = "${ccplugins}/commands";

  home.file.".claude/agents/docs-writer.md".text = ''
    ---
    name: docs-writer
    description: Documentation expert. PROACTIVELY use this agent to write, update, and improve documentation after implementing features.
    tools: Read, Edit, Glob, Grep, Write
    model: sonnet
    ---

    You are an expert technical documentation writer.

    When invoked:
    1. Review the code changes or new features
    2. Check existing documentation structure
    3. Write clear, well-organized documentation
    4. Include practical code examples
    5. Ensure consistency with existing docs style

    Guidelines:
    - Be concise but complete
    - Use markdown formatting appropriately
    - Add code examples where helpful
    - Update README and related docs as needed
    - Keep docs in sync with code behavior
  '';

  home.file.".claude/agents/git-committer.md".text = ''
    ---
    name: git-committer
    description: Git commit specialist. PROACTIVELY use this agent to create well-structured commits with semantic messages.
    tools: Bash, Read, Glob, Grep
    model: haiku
    ---

    You are an expert at creating clear, semantic git commits.

    When invoked:
    1. Run `git status` to see all changes
    2. Run `git diff` to understand staged and unstaged changes
    3. Run `git log --oneline -5` to see recent commit style
    4. Create a semantic commit message

    Commit message format:
    - type(scope): brief description
    - Blank line
    - Detailed explanation if needed

    Types: feat, fix, docs, style, refactor, test, chore

    Rules:
    - Focus on the "why" not just "what"
    - Keep first line under 72 characters
    - Reference issues if applicable
    - End commit with the standard footer:
      🤖 Generated with [Claude Code](https://claude.com/claude-code)

      Co-Authored-By: Claude <noreply@anthropic.com>
  '';

  home.file."Library/Application Support/Claude/claude_desktop_config.json".text = builtins.toJSON {
    globalShortcut = "Alt+Space";
    mcpServers = {
      bear = {
        command = "/etc/profiles/per-user/askielboe/bin/node";
        args = [ "/Users/askielboe/repos/bear-notes-mcp/dist/index.js" ];
        env = { };
      };
      trainerroad = {
        command = "${pkgs.uv}/bin/uv";
        args = [
          "--directory"
          "/Users/askielboe/work/trainerroad-transcribe/trainerroad-mcp-server"
          "run"
          "python"
          "-m"
          "src.server"
        ];
        env = {
          ANTHROPIC_API_KEY = "***REMOVED-SECRET***";
          NEO4J_URI = "bolt://localhost:7687";
          NEO4J_USER = "neo4j";
          NEO4J_PASSWORD = "password";
          QDRANT_URL = "http://localhost:6333";
        };
      };
    };
    preferences = {
      menuBarEnabled = true;
      quickEntryShortcut = {
        accelerator = "Alt+Space";
      };
    };
  };

  home.file.".serena/serena_config.yml".source = yamlFormat.generate "serena_config.yml" serenaConfig;
}
