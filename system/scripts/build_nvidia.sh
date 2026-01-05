#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$SCRIPT_DIR/.."
cd "$SYSTEM_DIR"

# Load NVIDIA modules config
source "$SYSTEM_DIR/configs/nvidia.conf"

# 1. Clone NVIDIA modules if not present
if [ ! -d "open-gpu-kernel-modules" ]; then
    echo "Cloning NVIDIA modules from $NVIDIA_MODULES_REPO ($NVIDIA_MODULES_TAG)..."
    git clone --depth 1 --branch "$NVIDIA_MODULES_TAG" "$NVIDIA_MODULES_REPO" open-gpu-kernel-modules
fi

# 2. Build NVIDIA modules
cd $SYSTEM_DIR/open-gpu-kernel-modules
make clean
make modules -j$(nproc) SYSSRC="$SYSTEM_DIR/noble"

# 3. Install NVIDIA modules to staging
make modules_install \
    SYSSRC="$SYSTEM_DIR/noble" \
    INSTALL_MOD_PATH="$SYSTEM_DIR/build/nvidia-modules"

echo "Build complete!"