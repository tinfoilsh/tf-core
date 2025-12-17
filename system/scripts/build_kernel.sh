#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$SCRIPT_DIR/.."
cd "$SYSTEM_DIR"

# Load kernel config
source "$SYSTEM_DIR/configs/kernel.conf"

# Create build directory structure
mkdir -p $SYSTEM_DIR/build/packages

# 1. Clone kernel if not present
if [ ! -d "noble" ]; then
    echo "Cloning kernel from $KERNEL_REPO ($KERNEL_BRANCH)..."
    git clone --depth 1 --branch "$KERNEL_BRANCH" "$KERNEL_REPO" noble
fi

# 2. Apply custom config
cp "$SYSTEM_DIR/configs/tinfoil-linux-config" $SYSTEM_DIR/noble/.config

# 3. Build kernel
cd $SYSTEM_DIR/noble
make -j$(nproc) bindeb-pkg
mv $SYSTEM_DIR/*.deb $SYSTEM_DIR/build/packages/

echo "Build complete!"