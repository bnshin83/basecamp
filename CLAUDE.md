# Basecamp

Manage research projects across local + gilbreth + gautschi clusters.

## Clusters

| Cluster | SSH Alias | Scratch | Account |
|---------|-----------|---------|---------|
| Gilbreth | `gilbreth` | /scratch/gilbreth/shin283 | jhaddock |
| Gautschi | `gautschi` | /scratch/gautschi/shin283 | jhaddock |
| Local | — | ~/scratch | — |

### Gilbreth (GPU-focused)

| Partition | GPUs | Nodes | Default |
|-----------|------|-------|---------|
| a100-80gb | A100 80GB | 57 | ★ |
| a100-40gb | A100 40GB | 32 | |
| a30 | A30 | 24 | |
| a10 | A10 | 16 | |
| v100 | V100 | 19 | |
| h100 | H100 | 2 | |

- **QoS**: normal, standby, training
- **Env**: Conda (`/scratch/gilbreth/shin283/conda_envs/upgd`)
- **Modules**: `cuda`
- **Defaults**: 3 days, 64G mem, 14 CPUs, 1 GPU

### Gautschi (General purpose)

| Partition | GPUs | Nodes | Max Time | Default |
|-----------|------|-------|----------|---------|
| ai | Yes | 20 | 14 days | ★ |
| smallgpu | Yes | 6 | 12 hours | |
| cpu | No | 336 | 14 days | |
| highmem | No | 6 | 1 day | |

- **QoS**: normal, preemptible
- **Env**: Venv (`/scratch/gautschi/shin283/upgd/.upgd`)
- **Modules**: `cuda`, `python`
- **Defaults**: 3 days, 14 CPUs, 1 GPU

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
