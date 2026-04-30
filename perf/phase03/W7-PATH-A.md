# Phase 3 W7 PATH A verdict

Status: FAIL — p50 gate not cleared after 3 honest flag-boundary attempts.
Gate: p50 ≤ 161.7ms, p95 ≤ 1500ms.
Baseline packet p50: 215ms.

| run | commit state | quickcheck samples after 3 warmup | p50 | p95 | verdict |
|---|---|---|---:|---:|---|
| W7-PATH-A-quickcheck-20260430T204500Z | lazy billing flag + billing bootstrap + lazy shell | 196, 182, 195, 195, 196, 198, 194 | 195ms | 197.4ms | FAIL |
| W7-PATH-A-attempt2-quickcheck-20260430T204626Z | plus app paywall/billing linkage isolation | 200, 183, 216, 206, 205, 204, 198 | 204ms | 213.0ms | FAIL |
| W7-PATH-A-attempt3-quickcheck-20260430T204752Z | plus workspace billing dependency trim | 182, 183, 207, 198, 184, 200, 207 | 198ms | 207.0ms | FAIL |

Attempt summary:
1. Feature flag scaffolding + deferred billing bootstrap + lazy customer shell: improved versus 215ms baseline but remained far above 172.4ms partial threshold.
2. Isolated app paywall from direct ColombaBilling linkage: worsened versus attempt 1.
3. Trimmed root workspace billing dependency: still above threshold.

Outcome: Path A did not clear or partially clear the gate. All Path A code commits were reverted. Measurement artifacts are preserved for audit.

PAPU_NEEDED: Path A exhausted. Per decision ladder, the remaining route is operator approval for Path C/W8 deeper instrumentation/per-stage decomposition, or a different operator decision.
