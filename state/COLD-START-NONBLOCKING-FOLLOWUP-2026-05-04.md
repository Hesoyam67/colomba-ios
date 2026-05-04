# Cold-start Non-blocking Follow-up — 2026-05-04

## Status
CI currently marks the iOS simulator build + cold-start gate as `continue-on-error: true`.

## Why
The Phase 3 cold-start budget needs an explicit baseline after the current Xcode/runtime/device target is accepted. Until then, green CI does not mean cold-start is a blocking pass.

## Required follow-up
- Rebaseline cold start with the selected Xcode/runtime/device.
- Write `state/COLD-START-BASELINE-XCODE-26.md` or equivalent for the accepted runner.
- Remove `continue-on-error: true` once the baseline is accepted.
