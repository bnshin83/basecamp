#!/bin/bash
# Check status of all clusters

CLUSTER=${1:-all}
BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "═══════════════════════════════════════════════════════════"
echo "  Basecamp Status - $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════"

# Gilbreth Status
check_gilbreth() {
    echo ""
    echo "🖥️  Gilbreth (Purdue)"
    echo "───────────────────────────────────────────────────────────"

    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes gilbreth "echo connected" &>/dev/null; then
        echo "❌ Cannot connect to Gilbreth"
        return 1
    fi

    echo "✅ Connected"
    echo ""
    echo "Running Jobs:"
    ssh gilbreth "squeue -u shin283 --format='  %.10i %.20j %.8T %.10M %.4C %.6m %R' 2>/dev/null" | head -10

    RUNNING=$(ssh gilbreth "squeue -u shin283 -h --state=running 2>/dev/null | wc -l")
    PENDING=$(ssh gilbreth "squeue -u shin283 -h --state=pending 2>/dev/null | wc -l")
    echo ""
    echo "Summary: $RUNNING running, $PENDING pending"

    echo ""
    echo "Scratch usage:"
    ssh gilbreth "du -sh /scratch/gilbreth/shin283/* 2>/dev/null | head -5" || echo "  Unable to check"
}

# Gautschi Status
check_gautschi() {
    echo ""
    echo "🖥️  Gautschi (Purdue)"
    echo "───────────────────────────────────────────────────────────"

    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes gautschi "echo connected" &>/dev/null; then
        echo "❌ Cannot connect to Gautschi"
        return 1
    fi

    echo "✅ Connected"
    echo ""
    echo "Running Jobs:"
    ssh gautschi "squeue -u shin283 --format='  %.10i %.20j %.8T %.10M %.4C %.6m %R' 2>/dev/null" | head -10

    RUNNING=$(ssh gautschi "squeue -u shin283 -h --state=running 2>/dev/null | wc -l")
    PENDING=$(ssh gautschi "squeue -u shin283 -h --state=pending 2>/dev/null | wc -l")
    echo ""
    echo "Summary: $RUNNING running, $PENDING pending"

    echo ""
    echo "Scratch usage:"
    ssh gautschi "du -sh /scratch/gautschi/shin283/* 2>/dev/null | head -5" || echo "  Unable to check"
}

# Local Status
check_local() {
    echo ""
    echo "💻 Local (Mac)"
    echo "───────────────────────────────────────────────────────────"

    # GPU status
    if command -v nvidia-smi &>/dev/null; then
        echo "GPUs:"
        nvidia-smi --query-gpu=index,name,memory.used,memory.total,utilization.gpu \
            --format=csv,noheader 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        echo "  No NVIDIA GPU (Mac)"
    fi

    echo ""
    echo "Running experiments:"
    PROCS=$(ps aux | grep -E "python.*train|python.*experiment" | grep -v grep | wc -l)
    if [ "$PROCS" -gt 0 ]; then
        ps aux | grep -E "python.*train|python.*experiment" | grep -v grep | awk '{print "  PID " $2 ": " $11 " " $12}' | head -5
    else
        echo "  None"
    fi

    echo ""
    echo "Disk:"
    df -h ~ 2>/dev/null | tail -1 | awk '{print "  Home: " $4 " free of " $2}'
}

# Show tracked repos
show_repos() {
    echo ""
    echo "📁 Tracked Repos"
    echo "───────────────────────────────────────────────────────────"
    if [ -f "$BASECAMP_DIR/repos/repos.yaml" ]; then
        grep -E "^  [a-z].*:" "$BASECAMP_DIR/repos/repos.yaml" | sed 's/://g' | while read repo; do
            echo "  • $repo"
        done
    fi
}

# Run checks
case $CLUSTER in
    gilbreth)
        check_gilbreth
        ;;
    gautschi)
        check_gautschi
        ;;
    local)
        check_local
        ;;
    repos)
        show_repos
        ;;
    all|*)
        check_gilbreth
        check_gautschi
        check_local
        show_repos
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════"
