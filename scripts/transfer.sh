#!/bin/bash
# Transfer files between clusters

set -e

SOURCE=$1
DEST=$2
PATH_ARG=$3
DRY_RUN=$4

BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$SOURCE" ] || [ -z "$DEST" ] || [ -z "$PATH_ARG" ]; then
    echo "Usage: ./transfer.sh <source> <dest> <path> [--dry-run]"
    echo ""
    echo "Clusters: gilbreth, gautschi, local"
    echo ""
    echo "Examples:"
    echo "  ./transfer.sh gilbreth local outputs/exp1/"
    echo "  ./transfer.sh gautschi local /scratch/gautschi/shin283/upgd/checkpoints/"
    echo "  ./transfer.sh local gilbreth ./data/processed/"
    echo "  ./transfer.sh gilbreth gautschi /scratch/gilbreth/shin283/model.pt"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo "  Transfer: $SOURCE → $DEST"
echo "═══════════════════════════════════════════════════════════"

# Resolve paths
resolve_path() {
    local cluster=$1
    local path=$2

    case $cluster in
        gilbreth)
            if [[ "$path" == /* ]]; then
                echo "gilbreth:$path"
            else
                echo "gilbreth:/scratch/gilbreth/shin283/$path"
            fi
            ;;
        gautschi)
            if [[ "$path" == /* ]]; then
                echo "gautschi:$path"
            else
                echo "gautschi:/scratch/gautschi/shin283/$path"
            fi
            ;;
        local)
            if [[ "$path" == /* ]]; then
                echo "$path"
            else
                echo "./$path"
            fi
            ;;
        *)
            echo "Unknown cluster: $cluster"
            exit 1
            ;;
    esac
}

SOURCE_PATH=$(resolve_path "$SOURCE" "$PATH_ARG")
DEST_PATH=$(resolve_path "$DEST" "$PATH_ARG")

# For local destination, ensure directory exists
if [ "$DEST" = "local" ]; then
    DEST_DIR=$(dirname "$PATH_ARG")
    mkdir -p "$DEST_DIR" 2>/dev/null || true
fi

echo ""
echo "From: $SOURCE_PATH"
echo "To:   $DEST_PATH"
echo ""

# Transfer
if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "Dry run (no changes):"
    rsync -avzn --progress "$SOURCE_PATH" "$DEST_PATH"
else
    echo "Transferring..."
    rsync -avz --progress "$SOURCE_PATH" "$DEST_PATH"

    echo ""
    echo "✅ Transfer complete"

    # Log
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "$TIMESTAMP TRANSFER $SOURCE:$PATH_ARG → $DEST" >> "$BASECAMP_DIR/logs/transfer.log"
fi

echo "═══════════════════════════════════════════════════════════"
