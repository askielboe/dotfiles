{
  config,
  pkgs,
  basic-memory-skills,
  ...
}:

let
  hax = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "hax";
    version = "0.6.1";

    src = pkgs.fetchurl {
      url = "https://github.com/OleksandrChekhovskyi/hax/releases/download/v${finalAttrs.version}/hax-${finalAttrs.version}.tar.xz";
      hash = "sha256-tGwTGHdw36tXfO47CnfQx9YigMcVw7g5YCyoihrjeho=";
    };

    nativeBuildInputs = with pkgs; [
      meson
      ninja
      pkg-config
    ];
    buildInputs = with pkgs; [
      curl
      jansson
    ];
    doCheck = true;
    # Terminal integration tests need tmux; Darwin's sandbox does not preserve setuid bits.
    postPatch = ''
      substituteInPlace tests/meson.build \
        --replace-fail "'repl_complete'," "" \
        --replace-fail "'repl_interrupt'," "" \
        --replace-fail "'repl_smoke'," ""
    ''
    + pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
      substituteInPlace tests/meson.build --replace-fail "'tools/test_write.c'," ""
    '';

    meta = {
      description = "Lightweight terminal coding agent";
      homepage = "https://usehax.dev/";
      license = pkgs.lib.licenses.mit;
      mainProgram = "hax";
      platforms = pkgs.lib.platforms.unix;
    };
  });
in
{
  home.packages = [ hax ];
  home.shellAliases.h = "hax";

  xdg.configFile =
    pkgs.lib.mapAttrs'
      (
        name: _:
        pkgs.lib.nameValuePair "hax/skills/${name}" {
          source = "${basic-memory-skills}/skills/${name}";
        }
      )
      (
        pkgs.lib.filterAttrs (
          name: type:
          type == "directory" && builtins.pathExists "${basic-memory-skills}/skills/${name}/SKILL.md"
        ) (builtins.readDir "${basic-memory-skills}/skills")
      )
    // {
      "hax/skills/prepare-management-slides".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/ChatGPT/IT Support/skills/prepare-management-slides";

      "hax/AGENTS.md".text = ''
        # GitHub consent

        Never create GitHub pull requests (including draft PRs) or issues without the
        user's explicit approval and consent for that specific action. Do not infer
        consent from a request to implement, fix, review, or investigate something.

        # Email sender

        Always draft and send Andreas's email from `askielboe@hccreators.com` using
        `gws-hccreators`, even when related documents or correspondence are in mo2tion.
        Sending still requires explicit approval of the exact draft.

        # Basic Memory

        Use the Basic Memory skills through the `bm` CLI, not unavailable MCP tools.
        Inspect `bm tool --help` and `bm tool <command> --help` for supported arguments.
        MCP tool names map to hyphenated CLI commands: `search_notes` → `bm tool search-notes`,
        `read_note` → `bm tool read-note`, `write_note` → `bm tool write-note`,
        `edit_note` → `bm tool edit-note`, `build_context` → `bm tool build-context`,
        and `recent_activity` → `bm tool recent-activity`.
        Discover projects with `bm project list --json`; use an explicit `--project` for note operations.
        CLI retrieval output defaults to JSON when piped. Follow the skills' approval requirements.

        # Browser (Stagehand)

        Use the Stagehand-backed `browse` CLI for browser tasks. Read the browse skill and
        run `browse skills show` before first use; inspect `browse <command> --help` for flags.
        Default to headless browsers; use headed mode only when the user explicitly requests it.
        Start with `browse open <url> --local --headless -s <task>` and use that named session
        on subsequent commands. Local mode needs Chrome but no API key. Use a separate
        session for each concurrent task; do not attach to personal Chrome without permission.
        Inspect snapshots before acting, refresh after page changes, and verify outcomes.
        Never blindly retry a submission after a timeout. Ask before purchases or destructive
        actions; existing email draft-review requirements still apply in the browser.
        Close task sessions with `browse stop -s <task>` when finished.
        Cloud browsing, fetch, and search require `BROWSERBASE_API_KEY`; do not silently
        switch to cloud mode. Keep credentials and authenticated browser state out of logs.
        Nix manages the CLI and skills: change `~/.config/nix` and let the user apply with `hs`,
        rather than running npm-global installs, `browse skills install`, or self-updates.
      '';

      "hax/skills/google-workspace/SKILL.md".text = ''
        ---
        name: google-workspace
        description: Google Workspace tasks for mo2tion and hccreators through the authenticated gws CLI, including Chat, Gmail, Drive, and Calendar.
        ---

        # Workspace access

        Google Workspace access uses account-specific commands:

        | Account | Command |
        | --- | --- |
        | andreas@mo2tion.com | `gws-mo2tion` |
        | askielboe@hccreators.com | `gws-hccreators` |

        The account follows the user's request or verified resource ownership. Ambiguous account selection requires clarification.
        Requests spanning both accounts use separate commands.
        The named wrappers select credentials; bare `gws` and the active `gcloud` account are not substitutes.

        ## Discovery and reads

        Method help comes from `<account-cli> <service> <resource> --help`.
        Method schemas come from `<account-cli> schema <service.resource.method>`.
        Commands use `--params` for path and query parameters, and `--json` for request bodies.
        Responses are JSON. Read calls use bounded page sizes and field selection where supported.
        Subsequent pages use the response's `nextPageToken` as the next request's `pageToken`.
        Resource names come from API responses, not guessed identifiers.

        ```sh
        gws-mo2tion chat spaces list --params '{"pageSize":10}'
        gws-hccreators chat spaces list --params '{"pageSize":10}'
        gws-mo2tion schema chat.spaces.messages.list
        gws-hccreators gmail users getProfile --params '{"userId":"me"}'
        ```

        Authorized services include Chat, Gmail, Drive, Calendar, Docs, Sheets, and Slides.
        Mutations remain limited to the user's requested scope. Authentication alone does not authorize external actions.

        ## Email sender and approval

        Always draft and send Andreas's email from `askielboe@hccreators.com` using `gws-hccreators`.
        This sender preference is independent of which account owns a related document or contains source correspondence.
        Do not use `andreas@mo2tion.com` as the sender merely because the task involves mo2tion resources.

        Sending, replying, forwarding, and scheduling email require review of the exact draft before explicit approval to send.
        The review includes To, CC, BCC, subject, complete body, attachments, and any scheduled delivery time.
        Changes to those details require renewed approval.
        General permission, silence, and requests to continue do not replace approval of the reviewed draft.
        This requirement applies across commands, tools, APIs, and delegated work.

        ## Authentication

        Each wrapper uses a separate directory under `~/.config/gws/`, named `mo2tion` or `hccreators`.
        Credentials are encrypted; their encryption key resides in the operating system's keyring.
        Refresh tokens renew access tokens automatically. Routine service calls do not require another login.
        Internal OAuth apps avoid the seven-day refresh-token expiry associated with External Testing apps.
        Revocation and Workspace security policies can still require reauthorization.

        ```sh
        gws-mo2tion auth status
        gws-hccreators auth status
        ```

        Authentication failures are reported for the affected account. Another account is not a fallback.
        Credential exports, tokens, and client secrets remain outside model output, repository files, and logs.
        Reauthorization and credential changes require an explicit setup request.
        Nix owns persistent configuration at `~/.config/nix`; the user applies changes with `hs`.
      '';
    };
}
