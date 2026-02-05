# Basecamp Status

**Last updated**: 2026-02-05 06:00 EST

## Clusters

| Cluster | Status | Running | Pending | Notes |
|---------|--------|---------|---------|-------|
| Gilbreth | ✓ | 0 | 0 | Maintenance active |
| Gautschi | ✓ | 0 | 9 | Maintenance (PartitionDown) |

**Maintenance**: Both clusters down since 4AM, expected back ~8AM today.

## Pending Jobs

### Gautschi (9 jobs waiting)

| JobID | Name | Status |
|-------|------|--------|
| 7526015-19 | celeba_train (5 jobs) | Waiting for maintenance |
| 7437477 | rl_humanoid_upgd_seeds | Waiting |
| 7437538 | rl_humanoid_upgd_seeds | Waiting |
| 7437563_[8-9] | rl_humanoid_upgd_seeds | Waiting |
| 7288555_[8-9] | rl_humanoid_adam_seeds | Waiting |

## Completed (Feb 4)

### Memorization (Gautschi)
- ✓ **gmm_train** x5 - all completed (~2h each)
- ✓ **theory_exp** x4 - all completed

### UPGD (Gautschi)
- ✓ rl_humanoid_upgd_seeds - batch completed

## Next Steps

1. Wait for maintenance to end (~8AM)
2. CelebA training jobs will auto-start
3. Remaining humanoid RL jobs will resume
