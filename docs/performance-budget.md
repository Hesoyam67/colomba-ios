# Performance Budget

Locked v0 contract:

- Cold start: <1.5s on iPhone 16
- Screen transitions: <200ms
- p95 API latency from Switzerland: <300ms
- Push delivery: <2s
- Scroll: zero dropped frames
- Loading states: no spinner >400ms; use skeletons or optimistic UI

Phase 1 instrumentation:
- `ColombaCustomerApp.init()` calls `ColdStart.markProcessStarted()` as the earliest app-entry marker.
- `RootView.onAppear` calls `ColdStart.markRootViewAppeared()` and logs `COLOMBA_COLD_START_MS=<ms>`.
- `scripts/measure-cold-start.sh` builds, installs, launches on an iPhone 16 simulator, extracts the log value, and fails when the value is `>=1500` ms.
