#!/bin/bash
# Sync repository to cluster

set -e

REPO=$1
CLUSTER=${2:-rcac}
DRY_RUN=${3:-}

BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$REPO" ]; then
    echo "Usage: ./sync.sh <repo_path> [cluster] [--dry-run]"
    echo ""
    echo "Examples:"
    echo "  ./sync.sh ~/projects/myrepo rcac"
    echo "  ./sync.sh . rcac --dry-run"
    exit 1
fi

# Resolve repo path
if [ "$REPO" = "." ]; then
    REPO_PATH=$(pwd)
else
    REPO_PATH=$(cd "$REPO" && pwd)
fi
REPO_NAME=$(basename "$REPO_PATH")

echo "═══════════════════════════════════════════════════════════"
echo "  Sync: $REPO_NAME → $CLUSTER"
echo "═══════════════════════════════════════════════════════════"

# Default excludes
EXCLUDES=(
    ".git"
    "__pycache__"
    "*.pyc"
    "*.pyo"
    ".env"
    "*.pt"
    "*.pth"
    "*.ckpt"
    "wandb"
    "outputs"
    "data"
    ".DS_Store"
    "*.log"
    "node_modules"
    ".venv"
    "venv"
    ".eggs"
    "*.egg-info"
)

# Build exclude args
EXCLUDE_ARGS=""
for ex in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude='$ex'"
done

# Determine destination
case $CLUSTER in
    rcac)
        DEST="rcac:~/projects/$REPO_NAME/"
        ;;
    *)
        echo "Unknown cluster: $CLUSTER"
        exit 1
        ;;
esac

# Check for uncommitted changes
echo ""
echo "Pre-sync checks:"
cd "$REPO_PATH"
if [ -d ".git" ]; then
    CHANGES=$(git status --porcelain | wc -l)
    if [ "$CHANGES" -gt 0 ]; then
        echo "  ⚠️  $CHANGES uncommitted changes"
    else
        echo "  ✅ Git clean"
    fi
    echo "  📍 Branch: $(git branch --show-current)"
fi

# Sync
echo ""
if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "Dry run (no changes):"
    eval "rsync -avzn --progress $EXCLUDE_ARGS '$REPO_PATH/' '$DEST'"
else
    echo "Syncing..."
    eval "rsync -avz --progress $EXCLUDE_ARGS '$REPO_PATH/' '$DEST'"

    echo ""
    echo "✅ Sync complete: $REPO_NAME → $CLUSTER"

    # Update registry
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) SYNC $REPO_NAME → $CLUSTER" >> "$BASECAMP_DIR/logs/sync.log"
fi

echo "═══════════════════════════════════════════════════════════"
