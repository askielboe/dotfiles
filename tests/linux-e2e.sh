#!/usr/bin/env bash
#
# End-to-end test of the standalone home-manager (Linux) config against a real
# Ubuntu userland: install Nix, build the activation package, activate it, and
# smoke-test the resulting shell/editor. This is what catches breakage that the
# day-to-day macOS workflow never exercises.
#
# It is meant for a THROWAWAY environment (an Ubuntu container via `just
# test-linux`, or a CI runner) — NOT your real machine: it rewrites the tracked
# secrets/settings.nix username in its staged copy and, when run as root,
# creates a throwaway build user.
#
# Routing is by uid:
#   * root      -> provision apt deps + a throwaway user, then re-exec as them.
#   * non-root  -> stage the repo under ~/.config/nix, install Nix if needed,
#                  build + activate + smoke-test AS the current user.
# So a container (`docker run ... ubuntu:24.04`, root) and a CI runner
# (`bash tests/linux-e2e.sh`, non-root) share one build path.
#
# Env:
#   E2E_USER  throwaway user to create when run as root (default: nixtest)

set -euo pipefail

E2E_USER="${E2E_USER:-nixtest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
# Root: provision the box and a throwaway user, then hand off to that user.
# ---------------------------------------------------------------------------
if [[ "$(id -u)" -eq 0 ]]; then
  log "Installing prerequisites (apt)"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq curl ca-certificates sudo xz-utils git locales >/dev/null

  log "Creating throwaway build user: $E2E_USER"
  id -u "$E2E_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$E2E_USER"
  # Passwordless sudo: the Nix installer and the activation's chsh step need it.
  printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$E2E_USER" >"/etc/sudoers.d/90-$E2E_USER"
  chmod 0440 "/etc/sudoers.d/90-$E2E_USER"

  DEST="/home/$E2E_USER/.config/nix"
  log "Staging the repo at $DEST"
  rm -rf "$DEST"
  mkdir -p "/home/$E2E_USER/.config"
  cp -a "$REPO_ROOT" "$DEST"
  rm -f "$DEST/result"
  chown -R "$E2E_USER:$E2E_USER" "/home/$E2E_USER/.config"

  log "Handing off to the build user ($E2E_USER)"
  exec sudo -iu "$E2E_USER" bash "$DEST/tests/linux-e2e.sh"
fi

# ---------------------------------------------------------------------------
# Build user: stage repo, fixture secrets, install Nix, build, activate, smoke.
# ---------------------------------------------------------------------------
ME="$(id -un)"
DEST="$HOME/.config/nix"

if [[ "$REPO_ROOT" != "$DEST" ]]; then
  log "Staging the repo at $DEST"
  rm -rf "$DEST"
  mkdir -p "$(dirname "$DEST")"
  cp -a "$REPO_ROOT" "$DEST"
  rm -f "$DEST/result"
fi
cd "$DEST"

log "Pointing secrets/settings.nix at the container user (username=$ME)"
# Line the fixture up with the runtime user so the flake output name
# (${user}-${arch}), the Linux home dir (/home/${user}) and the OS user all match.
# settings.nix is TRACKED, so the dirty edit is still part of the pure flake
# source. The container has no age key: eval stays green (sops validates file
# structure only) and the sops units simply skip, which is what the smoke wants.
sed -i -E "s/username = \"[^\"]*\"/username = \"$ME\"/" secrets/settings.nix

if ! command -v nix >/dev/null 2>&1; then
  log "Installing Nix (Determinate nix-installer; --init none for a container)"
  curl -fsSL https://install.determinate.systems/nix |
    sudo sh -s -- install linux --init none --no-confirm
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true

# No init system in a container, so start the daemon by hand and wait for it.
if ! nix store ping >/dev/null 2>&1; then
  log "Starting nix-daemon"
  sudo bash -c 'nohup /nix/var/nix/profiles/default/bin/nix-daemon >/var/log/nix-daemon.log 2>&1 &'
  for _ in $(seq 1 30); do
    nix store ping >/dev/null 2>&1 && break
    sleep 1
  done
fi
nix store ping >/dev/null 2>&1 || {
  echo "nix daemon not reachable" >&2
  exit 1
}

log "Building + activating the Linux home-manager config"
./build-and-switch-linux.sh "$ME"

# ---------------------------------------------------------------------------
# Smoke test: the activated environment must give a working shell + editor.
# ---------------------------------------------------------------------------
log "Smoke-testing the activated environment"
export PATH="$HOME/.nix-profile/bin:$PATH"
fail=0

for bin in zsh nvim tmux rg fd git; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "  ok: $bin -> $(command -v "$bin")"
  else
    echo "  MISSING: $bin"
    fail=1
  fi
done

echo "  checking: zsh loads its config"
if zsh -ic 'exit 0' </dev/null >/dev/null 2>&1; then
  echo "  ok: zsh -ic"
else
  echo "  FAIL: zsh -ic"
  fail=1
fi

echo "  checking: nvim (nixvim) loads headlessly"
if timeout 180 nvim --headless '+qa' </dev/null >/dev/null 2>&1; then
  echo "  ok: nvim --headless +qa"
else
  echo "  FAIL: nvim --headless"
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  log "E2E FAILED"
  exit 1
fi
log "E2E PASSED"
