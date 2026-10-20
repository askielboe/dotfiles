# Basic Memory CLI

Built with uv2nix from `pyproject.toml` and `uv.lock`. Python dependencies are
hash-pinned and installed in the Nix store; no runtime uv environment is needed.
Only `bm` and `basic-memory` are exposed, not dependency executables.

To update Basic Memory, change its version in `pyproject.toml` and the package
name in `default.nix`, then run:

```sh
uv lock --directory packages/basic-memory --python 3.12 --upgrade
nix flake check
```

Update the packaging inputs with `nix flake update uv2nix pyproject-nix
pyproject-build-systems`. Apply with the usual `hs` workflow.

Notes, configuration, and indexes remain writable user data. Optional embedding
models may still download on first use; they are not Python dependencies.
