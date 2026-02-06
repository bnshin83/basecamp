# Basecamp Status

**Last updated**: 2026-02-05 19:35 EST

## Clusters

| Cluster | Status | Running | Pending | Notes |
|---------|--------|---------|---------|-------|
| Gautschi | ✓ Online | 24 | 72 | SI, S&P, SGD running; UPGD variants queued |
| Gilbreth | ✓ Maintenance | 0 | 80 | Adam, EWC, MAS, SGD queued; auto-start when back |

## Active Campaign: UAI 2026 Supervised Baselines

**Submitted**: Feb 5, 2026 19:12 EST
**Target**: 5 seeds x 9 methods x 4 datasets = 180 cells (123 new runs needed)
**Expected completion**: ~Feb 7 noon

### Gautschi Jobs (6 scripts, 120 array tasks)

| JobID | Script | Method | Status |
|-------|--------|--------|--------|
| 7537671 | gautschi_si_all_datasets.sh | SI | 8 running, 12 pending |
| 7537672 | gautschi_snp_all_datasets.sh | S&P | 8 running, 12 pending |
| 7537673 | gautschi_sgd_extra_seeds.sh | SGD | 8 running, 12 pending |
| 7537674 | gautschi_upgd_full_extra_seeds.sh | UPGD Full | 20 pending (MaxCpuPerAccount) |
| 7537675 | gautschi_upgd_outputonly_extra_seeds.sh | UPGD Out | 20 pending |
| 7537676 | gautschi_upgd_hiddenonly_extra_seeds.sh | UPGD Hid | 20 pending |

### Gilbreth Jobs (4 scripts, 80 array tasks)

| JobID | Script | Method | Status |
|-------|--------|--------|--------|
| 10257411 | gilbreth_adam_all_datasets.sh | Adam | 20 pending (maintenance) |
| 10257412 | gilbreth_ewc_all_datasets.sh | EWC | 20 pending (maintenance) |
| 10257413 | gilbreth_mas_all_datasets.sh | MAS | 20 pending (maintenance) |
| 10257414 | gilbreth_sgd_extra_seeds.sh | SGD | 20 pending (maintenance) |

### Live Progress (Gautschi, as of 19:35)

- SI baselines: ~7% (EMNIST + CIFAR-10 seeds 0-7)
- S&P baselines: ~7% (EMNIST + CIFAR-10 seeds 0-7)
- SGD extra seeds: ~6.5% (EMNIST + CIFAR-10 seeds 0-7)

### Monitoring

```bash
# One-shot dashboard
bash UAI_2026/monitor.sh

# Auto-refresh every 10 min
bash UAI_2026/monitor.sh --watch

# WandB
# https://wandb.ai/shin283-purdue-university/upgd
```

## Next Steps

1. Gilbreth jobs auto-start when maintenance ends
2. Gautschi UPGD jobs start after SI/S&P/SGD wave completes (~8-10h)
3. All runs finish by ~Feb 7 noon
4. Aggregate results and generate tables
