# Basecamp

Central hub for managing experiments across clusters and repositories.

## Quick Commands

| Command | Description |
|---------|-------------|
| `./scripts/status.sh` | Check all clusters |
| `./scripts/sync.sh <repo> <cluster>` | Sync repo to cluster |
| `./scripts/transfer.sh <src> <dest> <path>` | Transfer files |
| `./scripts/submit.sh <script> [cluster]` | Submit SLURM job |

## Clusters

### RCAC (Purdue)
```bash
# SSH alias (add to ~/.ssh/config)
Host rcac
    HostName scholar.rcac.purdue.edu
    User YOUR_USERNAME

# Check status
./scripts/status.sh rcac

# Submit job
./scripts/submit.sh train.py rcac
```

### Local
```bash
./scripts/status.sh local
```

## Workflows

### Start Experiment on RCAC
```bash
# 1. Sync your code
./scripts/sync.sh ~/projects/myrepo rcac

# 2. Submit job
./scripts/submit.sh train.py rcac --gres=gpu:2 --time=48:00:00

# 3. Monitor
ssh rcac 'squeue -u $USER'
```

### Get Results
```bash
# Transfer outputs
./scripts/transfer.sh rcac local outputs/exp1/

# Or specific checkpoint
./scripts/transfer.sh rcac local checkpoints/best.pt
```

### Track Experiment
Edit `experiments/registry.yaml` to log:
- Experiment name, config
- Cluster, job ID
- Results, artifacts
- Notes

## File Locations

| Type | RCAC | Local |
|------|------|-------|
| Code | `~/projects/` | `~/projects/` |
| Scratch | `/scratch/scholar/$USER/` | `~/scratch/` |
| Data | `/depot/project/data/` | `~/data/` |
| Logs | `/scratch/$USER/logs/` | `./logs/` |

## SSH Config

Add to `~/.ssh/config`:
```
Host rcac
    HostName scholar.rcac.purdue.edu
    User YOUR_USERNAME
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Then use `ssh rcac` or `rsync ... rcac:path`.
