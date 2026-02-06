#!/bin/bash
# Submit job to SLURM cluster and auto-register in basecamp
#
# Usage:
#   ./submit.sh <script.sh> <cluster> [--project=upgd] [--method=adam] [--tag=uai2026] [slurm_args...]
#   ./submit.sh train.py gilbreth
#   ./submit.sh job.sbatch gautschi --project=upgd --method=si --tag=uai2026
#
# After submission:
#   1. Job submitted via SSH + sbatch
#   2. Experiment entry appended to experiments/registry.yaml
#   3. STATUS.md updated with new job
#   4. Auto-commit + push to basecamp remote

set -e

BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REGISTRY="$BASECAMP_DIR/experiments/registry.yaml"
STATUS_FILE="$BASECAMP_DIR/STATUS.md"
PROJECTS_FILE="$BASECAMP_DIR/projects/projects.yaml"

SCRIPT=$1
CLUSTER=${2:-gilbreth}
shift 2 2>/dev/null || true

# Parse basecamp-specific flags from remaining args
PROJECT=""
METHOD=""
TAGS=""
SLURM_ARGS=()

for arg in "$@"; do
    case $arg in
        --project=*) PROJECT="${arg#*=}" ;;
        --method=*) METHOD="${arg#*=}" ;;
        --tag=*) TAGS="${TAGS:+$TAGS, }${arg#*=}" ;;
        *) SLURM_ARGS+=("$arg") ;;
    esac
done

if [ -z "$SCRIPT" ]; then
    echo "Usage: ./submit.sh <script.sh or script.py> [cluster] [options] [slurm_args...]"
    echo ""
    echo "Clusters: gilbreth, gautschi"
    echo ""
    echo "Options:"
    echo "  --project=NAME    Project name (e.g., upgd)"
    echo "  --method=NAME     Method/learner name (e.g., adam, si)"
    echo "  --tag=TAG         Add tag (repeatable)"
    echo ""
    echo "Examples:"
    echo "  ./submit.sh train.py gilbreth"
    echo "  ./submit.sh gautschi_si_all_datasets.sh gautschi --project=upgd --method=si --tag=uai2026"
    exit 1
fi

# Determine scratch path
case $CLUSTER in
    gilbreth) SCRATCH="/scratch/gilbreth/shin283" ;;
    gautschi) SCRATCH="/scratch/gautschi/shin283" ;;
    *) echo "Unknown cluster: $CLUSTER"; exit 1 ;;
esac

SCRIPT_BASENAME=$(basename "$SCRIPT" .sh)
SCRIPT_BASENAME=$(basename "$SCRIPT_BASENAME" .py)

echo "═══════════════════════════════════════════════════════════"
echo "  Submit: $SCRIPT → $CLUSTER"
echo "═══════════════════════════════════════════════════════════"

# ── Submit the job ──────────────────────────────────────────

