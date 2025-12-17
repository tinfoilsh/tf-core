#!/bin/bash
#
# Generate platform measurements JSON file.
#
# This script iterates over all platform configs and computes their ACPI hashes,
# producing a JSON file with measurements for each config.
#
# Usage: ./measure.sh [output-file]
#        Default output: ../measurements/platform-measurements.json
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/../configs"
COMPUTE_ACPI_HASH="$SCRIPT_DIR/compute-acpi-hash.sh"

# Default output location
DEFAULT_OUTPUT_DIR="$SCRIPT_DIR/../out"
DEFAULT_OUTPUT_FILE="$DEFAULT_OUTPUT_DIR/platform-measurements.json"

OUTPUT_FILE="${1:-$DEFAULT_OUTPUT_FILE}"
OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"

# Verify compute-acpi-hash.sh exists
if [ ! -x "$COMPUTE_ACPI_HASH" ]; then
    echo "Error: compute-acpi-hash.sh not found or not executable: $COMPUTE_ACPI_HASH"
    exit 1
fi

# Verify configs directory exists
if [ ! -d "$CONFIGS_DIR" ]; then
    echo "Error: Configs directory not found: $CONFIGS_DIR"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Computing platform measurements..."

# Collect all measurements first
declare -A MEASUREMENTS
CONFIG_NAMES=()

for config_dir in "$CONFIGS_DIR"/*/; do
    # Skip if not a directory
    [ -d "$config_dir" ] || continue
    
    config_name=$(basename "$config_dir")
    metadata_json="$config_dir/metadata.json"
    
    # Skip if no metadata.json
    if [ ! -f "$metadata_json" ]; then
        echo "  Warning: Skipping $config_name (no metadata.json)" >&2
        continue
    fi
    
    # Compute ACPI hash
    acpi_hash=$("$COMPUTE_ACPI_HASH" "$metadata_json")
    
    MEASUREMENTS["$config_name"]="$acpi_hash"
    CONFIG_NAMES+=("$config_name")
    
    echo "  Computed: $config_name -> $acpi_hash"
done

# Sort config names for consistent output
IFS=$'\n' SORTED_NAMES=($(sort <<<"${CONFIG_NAMES[*]}")); unset IFS

# Generate JSON output
{
    echo "{"
    FIRST=true
    for config_name in "${SORTED_NAMES[@]}"; do
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo ","
        fi
        printf '  "%s": {\n    "acpi": "%s"\n  }' "$config_name" "${MEASUREMENTS[$config_name]}"
    done
    echo ""
    echo "}"
} > "$OUTPUT_FILE"

echo ""
echo "Measurements written to: $OUTPUT_FILE"
