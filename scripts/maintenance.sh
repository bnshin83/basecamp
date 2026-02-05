#!/bin/bash
# Check maintenance schedules across clusters

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

check_maintenance() {
    local cluster=$1
    echo -e "${BLUE}━━━ ${cluster} ━━━${NC}"

    if ! ssh -o ConnectTimeout=5 "$cluster" 'scontrol show reservations 2>/dev/null | grep -A5 "maint\|MAINT" | grep -E "ReservationName|StartTime|EndTime|State"' 2>/dev/null; then
        echo -e "  ${GREEN}No maintenance scheduled${NC}"
    fi
    echo ""
}

echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║       MAINTENANCE SCHEDULES            ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
echo ""

check_maintenance "gilbreth"
check_maintenance "gautschi"

echo -e "${CYAN}Current time: $(date)${NC}"
