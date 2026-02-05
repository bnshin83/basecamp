#!/bin/bash
# Check status of all clusters

CLUSTER=${1:-all}
BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "═══════════════════════════════════════════════════════════"
echo "  Basecamp Status - $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"

# RCAC Status
check_rcac() {
    echo ""
    echo "🖥️  RCAC (Purdue)"
    echo "───────────────────────────────────────────────────────────"

    # Check if we can connect
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes rcac "echo connected" &>/dev/null; then
        echo "❌ Cannot connect to RCAC"
        return 1
    fi

    echo "✅ Connected"
    echo ""

    # Running jobs
    echo "Running Jobs:"
    ssh rcac "squeue -u \$USER --format='  %.10i %.20j %.8T %.10M %.4C %.6m %R' 2>/dev/null" | head -10

    # Job summary
    RUNNING=$(ssh rcac "squeue -u \$USER -h --state=running | wc -l" 2>/dev/null)
    PENDING=$(ssh rcac "squeue -u \$USER -h --state=pending | wc -l" 2>/dev/null)
    echo ""
    echo "Summary: $RUNNING running, $PENDING pending"
}

# Local Status
check_local() {
    echo ""
    echo "💻 Local"
    echo "───────────────────────────────────────────────────────────"

    # GPU status
    if command -v nvidia-smi &>/dev/null; then
        echo "GPUs:"
        nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu \
            --format=csv,noheader | while read line; do
            echo "  $line"
        done
    else
        echo "  No GPU detected"
    fi

    echo ""

    # Running Python processes
    echo "Running experiments:"
    PROCS=$(ps aux | grep -E "python.*train|python.*experiment" | grep -v grep | wc -l)
    if [ "$PROCS" -gt 0 ]; then
        ps aux | grep -E "python.*train|python.*experiment" | grep -v grep | awk '{print "  PID " $2 ": " $11 " " $12}'
    else
        echo "  None"
    fi

    echo ""

    # Disk usage
    echo "Disk:"
    df -h ~ | tail -1 | awk '{print "  Home: " $4 " free of " $2}'
}

# Run checks
case $CLUSTER in
    rcac)
        check_rcac
        ;;
    local)
        check_local
        ;;
    all|*)
        check_rcac
        check_local
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════"
