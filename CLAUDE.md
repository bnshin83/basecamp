# Basecamp

Central hub for tracking experiments across Purdue clusters and repos.

## Clusters

| Name | Host | Scratch |
|------|------|---------|
| gilbreth | gilbreth.rcac.purdue.edu | /scratch/gilbreth/shin283 |
| gautschi | gautschi.rcac.purdue.edu | /scratch/gautschi/shin283 |
| local | localhost | ~/scratch |

## Tracked Repos

| Repo | Description | Active Cluster |
|------|-------------|----------------|
| upgd-research | UPGD research for UAI 2026 | gilbreth |
| memorization-survey | NeurIPS 2024 survey paper | - |
| icml2025-paper | ICML 2025 Memorization & Plasticity | - |

## Quick Commands

```bash
# Check all clusters and repos
./scripts/status.sh

# Sync repo to cluster
./scripts/sync.sh upgd-research gilbreth
./scripts/sync.sh memorization-survey gautschi

# Transfer results
./scripts/transfer.sh gilbreth local outputs/
./scripts/transfer.sh gautschi local /scratch/gautschi/shin283/upgd/checkpoints/

# Submit job
./scripts/submit.sh train.py gilbreth
./scripts/submit.sh train.py gautschi --gres=gpu:2
```

## SSH Config

Add to `~/.ssh/config`:
```
Host gilbreth
    HostName gilbreth.rcac.purdue.edu
    User shin283
    IdentityFile ~/.ssh/id_rsa

Host gautschi
    HostName gautschi.rcac.purdue.edu
    User shin283
    IdentityFile ~/.ssh/id_rsa
```

## Workflow

### Start New Experiment
```bash
# 1. Sync code
./scripts/sync.sh upgd-research gilbreth

# 2. Submit job
./scripts/submit.sh train.py gilbreth --gres=gpu:2 --time=48:00:00

# 3. Monitor
ssh gilbreth 'squeue -u shin283'
```

### Get Results
```bash
./scripts/transfer.sh gilbreth local outputs/exp1/
```

## File Locations

| Type | Gilbreth | Gautschi |
|------|----------|----------|
| Scratch | /scratch/gilbreth/shin283 | /scratch/gautschi/shin283 |
| UPGD | /scratch/gilbreth/shin283/upgd | /scratch/gautschi/shin283/upgd |
| Logs | /scratch/gilbreth/shin283/logs | /scratch/gautschi/shin283/logs |
