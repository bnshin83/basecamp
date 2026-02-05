#!/bin/bash
# Submit job to SLURM cluster

set -e

SCRIPT=$1
CLUSTER=${2:-gilbreth}
shift 2 2>/dev/null || true

BASECAMP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$SCRIPT" ]; then
    echo "Usage: ./submit.sh <script.py or script.sbatch> [cluster] [slurm_args...]"
    echo ""
    echo "Clusters: gilbreth, gautschi"
    echo ""
    echo "Examples:"
    echo "  ./submit.sh train.py gilbreth"
    echo "  ./submit.sh train.py gautschi --gres=gpu:2 --time=48:00:00"
    echo "  ./submit.sh job.sbatch gilbreth"
    exit 1
fi

# Determine scratch path based on cluster
case $CLUSTER in
    gilbreth)
        SCRATCH="/scratch/gilbreth/shin283"
        ;;
    gautschi)
        SCRATCH="/scratch/gautschi/shin283"
        ;;
    *)
        echo "Unknown cluster: $CLUSTER"
        exit 1
        ;;
esac

echo "═══════════════════════════════════════════════════════════"
echo "  Submit: $SCRIPT → $CLUSTER"
echo "═══════════════════════════════════════════════════════════"

# Generate job script if Python file
if [[ "$SCRIPT" == *.py ]]; then
    JOB_NAME=$(basename "$SCRIPT" .py)

    # Default SLURM settings
    PARTITION="gpu"
    TIME="24:00:00"
    GPUS="1"
    MEM="32G"
    CPUS="8"

    # Parse additional args
    for arg in "$@"; do
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

# Setup
module purge
module load anaconda cuda
conda activate ml

# Ensure logs directory exists
mkdir -p $SCRATCH/logs

# Run
cd \$SLURM_SUBMIT_DIR
echo "Starting job at \$(date)"
echo "Running: python $SCRIPT"
python $SCRIPT
echo "Job finished at \$(date)"
EOF
)

    echo "Generated SLURM script:"
    echo "───────────────────────────────────────────────────────────"
    echo "$SBATCH_SCRIPT"
    echo "───────────────────────────────────────────────────────────"
    echo ""

    # Submit via SSH
    REPO_DIR=$(basename "$(pwd)")
    echo "Submitting to $CLUSTER..."
    JOB_ID=$(ssh $CLUSTER "cd $SCRATCH/$REPO_DIR 2>/dev/null || cd ~/$REPO_DIR; sbatch <<'HEREDOC'
$SBATCH_SCRIPT
HEREDOC" | grep -oE '[0-9]+')

else
    # Submit existing sbatch script
    REPO_DIR=$(basename "$(pwd)")
    echo "Submitting $SCRIPT to $CLUSTER..."
    JOB_ID=$(ssh $CLUSTER "cd $SCRATCH/$REPO_DIR 2>/dev/null || cd ~/$REPO_DIR; sbatch $SCRIPT" | grep -oE '[0-9]+')
fi

echo ""
echo "✅ Job submitted: $JOB_ID"
echo ""
echo "Monitor:"
echo "  ssh $CLUSTER 'squeue -j $JOB_ID'"
echo "  ssh $CLUSTER 'tail -f $SCRATCH/logs/${JOB_ID}_*.out'"
echo ""
echo "Cancel:"
echo "  ssh $CLUSTER 'scancel $JOB_ID'"

# Log
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "$TIMESTAMP SUBMIT job=$JOB_ID script=$SCRIPT cluster=$CLUSTER" >> "$BASECAMP_DIR/logs/jobs.log"

echo "═══════════════════════════════════════════════════════════"
