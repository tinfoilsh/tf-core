#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$SCRIPT_DIR/.."
cd "$SYSTEM_DIR"

# Load NVIDIA modules config
source "$SYSTEM_DIR/configs/nvidia.conf"

# 1. Clone/update NVIDIA modules at specific commit
echo "Fetching NVIDIA modules from $NVIDIA_MODULES_REPO at commit $NVIDIA_MODULES_COMMIT..."
if [ ! -d "open-gpu-kernel-modules" ]; then
    git init open-gpu-kernel-modules
fi
git -C open-gpu-kernel-modules fetch --depth 1 "$NVIDIA_MODULES_REPO" "$NVIDIA_MODULES_COMMIT"
git -C open-gpu-kernel-modules checkout FETCH_HEAD

# Verify commit matches expected tag
TAG_COMMIT=$(git ls-remote "$NVIDIA_MODULES_REPO" "refs/tags/$NVIDIA_MODULES_TAG" 2>/dev/null | cut -f1)
if [ "$TAG_COMMIT" != "$NVIDIA_MODULES_COMMIT" ]; then
    echo "WARNING: $NVIDIA_MODULES_TAG now points to $TAG_COMMIT, but using pinned $NVIDIA_MODULES_COMMIT"
fi
echo "✓ NVIDIA modules commit: $NVIDIA_MODULES_COMMIT"

# 2. Build NVIDIA modules
cd $SYSTEM_DIR/open-gpu-kernel-modules
make clean
make modules -j$(nproc) SYSSRC="$SYSTEM_DIR/noble"

# 3. Install NVIDIA modules to staging
make modules_install \
    SYSSRC="$SYSTEM_DIR/noble" \
    INSTALL_MOD_PATH="$SYSTEM_DIR/build/nvidia-modules"

echo "Build complete!"