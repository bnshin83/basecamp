# Basecamp Status

**Last updated**: 2026-02-06 17:00 EST

## Clusters

| Cluster | Status | Running | Held | Pending | Notes |
|---------|--------|---------|------|---------|-------|
| Gautschi | Online | 24 supervised | 3 arrays held | 5 RL quick tests queued | RL tests start as supervised finishes |
| Gilbreth | Online | 6 supervised | 2 arrays held | 4 RL quick tests queued | RL tests start after Adam batch 1 |

## PRIORITY: RL Quick Tests (A/B optimizer comparison)

**Why**: Discovered `upgd_full` used `AdaptiveUPGD` (no global_max_util clamp) while `output_only`/`hidden_only` used `RLLayerSelectiveUPGD` (with clamp). Fixed on both clusters. Running A/B test to validate.

| JobID | Cluster | Env | Methods | Steps | Status |
|-------|---------|-----|---------|-------|--------|
| **7563423** [0-3] | Gautschi | Ant-v4 | full, output, hidden, adam (all fixed) | 2M | Pending |
| **7563489** [0] | Gautschi | Ant-v4 | upgd_full_old (original AdaptiveUPGD) | 2M | Pending |
| **10262040** [0-3] | Gilbreth | Humanoid-v4 | full, output, hidden, adam (all fixed) | 2M | Pending |

**WandB**: `upgd-rl` project, filter for "qt_" prefix
**Analysis**: `UAI_2026/rl_gating_analysis.md`

## Supervised Campaign: UAI 2026 (7 methods — HELD pending RL tests)

**Target**: 5 seeds x 7 methods x 4 datasets = 140 cells
**Changes**: Dropped EWC/MAS (forgetting-focused, not needed for plasticity paper)

### Gautschi (H100)

| JobID | Method | Done | Running | Held | Total |
|-------|--------|------|---------|------|-------|
| 7537671 | SI | **20/20** | - | - | DONE |
| 7537672 | S&P | **20/20** | - | - | DONE |
| 7537673 | SGD | **20/20** | - | - | DONE |
| 7537674 | UPGD Full | 8 | 8 | 4 held | 16/20 |
| 7537675 | UPGD Out | 7 | 8 | 5 held | 15/20 |
| 7537676 | UPGD Hid | 1 | 8 | 11 held | 9/20 |

### Gilbreth (A100-80GB)

| JobID | Method | Done | Running | Held | Total |
|-------|--------|------|---------|------|-------|
| 10260099 | Adam | 0 | 6 | 14 held | 6/20 |
| ~~10260100~~ | ~~EWC~~ | - | - | - | CANCELLED |
| ~~10260101~~ | ~~MAS~~ | - | - | - | CANCELLED |
| 10260102 | SGD | 0 | 0 | 20 held | 0/20 |

### Release holds after RL tests complete
```bash
ssh gautschi "scontrol release 7537674 7537675 7537676"
ssh gilbreth "scontrol release 10260099 10260102"
```

## Monitoring
```bash
bash UAI_2026/monitor.sh          # Full dashboard
bash UAI_2026/monitor.sh --watch  # Auto-refresh
# WandB supervised: https://wandb.ai/shin283-purdue-university/upgd
# WandB RL: https://wandb.ai/shin283-purdue-university/upgd-rl
```

## Next Steps
1. Wait for RL quick tests to complete (~1-1.5h each once started)
2. Analyze A/B results: old Full vs new Full vs Output-only on Ant
3. Decide which optimizer class to standardize on
4. Release supervised holds
5. Design full RL experiment campaign
