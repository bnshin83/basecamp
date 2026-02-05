# Basecamp

Central hub for managing research projects across local Mac and Purdue RCAC clusters.

## Overview

Each project can exist in **3 locations**:
- **Local** (Mac)
- **Gilbreth** cluster
- **Gautschi** cluster

Basecamp tracks where each project is deployed and helps sync between them.

## Quick Start

```bash
cd ~/basecamp

# See everything: clusters, local, projects
./scripts/status.sh

# Sync project to cluster
./scripts/sync.sh upgd gilbreth           # Push local → gilbreth
./scripts/sync.sh upgd gautschi --pull    # Pull gautschi → local

# Submit job
./scripts/submit.sh train.py gilbreth

# Transfer results
./scripts/transfer.sh gilbreth local outputs/
```

## Status Output

```
═══════════════════════════════════════════════════════════
  Basecamp Status - 2024-01-15 14:30:00
═══════════════════════════════════════════════════════════

🖥️  gilbreth
  ✅ Connected
  Jobs: 2 running, 1 pending
  Projects:
    upgd                 4.2G

🖥️  gautschi
  ✅ Connected
  Jobs: 0 running, 0 pending
  Projects:
    upgd                 3.8G

💻 Local
  Running experiments: 0
  Disk: 450G free of 1T

📁 Projects Overview

  PROJECT            ACTIVE LOCAL    GILBRETH GAUTSCHI
  upgd               ✓      ✓        ★        ✓
  memorization-survey       ✓        —        —
  icml2025                  ✓        —        —

  Legend: ✓ = exists, ★ = active cluster, — = not deployed
```

## Projects

Defined in `projects/projects.yaml`:

| Project | Description | Active Cluster |
|---------|-------------|----------------|
| upgd | UAI 2026 - UPGD research | gilbreth |
| memorization-survey | NeurIPS 2024 survey | - |
| icml2025 | ICML 2025 paper | - |

## Scripts

### status.sh
```bash
./scripts/status.sh              # Everything
./scripts/status.sh clusters     # Both clusters only
./scripts/status.sh gilbreth     # Gilbreth only
./scripts/status.sh projects     # Project overview
```

### sync.sh
```bash
./scripts/sync.sh <project> [cluster] [--push|--pull] [--dry-run]

./scripts/sync.sh upgd gilbreth           # Push to gilbreth
./scripts/sync.sh upgd gautschi           # Push to gautschi
./scripts/sync.sh upgd gilbreth --pull    # Pull from gilbreth
./scripts/sync.sh upgd gilbreth --dry-run # Preview changes
```

### submit.sh
```bash
./scripts/submit.sh <script.py> [cluster] [slurm_args]

./scripts/submit.sh train.py gilbreth
./scripts/submit.sh train.py gautschi --gres=gpu:2 --time=48:00:00
```

### transfer.sh
```bash
./scripts/transfer.sh <source> <dest> <path>

./scripts/transfer.sh gilbreth local outputs/
./scripts/transfer.sh gautschi local checkpoints/best.pt
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

## Structure

```
basecamp/
├── clusters/           # Cluster configs
│   ├── gilbreth.yaml
│   ├── gautschi.yaml
│   └── local.yaml
├── projects/           # Project registry
│   └── projects.yaml
├── experiments/        # Experiment tracking
│   └── registry.yaml
├── scripts/
│   ├── status.sh
│   ├── sync.sh
│   ├── submit.sh
│   └── transfer.sh
└── logs/
```

## Adding a New Project

Edit `projects/projects.yaml`:

```yaml
  my-new-project:
    name: "My New Project"
    description: "What it does"
    active: true
    locations:
      local: "/path/on/mac"
      gilbreth: "/scratch/gilbreth/shin283/my-new-project"
      gautschi: "/scratch/gautschi/shin283/my-new-project"
    last_sync: {}
    active_cluster: gilbreth
    tags: [tag1, tag2]
```
