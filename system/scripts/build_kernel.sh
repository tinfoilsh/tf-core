#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$SCRIPT_DIR/.."
cd "$SYSTEM_DIR"

# Load kernel config
source "$SYSTEM_DIR/configs/kernel.conf"

# Create build directory structure
mkdir -p $SYSTEM_DIR/build/packages

# 1. Clone/update kernel at specific commit
echo "Fetching kernel from $KERNEL_REPO at commit $KERNEL_COMMIT..."
if [ ! -d "noble" ]; then
    git init noble
fi
git -C noble fetch --depth 1 "$KERNEL_REPO" "$KERNEL_COMMIT"
git -C noble checkout FETCH_HEAD

# Verify commit matches expected branch
BRANCH_COMMIT=$(git ls-remote "$KERNEL_REPO" "refs/heads/$KERNEL_BRANCH" 2>/dev/null | cut -f1)
if [ "$BRANCH_COMMIT" != "$KERNEL_COMMIT" ]; then
    echo "WARNING: $KERNEL_BRANCH now points to $BRANCH_COMMIT, but using pinned $KERNEL_COMMIT"
fi
echo "✓ Kernel commit: $KERNEL_COMMIT"

# 2. Apply custom config
cp "$SYSTEM_DIR/configs/tinfoil-linux-config" $SYSTEM_DIR/noble/.config

# 3. Build kernel
cd $SYSTEM_DIR/noble
make -j$(nproc) bindeb-pkg
mv $SYSTEM_DIR/*.deb $SYSTEM_DIR/build/packages/

echo "Build complete!"