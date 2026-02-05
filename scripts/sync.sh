#!/bin/bash
# Sync repository to cluster

set -e

REPO=$1
CLUSTER=${2:-gilbreth}
DRY_RUN=$3

BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$REPO" ]; then
    echo "Usage: ./sync.sh <repo_name or path> [cluster] [--dry-run]"
    echo ""
    echo "Repos:"
    grep -E "^  [a-z].*:" "$BASECAMP_DIR/repos/repos.yaml" | sed 's/://g' | while read repo; do
        echo "  • $repo"
    done
    echo ""
    echo "Clusters: gilbreth, gautschi"
    echo ""
    echo "Examples:"
    echo "  ./sync.sh upgd-research gilbreth"
    echo "  ./sync.sh memorization-survey gautschi"
    echo "  ./sync.sh /path/to/repo gilbreth --dry-run"
    exit 1
fi

# Resolve repo path from registry or use direct path
if [ -f "$BASECAMP_DIR/repos/repos.yaml" ] && grep -q "^  $REPO:" "$BASECAMP_DIR/repos/repos.yaml"; then
    # Get local path from registry
    REPO_PATH=$(grep -A1 "^  $REPO:" "$BASECAMP_DIR/repos/repos.yaml" | grep "local_path" | sed 's/.*local_path: *"//;s/".*//')
    REPO_NAME=$REPO

    # Get remote path
    REMOTE_PATH=$(grep -A10 "^  $REPO:" "$BASECAMP_DIR/repos/repos.yaml" | grep "$CLUSTER:" | head -1 | sed 's/.*: *"//;s/".*//')
else
    # Direct path
    if [ -d "$REPO" ]; then
        REPO_PATH=$(cd "$REPO" && pwd)
    else
        echo "Error: Repo '$REPO' not found in registry or as path"
        exit 1
    fi
    REPO_NAME=$(basename "$REPO_PATH")
    REMOTE_PATH="/scratch/$CLUSTER/shin283/$REPO_NAME"
fi

echo "═══════════════════════════════════════════════════════════"
echo "  Sync: $REPO_NAME → $CLUSTER"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Local:  $REPO_PATH"
echo "Remote: $REMOTE_PATH"

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

DEST="$CLUSTER:$REMOTE_PATH/"

# Pre-sync checks
echo ""
echo "Pre-sync checks:"
cd "$REPO_PATH"
if [ -d ".git" ]; then
    CHANGES=$(git status --porcelain 2>/dev/null | wc -l)
    if [ "$CHANGES" -gt 0 ]; then
        echo "  ⚠️  $CHANGES uncommitted changes"
    else
        echo "  ✅ Git clean"
    fi
    echo "  📍 Branch: $(git branch --show-current 2>/dev/null || echo 'N/A')"
fi

# Ensure remote directory exists
echo ""
echo "Ensuring remote directory exists..."
ssh $CLUSTER "mkdir -p $REMOTE_PATH"

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

    # Update registry timestamp
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "$TIMESTAMP SYNC $REPO_NAME → $CLUSTER:$REMOTE_PATH" >> "$BASECAMP_DIR/logs/sync.log"
fi

echo "═══════════════════════════════════════════════════════════"
