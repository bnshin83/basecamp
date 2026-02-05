#!/bin/bash
# Sync project between local and cluster (either direction)

set -e

PROJECT=$1
CLUSTER=${2:-gilbreth}
DIRECTION=${3:---push}  # --push (local→cluster) or --pull (cluster→local)

BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECTS_FILE="$BASECAMP_DIR/projects/projects.yaml"

usage() {
    echo "Usage: ./sync.sh <project> [cluster] [--push|--pull] [--dry-run]"
    echo ""
    echo "Projects:"
    grep -E "^  [a-z0-9_-]+:$" "$PROJECTS_FILE" 2>/dev/null | sed 's/://g; s/^  /  • /'
    echo ""
    echo "Clusters: gilbreth, gautschi"
    echo ""
    echo "Direction:"
    echo "  --push     Local → Cluster (default)"
    echo "  --pull     Cluster → Local"
    echo "  --dry-run  Show what would be synced"
    echo ""
    echo "Examples:"
    echo "  ./sync.sh upgd gilbreth          # Push to gilbreth"
    echo "  ./sync.sh upgd gautschi --pull   # Pull from gautschi"
    echo "  ./sync.sh upgd gilbreth --dry-run"
    exit 1
}

[ -z "$PROJECT" ] && usage

# Parse args
DRY_RUN=""
for arg in "$@"; do
    case $arg in
        --push) DIRECTION="--push" ;;
        --pull) DIRECTION="--pull" ;;
        --dry-run) DRY_RUN="--dry-run" ;;
        gilbreth|gautschi) CLUSTER="$arg" ;;
    esac
done

# Get paths from projects.yaml
get_project_path() {
    local proj=$1
    local loc=$2
    # Extract path for location
    awk "/^  $proj:/,/^  [a-z]/" "$PROJECTS_FILE" | grep "$loc:" | head -1 | sed 's/.*: *"//;s/".*//'
}

LOCAL_PATH=$(get_project_path "$PROJECT" "local")
REMOTE_PATH=$(get_project_path "$PROJECT" "$CLUSTER")

if [ -z "$LOCAL_PATH" ]; then
    echo "Error: Project '$PROJECT' not found or no local path"
    exit 1
fi

if [ -z "$REMOTE_PATH" ]; then
    # Default remote path if not specified
    REMOTE_PATH="/scratch/$CLUSTER/shin283/$PROJECT"
    echo "Note: No remote path in config, using: $REMOTE_PATH"
fi

echo "═══════════════════════════════════════════════════════════"
if [ "$DIRECTION" = "--push" ]; then
    echo "  Sync: $PROJECT (local → $CLUSTER)"
else
    echo "  Sync: $PROJECT ($CLUSTER → local)"
fi
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Local:  $LOCAL_PATH"
echo "Remote: $CLUSTER:$REMOTE_PATH"

# Excludes
EXCLUDES=(
    ".git" "__pycache__" "*.pyc" "*.pyo" ".env"
    "*.pt" "*.pth" "*.ckpt" "wandb" "outputs" "data"
    ".DS_Store" "*.log" "node_modules" ".venv" "venv"
    ".eggs" "*.egg-info" "*.so" "*.o"
)

EXCLUDE_ARGS=""
for ex in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude='$ex'"
done

# Pre-sync check
echo ""
if [ "$DIRECTION" = "--push" ] && [ -d "$LOCAL_PATH/.git" ]; then
    echo "Git status:"
    cd "$LOCAL_PATH"
    CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHANGES" -gt 0 ]; then
        echo "  ⚠️  $CHANGES uncommitted changes"
    else
        echo "  ✅ Clean"
    fi
    BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
    echo "  Branch: $BRANCH"
fi

# Ensure remote directory exists (for push)
if [ "$DIRECTION" = "--push" ]; then
    echo ""
    echo "Ensuring remote directory exists..."
    ssh $CLUSTER "mkdir -p $REMOTE_PATH"
fi

# Sync
echo ""
if [ "$DIRECTION" = "--push" ]; then
    SRC="$LOCAL_PATH/"
    DST="$CLUSTER:$REMOTE_PATH/"
else
    SRC="$CLUSTER:$REMOTE_PATH/"
    DST="$LOCAL_PATH/"
fi

if [ -n "$DRY_RUN" ]; then
    echo "Dry run:"
    eval "rsync -avzn --progress $EXCLUDE_ARGS '$SRC' '$DST'"
else
    echo "Syncing..."
    eval "rsync -avz --progress $EXCLUDE_ARGS '$SRC' '$DST'"

    echo ""
    echo "✅ Sync complete"

    # Log
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    if [ "$DIRECTION" = "--push" ]; then
        echo "$TIMESTAMP SYNC $PROJECT local → $CLUSTER" >> "$BASECAMP_DIR/logs/sync.log"
    else
        echo "$TIMESTAMP SYNC $PROJECT $CLUSTER → local" >> "$BASECAMP_DIR/logs/sync.log"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
