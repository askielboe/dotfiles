{
  pkgs,
  lib,
  private,
  ...
}:
let
  ccplugins = builtins.fetchGit {
    url = "https://github.com/brennercruvinel/CCPlugins";
    ref = "main";
    rev = "b02d67e33091abff7cef3c98465fc1fa5f96ba46";
  };

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
    model = "claude-opus-4-5-20251101";
    alwaysThinkingEnabled = true;
    permissions = {
      allow = [ "*" ];
      deny = [ ];
    };
    statusLine = {
      type = "command";
      command = "~/.claude/statusline.sh";
      padding = 0;
    };
  };

  home.file.".claude/statusline.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      input=$(cat)
      CURRENT_DIR=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.current_dir')
      echo "''${CURRENT_DIR##*/}"
    '';
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
      voicemode = {
        command = "${pkgs.mcp-voicemode}/bin/voice-mode";
        args = [ ];
        env = {
          OPENAI_API_KEY = private.apiKeys.openai;
        };
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

}
