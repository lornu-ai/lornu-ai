#!/bin/bash

# Optimization script for Cloudflare builds
# Checks if Bun is already installed/cached before attempting to install
# Reference: https://github.com/lornu-ai/lornu-ai/issues/40

if ! command -v bun &> /dev/null; then
  echo "Bun not found. Installing..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
else
  echo "Bun is already installed. Skipping installation."
  echo "Bun version: $(bun --version)"
fi
