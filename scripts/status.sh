#!/bin/bash
# Unified status: clusters + projects

WHAT=${1:-all}
BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

print_header() {
    echo "═══════════════════════════════════════════════════════════"
    echo "  Basecamp Status - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "═══════════════════════════════════════════════════════════"
}

# Check cluster connection and jobs
check_cluster() {
    local CLUSTER=$1

    echo ""
    echo "🖥️  $CLUSTER"
    echo "───────────────────────────────────────────────────────────"

    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $CLUSTER "echo ok" &>/dev/null; then
        echo "  ❌ Cannot connect"
        return 1
    fi

    echo "  ✅ Connected"

    # Jobs summary
    RUNNING=$(ssh $CLUSTER "squeue -u shin283 -h --state=running 2>/dev/null | wc -l" | tr -d ' ')
    PENDING=$(ssh $CLUSTER "squeue -u shin283 -h --state=pending 2>/dev/null | wc -l" | tr -d ' ')
    echo "  Jobs: $RUNNING running, $PENDING pending"

    # Show running jobs if any
    if [ "$RUNNING" -gt 0 ]; then
        echo ""
        ssh $CLUSTER "squeue -u shin283 --state=running --format='    %8i %-20j %10M %R' 2>/dev/null | tail -n +2" | head -5
    fi
}

# Check local
check_local() {
    echo ""
    echo "💻 Local"
    echo "───────────────────────────────────────────────────────────"

    # Running experiments
    PROCS=$(ps aux | grep -E "python.*train|python.*experiment" | grep -v grep | wc -l | tr -d ' ')
    echo "  Running experiments: $PROCS"

    # Disk
    DISK=$(df -h ~ 2>/dev/null | tail -1 | awk '{print $4 " free"}')
    echo "  Disk: $DISK"
}

# Show all projects with locations
show_projects() {
    echo ""
    echo "📁 Projects"
    echo "───────────────────────────────────────────────────────────"
    echo ""
    printf "  %-22s %-10s %-6s %-6s %-6s %s\n" "PROJECT" "STATUS" "LOCAL" "GILB" "GAUT" "NOTES"
    printf "  %-22s %-10s %-6s %-6s %-6s %s\n" "───────" "──────" "─────" "────" "────" "─────"

    # Parse YAML
    local current=""
    local status=""
    local has_local=""
    local has_gilbreth=""
    local has_gautschi=""
    local active_cluster=""
    local active=""

    while IFS= read -r line; do
        # New project
        if [[ "$line" =~ ^[[:space:]]{2}([a-z0-9_-]+):$ ]]; then
            # Print previous project
            if [ -n "$current" ]; then
                print_project_row
            fi
            current="${BASH_REMATCH[1]}"
            status=""
            has_local=""
            has_gilbreth=""
            has_gautschi=""
            active_cluster=""
            active=""
        elif [[ "$line" =~ status:[[:space:]]*\"([^\"]+)\" ]]; then
            status="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ active:[[:space:]]*(true|false) ]]; then
            active="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ local:[[:space:]]*\"[^\"]+\" ]]; then
            has_local="yes"
        elif [[ "$line" =~ gilbreth:[[:space:]]*\"[^\"]+\" ]]; then
            has_gilbreth="yes"
        elif [[ "$line" =~ gautschi:[[:space:]]*\"[^\"]+\" ]]; then
            has_gautschi="yes"
        elif [[ "$line" =~ active_cluster:[[:space:]]*(gilbreth|gautschi) ]]; then
            active_cluster="${BASH_REMATCH[1]}"
        fi
    done < "$BASECAMP_DIR/projects/projects.yaml"

    # Print last project
    if [ -n "$current" ]; then
        print_project_row
    fi

    echo ""
    echo "  Legend: ✓=exists ★=active —=none"
}

print_project_row() {
    local local_mark="—"
    local gilbreth_mark="—"
    local gautschi_mark="—"
    local notes=""

    [ "$has_local" = "yes" ] && local_mark="✓"
    [ "$has_gilbreth" = "yes" ] && gilbreth_mark="✓"
    [ "$has_gautschi" = "yes" ] && gautschi_mark="✓"

    # Mark active cluster with star
    [ "$active_cluster" = "gilbreth" ] && gilbreth_mark="★"
    [ "$active_cluster" = "gautschi" ] && gautschi_mark="★"

    # Add active indicator
    if [ "$active" = "true" ]; then
        notes="◀ ACTIVE"
    fi

    printf "  %-22s %-10s %-6s %-6s %-6s %s\n" "$current" "$status" "$local_mark" "$gilbreth_mark" "$gautschi_mark" "$notes"
}

# Main
print_header

case $WHAT in
    gilbreth)
        check_cluster gilbreth
        ;;
    gautschi)
        check_cluster gautschi
        ;;
    clusters)
        check_cluster gilbreth
        check_cluster gautschi
        ;;
    local)
        check_local
        ;;
    projects)
        show_projects
        ;;
    all|*)
        check_cluster gilbreth
        check_cluster gautschi
        check_local
        show_projects
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════"
