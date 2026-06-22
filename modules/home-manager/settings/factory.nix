{ pkgs, ... }:
let
  # 1Password reference for the Anthropic API key used with Factory's `droid` CLI.
  # This is a POINTER, not secret material — safe to commit (like a *.tpl file).
  # It is resolved by `op run` into the droid subprocess only (see the wrapper
  # below), so the secret never lands in the Nix store and never sets a global
  # ANTHROPIC_API_KEY (which would otherwise hijack Claude Code's own auth).
  anthropicKeyRef = "op://Private/uthlrb6g3fxdc64cgu4scq4zza/API Keys/factory.ai";

  # `op run --env-file` reads KEY=value lines; an `op://` value is resolved to the
  # secret, anything else is passed through verbatim. Generated into the Nix store
  # (world-readable) — fine, because it holds only the pointer above.
  # The op:// path contains a space ("API Keys"); quote the value so op's dotenv
  # parser takes the whole reference, not just up to the first space.
  factoryEnvFile = pkgs.writeText "factory.op.env" ''
    ANTHROPIC_API_KEY="${anthropicKeyRef}"
  '';

  # Bring-your-own-key config for droid. Lives in settings.local.json (which droid
  # merges on top of its own settings.json) rather than settings.json itself: droid
  # rewrites settings.json at runtime via `/settings`, and a read-only Nix symlink
  # there would break those writes. `apiKey` uses droid's `${VAR}` env expansion;
  # the wrapper injects ANTHROPIC_API_KEY from 1Password. Switch between these with
  # droid's `/model` command. Model IDs/limits per the Anthropic API (June 2026).
  mkModel = model: displayName: {
    inherit model displayName;
    baseUrl = "https://api.anthropic.com/v1";
    apiKey = "\${ANTHROPIC_API_KEY}";
    provider = "anthropic";
    maxOutputTokens = 64000;
  };
  factorySettingsLocal = {
    customModels = [
      (mkModel "claude-opus-4-8" "Claude Opus 4.8 (BYOK)")
      (mkModel "claude-sonnet-4-6" "Claude Sonnet 4.6 (BYOK)")
      (mkModel "claude-haiku-4-5" "Claude Haiku 4.5 (BYOK)")
    ];
  };
in
{
  # Run `droid` through `op run` so the Anthropic key is pulled from 1Password into
  # the droid process at launch — zero paste, desktop-app unlock. Mirrors the
  # `aider` op-run alias in home-manager/default.nix. The binary itself comes from
  # the `droid` Homebrew cask (modules/darwin/settings/homebrew.nix). No recursion:
  # `op run` execs the on-PATH `droid` binary directly, not via the shell alias.
  home.shellAliases.droid = "op run --no-masking --env-file=${factoryEnvFile} -- droid";

  home.file.".factory/settings.local.json".text = builtins.toJSON factorySettingsLocal;
}
