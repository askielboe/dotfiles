{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    file.".codex/AGENTS.md".text = ''
      ## HARD CONSTRAINT: Email requires prior draft review

      - NEVER send, reply to, forward, or schedule an email until I have reviewed the exact draft and explicitly approved sending it afterward.
      - First show the recipients (including CC/BCC), subject, complete body, and any attachments. Wait for my explicit approval of that draft before sending. If any of these change, obtain approval again.
      - Requests such as "reply to the email thread", "send an email", "continue", or general permission to act authorize preparation only when I have not yet reviewed the exact draft. Silence is never approval.
      - This is mandatory globally, across all projects, tasks, agents, automations, accounts, plugins, connectors, APIs, command-line tools, and browser/native-app actions. Never bypass it by changing the sending method or delegating. Routine confirmations have no exception.

      ## Code hygiene

      - Comments explain why, never what.
      - Do not create documentation unless explicitly requested.
      - Do not duplicate information across code, comments, and documentation.
      - Before adding an abstraction or helper, search for an existing one.
      - Prefer deletion and consolidation over addition.
      - When modifying code, remove code and comments made obsolete by the change.
      - Do not preserve obsolete compatibility paths unless required.

      ## Primary information sources

      - Bear notes and Granola are my primary sources of personal and work context. Proactively search them when a request involves my projects, people, meetings, decisions, plans, preferences, or previous work, even when I do not name either app.
      - Use Bear for written notes and reference material, and Granola for meeting notes, discussions, decisions, and action items. Search both when the topic could span them, before asking me for context or relying on memory alone.
      - Start with focused searches and read the relevant results. Cite the notes or meetings used, including dates when useful; verify time-sensitive claims against current authoritative sources.
      - If a connector is not listed, discover its tools or use an existing configured connection. If access fails, say which source could not be checked; do not treat unavailable access as no results.
      - Skip these searches for self-contained requests that do not need personal context, such as translations, simple rewrites, general facts, or code changes fully specified by the repository and prompt.

      ## Browser use

      - Use Google Chrome through the browser extension for browser tasks. Give parallel tasks separate tabs. Do not use Safari or desktop mouse-and-keyboard control for browsing. If extension-based control is unavailable, ask before switching methods.

      ## Autonomy

      - When a request includes implementation, run in-scope commands and edit in-scope files without asking for confirmation.
    '';

    # The desktop app mutates this file, so keep its state and enforce only these defaults.
    activation.codexFullAccess = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cfg="$HOME/.codex/config.toml"
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$cfg")"
      tmp="$(${pkgs.coreutils}/bin/mktemp "$cfg.XXXXXX")"

      if [ -f "$cfg" ]; then
        input="$cfg"
      else
        input=/dev/null
      fi

      # TOML root values must precede tables or they become part of the last table.
      if ${pkgs.yq-go}/bin/yq -p toml -o toml '
        .approval_policy = "never" |
        .sandbox_mode = "danger-full-access" |
        .notice.hide_full_access_warning = true |
        .apps._default.default_tools_approval_mode = "approve" |
        .apps._default.destructive_enabled = true |
        .apps._default.open_world_enabled = true
        ${lib.optionalString pkgs.stdenv.isDarwin ''
          | .mcp_servers.enzyme.command = "${config.home.profileDirectory}/bin/enzyme"
          | .mcp_servers.enzyme.args = ["mcp"]
        ''}
        | to_entries | sort_by(.value | kind == "map") | from_entries
      ' "$input" > "$tmp"; then
        ${pkgs.coreutils}/bin/chmod 600 "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$cfg"
      else
        ${pkgs.coreutils}/bin/rm -f "$tmp"
        echo "⚠️  Codex config isn't valid TOML; left it untouched." >&2
      fi
    '';
  };
}
