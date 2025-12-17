#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$SCRIPT_DIR/.."
cd "$SYSTEM_DIR"

# 1. Build NVIDIA modules
cd $SYSTEM_DIR/open-gpu-kernel-modules
make clean
make modules -j$(nproc) SYSSRC="$SYSTEM_DIR/noble"

# 2. Install NVIDIA modules to staging
make modules_install \
    SYSSRC="$SYSTEM_DIR/noble" \
    INSTALL_MOD_PATH="$SYSTEM_DIR/build/nvidia-modules"

echo "Build complete!"