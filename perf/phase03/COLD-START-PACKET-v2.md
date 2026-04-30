# COLD-START-PACKET-v2 — Phase 3 W7

Created: 2026-04-30T21:34:00+02:00
Repo: `/Users/hesoyam/colomba-build/customer-app`
Branch: `phase3-plans-paywall-heso`
Protocol: N=30 runs, discard first 3 warmup, `scripts/measure-cold-start.sh`, simulator `Colomba Phase1 iPhone 12`, Debug.
Binding gate: p50 ≤ 161.7ms; p95 ≤ 1500ms.

## Baseline
- Artifacts: `perf/phase03/phase03-baseline-20260430T191030Z-*`
- Result: p50 215ms, p95 252.0ms. Gate FAIL.

## Attempt 1
- Hypothesis: post-first-frame auth materialization contended with measured frame.
- Change: defer `AuthRootHost` creation with `DispatchQueue.main.asyncAfter(250ms)`.
- Artifacts: `perf/phase03/phase03-attempt1-20260430T191556Z-*`
- Result: p50 209ms, p95 236.3ms. Improved but FAIL.

## Attempt 2
- Hypothesis: direct app linkage of new billing/paywall support increased launch work.
- Change: isolated app paywall from direct `ColombaBilling` package dependency while keeping package outputs intact.
- Artifacts: `perf/phase03/phase03-attempt2-20260430T191957Z-*`
- Result: p50 226ms, p95 247.6ms. Worse; reverted.

## Attempt 3
- Hypothesis: root `Group`/outer appearance traversal added root-frame overhead.
- Change: moved marker to splash `Text` and removed outer root `Group` wrapper.
- Artifacts: `perf/phase03/phase03-attempt3-20260430T192358Z-*`
- Result: p50 214ms, p95 232.0ms. FAIL; reverted.

## Verdict
Phase 3 W7 is blocked. Three honest attempts failed the binding p50 gate. Final source tree does not keep the failed cold-start code changes. p95 absolute budget stayed green across all runs.

PAPU_NEEDED: choose whether to accept a Phase 3 cold-start scope cut, relax/rebase the p50 gate for Debug simulator Phase 3, or authorize a deeper instrumentation/perf workstream before Phase 3 can be marked DONE.
