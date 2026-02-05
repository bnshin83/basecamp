# Basecamp

Central hub for tracking experiments, transferring data, and managing work across clusters and repos.

## Structure

```
basecamp/
├── clusters/           # Cluster configurations
│   ├── rcac.yaml       # Purdue RCAC settings
│   └── local.yaml      # Local machine settings
├── experiments/        # Experiment registry & results
│   ├── registry.yaml   # All experiments tracker
│   └── archive/        # Completed experiment records
├── repos/              # Tracked repositories
│   └── repos.yaml      # Repo locations & sync status
├── scripts/            # Utility scripts
│   ├── sync.sh         # Sync code to clusters
│   ├── transfer.sh     # Transfer data/models
│   └── status.sh       # Check all cluster status
├── logs/               # Operation logs
└── CLAUDE.md           # Claude Code commands
```

## Quick Commands

```bash
# Check status of all clusters
./scripts/status.sh

# Sync repo to RCAC
./scripts/sync.sh myrepo rcac

# Transfer results from RCAC
./scripts/transfer.sh rcac local outputs/

# List all experiments
cat experiments/registry.yaml
```

## Clusters

| Name | Type | Host |
|------|------|------|
| rcac | SLURM | scholar.rcac.purdue.edu |
| local | Local | localhost |

## Workflows

### Start New Experiment
1. Register in `experiments/registry.yaml`
2. Sync code: `./scripts/sync.sh repo rcac`
3. Submit job on cluster
4. Track with experiment ID

### Retrieve Results
1. Check status: `./scripts/status.sh rcac`
2. Transfer: `./scripts/transfer.sh rcac local outputs/`
3. Update experiment record

## Integration with Claude Code

Copy `.claude/` commands to your projects or use basecamp as your central command center.
