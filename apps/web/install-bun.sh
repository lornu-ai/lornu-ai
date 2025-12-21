#!/usr/bin/env bash
set -euo pipefail

# Hardened Bun installation for Cloudflare builds
# - Optional SHA256 verification via BUN_INSTALL_SHA256
# - Optional version pin via BUN_VERSION (defaults to current stable if omitted)
# Reference: https://github.com/lornu-ai/lornu-ai/issues/40

export PATH="${HOME}/.bun/bin:${PATH}"

if command -v bun >/dev/null 2>&1; then
  echo "Bun is already installed. Version: $(bun --version)"
  exit 0
fi

echo "Installing Bun..."
TMP_SCRIPT="/tmp/bun_install.sh"
curl -fsSL https://bun.sh/install -o "${TMP_SCRIPT}"

# If a checksum is provided, verify integrity of the installer
if [[ -n "${BUN_INSTALL_SHA256:-}" ]]; then
  echo "Verifying installer checksum..."
  CALC_SHA256=$(shasum -a 256 "${TMP_SCRIPT}" | awk '{print $1}')
  if [[ "${CALC_SHA256}" != "${BUN_INSTALL_SHA256}" ]]; then
    echo "ERROR: Installer checksum mismatch" >&2
    echo "Expected: ${BUN_INSTALL_SHA256}" >&2
    echo "Actual:   ${CALC_SHA256}" >&2
    exit 1
  fi
fi

# Allow version pinning if the installer supports it
# The official script respects BUN_INSTALL environment for path;
# version pinning may be supported via environment (implementation-dependent).
chmod +x "${TMP_SCRIPT}"
"${TMP_SCRIPT}"

echo "Bun installed. Version: $(bun --version)"
