{ nixpkgs-unstable, pkgs, ... }:

# Pi coding agent (pi.dev / earendil-works/pi) set up to run Qwen3.6-27B locally
# via MLX — the most performant local-inference path on Apple Silicon (MLX has
# the highest sustained throughput of the local runtimes; Ollama 0.19 itself
# switched to an MLX backend on Apple Silicon).
#
# The `pi` CLI is packaged in nixpkgs. It's pulled from unstable (like repomix /
# devenv in packages.nix) because pi moves fast — 25.11 lags a few minor
# versions behind upstream.
#
# Local model serving comes from the `pi-mlx-models` package, which runs an
# OpenAI-compatible mlx-lm server inside its own managed venv. Pi manages that
# venv at runtime, so the bootstrap below can't be nix-pure:
#   pi install npm:pi-mlx-models   # add the local MLX provider to pi
#   pi                             # launch pi, then inside it:
#     /mlx-init                    #   create venv (python -m venv) + pip-install mlx-lm
#     /mlx-start                   #   download + serve PI_MLX_MODELS_DEFAULT_MODEL (below)
#
# /mlx-init needs a Python 3.10–3.13 at a path it probes; the nix python is
# symlinked into /usr/local/bin for it by modules/darwin/settings/pi-mlx-python.nix.
#
# Model selection: pi defaults to provider `google` and doesn't persist the
# /model picker choice, and its --provider flag rejects the extension-registered
# "pi-mlx-models". So a first-class `mlx-local` provider is declared in
# ~/.pi/agent/models.json (below) pointing at the same :11434 server, and the
# `pim` alias launches straight into the 27B — no /model dance.
#
# Quantization choice: 27B at MLX 4-bit (~16 GB) fits entirely in this 32 GB
# M1 Max's GPU memory with room for a large context, so inference stays on the
# GPU and never falls back to CPU/swap. That's why 4-bit and not Q8 (~29 GB,
# which would not fit) — and why no `iogpu.wired_limit_mb` bump is needed. MLX
# 4-bit is the equivalent here of GGUF's Q4_K_M.
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # First-class local provider so the 27B is CLI-selectable and persistent.
  # apiKey "local" is a literal (lowercase => not an env-var ref), so this path
  # doesn't need the $DUMMY workaround the extension's provider does. mlx-lm is a
  # bare OpenAI-compatible server that doesn't understand the `developer` role or
  # `reasoning_effort`, so disable both via compat. pi only reads this file
  # (reloaded on /model), so a read-only home.file symlink is safe here.
  modelsJson = builtins.toJSON {
    providers = {
      "mlx-local" = {
        baseUrl = "http://127.0.0.1:11434/v1";
        api = "openai-completions";
        apiKey = "local";
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };
        models = [
          {
            id = "mlx-community/Qwen3.6-27B-4bit";
            name = "Qwen3.6 27B (local MLX)";
            reasoning = true;
          }
        ];
      };
    };
  };
in
{
  home = {
    packages = [ unstable.pi-coding-agent ];

    # Launch straight into the local 27B, skipping the /model picker.
    shellAliases.pim = "pi --provider mlx-local --model mlx-community/Qwen3.6-27B-4bit";

    # Declarative custom-provider config (see modelsJson above).
    file.".pi/agent/models.json".text = modelsJson;

    sessionVariables = {
      # Model served by `/mlx-start` with no args. Canonical 4-bit MLX build of
      # Qwen3.6-27B. Drop-in alternatives at the same ~16 GB footprint:
      #   mlx-community/Qwen3.6-27B-OptiQ-4bit  - mixed-precision 4-bit, higher quality per bit
      #   mlx-community/Qwen3.6-27B-MTP-4bit    - MTP drafter for speculative decoding (more tok/s)
      PI_MLX_MODELS_DEFAULT_MODEL = "mlx-community/Qwen3.6-27B-4bit";
      # Endpoint defaults to 127.0.0.1:11434; override with
      # PI_MLX_MODELS_HOST / PI_MLX_MODELS_PORT if needed.

      # pi-mlx-models registers its local provider with a hardcoded placeholder
      # apiKey "DUMMY" (a local mlx-lm server ignores auth). Pi 0.79.1 resolves a
      # bare "DUMMY" as a reference to the $DUMMY env var, so it must exist and be
      # non-empty — otherwise pi errors "No API key found for the selected model".
      DUMMY = "local";
    };
  };
}
