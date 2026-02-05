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
| paper_convert | ✓ | — | — | local |
| memorization-survey | ✓ | — | — | — |
| icml2025 | ✓ | — | — | — |

### paper_convert

ML conference paper analysis system. Location: `~/paper_convert`

**Database**: `unified_fts_v3.sqlite3` (7,931 papers, 89 clusters)
- NeurIPS 2025: 4,941 papers
- ICML 2025: 2,990 papers

**Quick Commands**:
```bash
cd ~/paper_convert
python scripts/query_analysis.py clusters                    # List clusters
python scripts/query_analysis.py search "your query"         # Search papers
python scripts/query_analysis.py cluster-methods <cluster>   # Get methods
```

**Skill**: `/paper-qa <question>` - Answer questions with paper citations

## Commands

```bash
# Hub (quick overview)
./scripts/hub.sh                 # Cluster status, jobs, maintenance

# Jobs & Maintenance
./scripts/jobs.sh                # Detailed job list across clusters
./scripts/maintenance.sh         # Maintenance schedules

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

## Experiments

Slurm scripts organized by project in `experiments/`:
```
experiments/
└── upgd/
    ├── gilbreth_slurm_rl_ant_upgd.sh
    └── slurm_rl_ant_upgd.sh (gautschi)
```

## Typical Workflow

```bash
# 1. Check hub
./scripts/hub.sh

# 2. Sync code to cluster
./scripts/sync.sh upgd gilbreth

# 3. Submit job
./scripts/submit.sh train.py gilbreth

# 4. Monitor
./scripts/jobs.sh

# 5. Get results
./scripts/transfer.sh gilbreth local outputs/
```
