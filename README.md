# Basecamp

Central hub for tracking experiments across Purdue RCAC clusters and research repositories.

## Setup

### Clusters
- **Gilbreth**: gilbreth.rcac.purdue.edu
- **Gautschi**: gautschi.rcac.purdue.edu

### Tracked Repos
- `upgd-research` - UAI 2026 UPGD paper
- `memorization-survey` - NeurIPS 2024 survey
- `icml2025-paper` - ICML 2025 paper

## Quick Start

```bash
# Check status of all clusters
./scripts/status.sh

# Sync code to cluster
./scripts/sync.sh upgd-research gilbreth

# Submit job
./scripts/submit.sh train.py gilbreth

# Get results back
./scripts/transfer.sh gilbreth local outputs/
```

## Structure

```
basecamp/
├── clusters/           # Cluster configs
│   ├── gilbreth.yaml
│   ├── gautschi.yaml
│   └── local.yaml
├── experiments/        # Experiment registry
│   └── registry.yaml
├── repos/              # Tracked repos
│   └── repos.yaml
├── scripts/            # Utility scripts
│   ├── status.sh       # Check cluster status
│   ├── sync.sh         # Sync repo to cluster
│   ├── transfer.sh     # Transfer files
│   └── submit.sh       # Submit SLURM jobs
└── logs/               # Operation logs
```

## SSH Config

Add to `~/.ssh/config`:
```
Host gilbreth
    HostName gilbreth.rcac.purdue.edu
    User shin283

Host gautschi
    HostName gautschi.rcac.purdue.edu
    User shin283
```

## Scripts

### status.sh
```bash
./scripts/status.sh           # All clusters
./scripts/status.sh gilbreth  # Gilbreth only
./scripts/status.sh repos     # Show tracked repos
```

### sync.sh
```bash
./scripts/sync.sh upgd-research gilbreth
./scripts/sync.sh /path/to/repo gautschi --dry-run
```

### transfer.sh
```bash
./scripts/transfer.sh gilbreth local outputs/
./scripts/transfer.sh gautschi local /scratch/gautschi/shin283/checkpoints/
```

### submit.sh
```bash
./scripts/submit.sh train.py gilbreth
./scripts/submit.sh train.py gautschi --gres=gpu:2 --time=48:00:00
```
