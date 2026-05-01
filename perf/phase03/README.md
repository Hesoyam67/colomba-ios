# Phase 3 cold-start measurements

Protocol: N=30, discard first 3 warmup, `scripts/measure-cold-start.sh`, simulator `iPhone 16`, Debug.

| run | p50 | p95 | result |
|---|---:|---:|---|
| phase03-baseline-20260430T191030Z | 215ms | 252.0ms | FAIL p50 > 161.7ms |
| phase03-attempt1-20260430T191556Z | 209ms | 236.3ms | FAIL p50 > 161.7ms |
| phase03-attempt2-20260430T191957Z | 226ms | 247.6ms | FAIL p50 > 161.7ms |
| phase03-attempt3-20260430T192358Z | 214ms | 232.0ms | FAIL p50 > 161.7ms |

Attempt notes:
- Attempt 1 deferred post-first-frame auth materialization with `DispatchQueue.main.asyncAfter(250ms)`: improved p50 by 6ms but failed.
- Attempt 2 isolated app paywall from direct `ColombaBilling` package dependency: worsened p50 and was reverted.
- Attempt 3 moved marker onto splash `Text` and removed outer root `Group`: still failed and was reverted.

Final tree intentionally reverts the cold-start code attempts because none cleared the binding gate.