if [[ "$SCRIPT" == *.py ]]; then
    JOB_NAME=$(basename "$SCRIPT" .py)

    PARTITION="gpu"
    TIME="24:00:00"
    GPUS="1"
    MEM="32G"
    CPUS="8"

    for arg in "${SLURM_ARGS[@]}"; do
        case $arg in
            --partition=*) PARTITION="${arg#*=}" ;;
            --time=*) TIME="${arg#*=}" ;;
            --gres=gpu:*) GPUS="${arg#*=gpu:}" ;;
            --mem=*) MEM="${arg#*=}" ;;
            --cpus-per-task=*) CPUS="${arg#*=}" ;;
        esac
    done

    SBATCH_SCRIPT=$(cat <<EOF
#!/bin/bash
#SBATCH --job-name=$JOB_NAME
#SBATCH --partition=$PARTITION
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=$CPUS
#SBATCH --gres=gpu:$GPUS
#SBATCH --mem=$MEM
#SBATCH --time=$TIME
#SBATCH --output=$SCRATCH/logs/%j_%x.out
#SBATCH --error=$SCRATCH/logs/%j_%x.err

module purge
module load anaconda cuda
conda activate ml

mkdir -p $SCRATCH/logs
cd \$SLURM_SUBMIT_DIR
echo "Starting job at \$(date)"
python $SCRIPT
echo "Job finished at \$(date)"
EOF
)

    echo "Generated SLURM script:"
    echo "───────────────────────────────────────────────────────────"
    echo "$SBATCH_SCRIPT"
    echo "───────────────────────────────────────────────────────────"
    echo ""

    REPO_DIR=$(basename "$(pwd)")
    echo "Submitting to $CLUSTER..."
    JOB_ID=$(ssh $CLUSTER "cd $SCRATCH/$REPO_DIR 2>/dev/null || cd ~/$REPO_DIR; sbatch <<'HEREDOC'
$SBATCH_SCRIPT
HEREDOC" | grep -oE '[0-9]+')

else
    # Submit existing sbatch script
    # Try project scratch dir first, then generic
    SUBMIT_DIR="${SCRATCH}/upgd/slurm_runs"
    if [ -n "$PROJECT" ]; then
        SUBMIT_DIR="${SCRATCH}/${PROJECT}/slurm_runs"
    fi

    echo "Submitting $SCRIPT to $CLUSTER ($SUBMIT_DIR)..."
    SUBMIT_OUTPUT=$(ssh $CLUSTER "cd $SUBMIT_DIR 2>/dev/null && sbatch $(basename "$SCRIPT") || (cd $SCRATCH && sbatch $SCRIPT)" 2>&1)
    JOB_ID=$(echo "$SUBMIT_OUTPUT" | grep -oE '[0-9]+' | tail -1)

    if [ -z "$JOB_ID" ]; then
        echo "❌ Submit failed:"
        echo "$SUBMIT_OUTPUT"
        exit 1
    fi
fi

echo ""
echo "✅ Job submitted: $JOB_ID"
echo ""

# ── Log to jobs.log ─────────────────────────────────────────

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TIMESTAMP_LOCAL=$(date '+%Y-%m-%d %H:%M')
mkdir -p "$BASECAMP_DIR/logs"
echo "$TIMESTAMP SUBMIT job=$JOB_ID script=$SCRIPT cluster=$CLUSTER project=$PROJECT method=$METHOD" >> "$BASECAMP_DIR/logs/jobs.log"

# ── Register in experiments/registry.yaml ───────────────────

EXP_KEY="${PROJECT:-unknown}_${CLUSTER}_${SCRIPT_BASENAME}"

# Extract array size from the script if it's a .sh file
ARRAY_SIZE=""
if [[ "$SCRIPT" == *.sh ]] && [ -f "$SCRIPT" ]; then
    ARRAY_LINE=$(grep '#SBATCH --array=' "$SCRIPT" 2>/dev/null || true)
    if [ -n "$ARRAY_LINE" ]; then
        ARRAY_SIZE=$(echo "$ARRAY_LINE" | grep -oE '[0-9]+-[0-9]+' | head -1)
        ARRAY_THROTTLE=$(echo "$ARRAY_LINE" | grep -oE '%[0-9]+' | tr -d '%')
    fi
fi

# Append experiment entry
cat >> "$REGISTRY" << YAML

  ${EXP_KEY}:
    id: "${JOB_ID}"
    name: "${SCRIPT_BASENAME} (${CLUSTER})"
    project: ${PROJECT:-unknown}
    status: pending
    cluster: ${CLUSTER}
    job_id: ${JOB_ID}
    script: $(basename "$SCRIPT")
    submitted: "${TIMESTAMP}"
${METHOD:+    method: ${METHOD}}
${ARRAY_SIZE:+    array: "${ARRAY_SIZE}"}
${ARRAY_THROTTLE:+    throttle: ${ARRAY_THROTTLE}}
    tags: [${TAGS:-submitted}]
YAML

# Add to active list (insert before the closing bracket if it exists)
# Use a simple check: if the key isn't already in active list, add it
if ! grep -q "$EXP_KEY" "$REGISTRY" 2>/dev/null | head -1 | grep -q "^active:"; then
    # Prepend to active list (after "active:" line)
    if grep -q "^active:" "$REGISTRY"; then
        sed -i '' "/^active:/a\\
\\  - ${EXP_KEY}" "$REGISTRY" 2>/dev/null || \
        sed -i "/^active:/a\\  - ${EXP_KEY}" "$REGISTRY" 2>/dev/null || true
    fi
fi

echo "📝 Registered: ${EXP_KEY} in registry.yaml"

# ── Update STATUS.md ────────────────────────────────────────

# Append a job entry to STATUS.md
{
    echo ""
    echo "### New Job: ${TIMESTAMP_LOCAL}"
    echo "| ${JOB_ID} | ${CLUSTER} | $(basename "$SCRIPT") | ${METHOD:-N/A} | pending |"
} >> "$STATUS_FILE"

echo "📊 Updated STATUS.md"

# ── Auto-commit + push ──────────────────────────────────────

cd "$BASECAMP_DIR"
git add STATUS.md experiments/registry.yaml projects/projects.yaml logs/jobs.log 2>/dev/null || true
git commit -m "Auto-register: ${CLUSTER} job ${JOB_ID} (${SCRIPT_BASENAME})" --no-verify 2>/dev/null || true
git push 2>/dev/null &
PUSH_PID=$!

echo "🚀 Basecamp auto-committed (pushing in background)"

# ── Print follow-up commands ────────────────────────────────

echo ""
echo "Monitor:"
echo "  ssh $CLUSTER 'squeue -j $JOB_ID'"
echo "  ssh $CLUSTER 'tail -f $SCRATCH/logs/${JOB_ID}_*.out'"
echo ""
echo "Cancel:"
echo "  ssh $CLUSTER 'scancel $JOB_ID'"
echo "═══════════════════════════════════════════════════════════"

# Wait for push to finish (but don't block long)
wait $PUSH_PID 2>/dev/null || true
