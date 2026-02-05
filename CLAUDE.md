# Basecamp

Manage research projects across local + gilbreth + gautschi clusters.

## Clusters

| Cluster | Host | Scratch |
|---------|------|---------|
| gilbreth | gilbreth.rcac.purdue.edu | /scratch/gilbreth/shin283 |
| gautschi | gautschi.rcac.purdue.edu | /scratch/gautschi/shin283 |
| local | Mac | ~/scratch |

## Projects

| Project | Local | Gilbreth | Gautschi | Active |
|---------|-------|----------|----------|--------|
| upgd | ✓ | ★ | ✓ | gilbreth |
| memorization-survey | ✓ | — | — | — |
| icml2025 | ✓ | — | — | — |

## Commands

```bash
# Status
./scripts/status.sh              # All
./scripts/status.sh clusters     # Clusters only
./scripts/status.sh projects     # Projects only

# Sync project
./scripts/sync.sh upgd gilbreth           # local → gilbreth
./scripts/sync.sh upgd gautschi           # local → gautschi
./scripts/sync.sh upgd gilbreth --pull    # gilbreth → local
./scripts/sync.sh upgd gautschi --pull    # gautschi → local

# Submit job
./scripts/submit.sh train.py gilbreth
./scripts/submit.sh train.py gautschi --gres=gpu:2

# Transfer files
./scripts/transfer.sh gilbreth local outputs/
./scripts/transfer.sh gautschi local checkpoints/
```

## Typical Workflow

```bash
# 1. Check status
./scripts/status.sh

# 2. Sync code to cluster
./scripts/sync.sh upgd gilbreth

# 3. Submit job
./scripts/submit.sh train.py gilbreth

# 4. Monitor
ssh gilbreth 'squeue -u shin283'

# 5. Get results
./scripts/transfer.sh gilbreth local outputs/
```
