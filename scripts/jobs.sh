#!/bin/bash
# Unified job status across all clusters

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

cluster_jobs() {
    local cluster=$1
    echo -e "${BLUE}━━━ ${cluster} ━━━${NC}"

    if ! ssh -o ConnectTimeout=5 "$cluster" 'squeue -u $USER -o "%.10i %.12P %.30j %.2t %.12M %.6D %R" 2>/dev/null' 2>/dev/null; then
        echo -e "${RED}  Connection failed${NC}"
    fi
    echo ""
}

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         CLUSTER JOB STATUS             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

cluster_jobs "gilbreth"
cluster_jobs "gautschi"
