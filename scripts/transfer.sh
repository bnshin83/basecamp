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
    echo "Examples:"
    echo "  ./transfer.sh rcac local outputs/exp1/"
    echo "  ./transfer.sh local rcac checkpoints/best.pt"
    echo "  ./transfer.sh rcac local /scratch/user/results/ --dry-run"
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
        rcac)
            if [[ "$path" == /* ]]; then
                echo "rcac:$path"
            else
                echo "rcac:~/projects/\$(basename \$PWD)/$path"
            fi
            ;;
        local)
            if [[ "$path" == /* ]]; then
                echo "$path"
            else
                echo "./$path"
            fi
            ;;
    esac
}

SOURCE_PATH=$(resolve_path "$SOURCE" "$PATH_ARG")
DEST_PATH=$(resolve_path "$DEST" "$PATH_ARG")

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
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) TRANSFER $SOURCE:$PATH_ARG → $DEST" >> "$BASECAMP_DIR/logs/transfer.log"
fi

echo "═══════════════════════════════════════════════════════════"
