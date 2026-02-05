#!/bin/bash
# Basecamp hub - unified cluster overview

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║            BASECAMP HUB                ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
echo -e "${CYAN}$(date)${NC}"
echo ""

# Cluster connectivity
echo -e "${GREEN}▶ CLUSTER STATUS${NC}"
for cluster in gilbreth gautschi; do
    if ssh -o ConnectTimeout=3 -o BatchMode=yes "$cluster" 'echo ok' &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $cluster"
    else
        echo -e "  ${RED}✗${NC} $cluster"
    fi
done
echo ""

# Job counts
echo -e "${GREEN}▶ JOBS${NC}"
for cluster in gilbreth gautschi; do
    count=$(ssh -o ConnectTimeout=5 "$cluster" 'squeue -u $USER -h 2>/dev/null | wc -l' 2>/dev/null || echo "?")
    running=$(ssh -o ConnectTimeout=5 "$cluster" 'squeue -u $USER -h -t R 2>/dev/null | wc -l' 2>/dev/null || echo "?")
    pending=$(ssh -o ConnectTimeout=5 "$cluster" 'squeue -u $USER -h -t PD 2>/dev/null | wc -l' 2>/dev/null || echo "?")
    echo -e "  $cluster: ${GREEN}$running running${NC}, ${YELLOW}$pending pending${NC}"
done
echo ""

# Maintenance check
echo -e "${GREEN}▶ MAINTENANCE${NC}"
for cluster in gilbreth gautschi; do
    maint=$(ssh -o ConnectTimeout=5 "$cluster" 'scontrol show reservations 2>/dev/null | grep -A2 "maint\|MAINT" | grep StartTime | head -1' 2>/dev/null || echo "")
    if [ -n "$maint" ]; then
        start=$(echo "$maint" | sed 's/.*StartTime=\([^ ]*\).*/\1/')
        echo -e "  ${YELLOW}⚠${NC} $cluster: $start"
    else
        echo -e "  ${GREEN}✓${NC} $cluster: none scheduled"
    fi
done
echo ""

# Quick commands
echo -e "${CYAN}Commands:${NC}"
echo "  ./scripts/jobs.sh        - detailed job list"
echo "  ./scripts/maintenance.sh - maintenance details"
echo "  ./scripts/sync.sh        - sync projects"
