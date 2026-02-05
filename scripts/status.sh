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
    echo "🖥️  $CLUSTER (${CLUSTER}.rcac.purdue.edu)"
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

    # Show running jobs
    if [ "$RUNNING" -gt 0 ]; then
        echo ""
        ssh $CLUSTER "squeue -u shin283 --state=running --format='    %8i %20j %10M %4C %6m %R' 2>/dev/null" | head -6
    fi

    # Projects on this cluster
    echo ""
    echo "  Projects:"
    PROJECTS=$(ssh $CLUSTER "ls -d /scratch/$CLUSTER/shin283/*/ 2>/dev/null | xargs -n1 basename" 2>/dev/null)
    if [ -z "$PROJECTS" ]; then
        echo "    (none)"
    else
        echo "$PROJECTS" | while read p; do
            SIZE=$(ssh $CLUSTER "du -sh /scratch/$CLUSTER/shin283/$p 2>/dev/null | cut -f1")
            printf "    %-20s %s\n" "$p" "$SIZE"
        done
    fi
}

# Check local
check_local() {
    echo ""
    echo "💻 Local (Mac)"
    echo "───────────────────────────────────────────────────────────"

    # Running experiments
    PROCS=$(ps aux | grep -E "python.*train|python.*experiment" | grep -v grep | wc -l | tr -d ' ')
    echo "  Running experiments: $PROCS"

    # Disk
    DISK=$(df -h ~ 2>/dev/null | tail -1 | awk '{print $4 " free of " $2}')
    echo "  Disk: $DISK"
}

# Show all projects with locations
show_projects() {
    echo ""
    echo "📁 Projects Overview"
    echo "───────────────────────────────────────────────────────────"
    echo ""
    printf "  %-18s %-6s %-8s %-8s %-8s\n" "PROJECT" "ACTIVE" "LOCAL" "GILBRETH" "GAUTSCHI"
    printf "  %-18s %-6s %-8s %-8s %-8s\n" "───────" "──────" "─────" "────────" "────────"

    # Simple YAML parsing
    local current=""
    local active=""
    local has_local=""
    local has_gilbreth=""
    local has_gautschi=""
    local active_cluster=""

    while IFS= read -r line; do
        # New project
        if [[ "$line" =~ ^[[:space:]]{2}([a-z0-9_-]+):$ ]]; then
            # Print previous project
            if [ -n "$current" ]; then
                local_mark="—"
                gilbreth_mark="—"
                gautschi_mark="—"
                [ "$has_local" = "yes" ] && local_mark="✓"
                [ "$has_gilbreth" = "yes" ] && gilbreth_mark="✓"
                [ "$has_gautschi" = "yes" ] && gautschi_mark="✓"
                [ "$active_cluster" = "gilbreth" ] && gilbreth_mark="★"
                [ "$active_cluster" = "gautschi" ] && gautschi_mark="★"
                active_mark="  "
                [ "$active" = "true" ] && active_mark="✓"
                printf "  %-18s %-6s %-8s %-8s %-8s\n" "$current" "$active_mark" "$local_mark" "$gilbreth_mark" "$gautschi_mark"
            fi
            current="${BASH_REMATCH[1]}"
            active=""
            has_local=""
            has_gilbreth=""
            has_gautschi=""
            active_cluster=""
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
        local_mark="—"
        gilbreth_mark="—"
        gautschi_mark="—"
        [ "$has_local" = "yes" ] && local_mark="✓"
        [ "$has_gilbreth" = "yes" ] && gilbreth_mark="✓"
        [ "$has_gautschi" = "yes" ] && gautschi_mark="✓"
        [ "$active_cluster" = "gilbreth" ] && gilbreth_mark="★"
        [ "$active_cluster" = "gautschi" ] && gautschi_mark="★"
        active_mark="  "
        [ "$active" = "true" ] && active_mark="✓"
        printf "  %-18s %-6s %-8s %-8s %-8s\n" "$current" "$active_mark" "$local_mark" "$gilbreth_mark" "$gautschi_mark"
    fi

    echo ""
    echo "  Legend: ✓ = exists, ★ = active cluster, — = not deployed"
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
