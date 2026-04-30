# Handoff — Phase 1 → Phase 2

From session: `agent:main:ios-app:phase01`
To session: `agent:main:ios-app:phase02`
Status: **DONE_PHASE1** — scaffold, package surface, design tokens, Xcode build/lint/tests, and iPhone 12 cold-start gate are green.
Cold-start result: `COLOMBA_COLD_START_MS=154` (`154ms < 1500ms`).
Commit base: `e5260e2` (`Phase 1 iOS customer app scaffold`); final gate/docs commit follows this handoff.

## What shipped in Phase 1 source
- XcodeGen spec at `project.yml` and generated `ColombaCustomer.xcodeproj` / `ColombaCustomer.xcworkspace`.
- Lean SwiftUI app target in `ColombaCustomer/`:
  - `ColombaCustomerApp.swift`
  - `AppEnvironment.swift`
  - `AppRouter.swift`
  - `RootView.swift`
  - `Assets.xcassets/` including generated Phase 1 placeholder `AppIcon.appiconset`
  - `Info.plist`
- Root aggregate Swift package at `Package.swift` / `Sources/ColombaCustomerWorkspace` with a sentinel test target.
- Stub packages with public API surfaces:
  - `Packages/ColombaCore`
  - `Packages/ColombaNetworking`
  - `Packages/ColombaAuth`
  - `Packages/ColombaBilling`
  - `Packages/Features/PlanFeature`
  - `Packages/Features/UsageFeature`
  - `Packages/Features/UpgradeFeature`
  - `Packages/Features/TopUpFeature`
  - `Packages/Features/ScheduledChangeFeature`
  - `Packages/Features/InvoicesFeature`
  - `Packages/Features/AccountFeature`
- Full Phase 0.5 design token implementation in `Packages/ColombaDesign/Sources/ColombaDesign/Tokens/`:
  - semantic light/dark colors
  - typography helpers including numeric SF Mono helper
  - spacing scale + semantic aliases
  - corner radii + component aliases
  - motion durations/easing/reduced-motion helper
  - skeleton shimmer modifier
- Cold-start instrumentation:
  - `ColombaCustomerApp.init()` calls `ColdStart.markProcessStarted()`.
  - `RootView.onAppear` calls `ColdStart.markRootViewAppeared()`.
  - `scripts/measure-cold-start.sh` builds, installs, launches on an iPhone 12 simulator, extracts `COLOMBA_COLD_START_MS=<ms>`, and fails at `>=1500` ms.
- CI workflow at `.github/workflows/ios-customer-app.yml`:
  - selects Xcode 16
  - installs SwiftLint
  - runs root + per-package `swift test`
  - runs `swiftlint --strict`
  - runs simulator build + cold-start script

## Verification run on Heso
Environment:
- macOS 26.4.1
- `xcode-select -p` → `/Applications/Xcode.app/Contents/Developer`
- Xcode 26.4.1, build 17E202
- Apple Swift 6.3.1; package manifests pinned to Swift 5.10
- iOS Simulator runtime iOS 26.4.1 (23E254a)
- SwiftLint 0.63.2

Passed:
- `xcodegen generate --spec project.yml`
- `bash -n scripts/measure-cold-start.sh`
- root `swift build --disable-sandbox`
- `swift build --disable-sandbox` for every package under `Packages/*` and `Packages/Features/*`
- root `swift test`
- `swift test` for every package under `Packages/*` and `Packages/Features/*`
- `swiftlint --strict`
- `scripts/measure-cold-start.sh`

Cold-start gate output:
```text
COLOMBA_COLD_START_MS=154
cold-start gate passed: 154ms < 1500ms
```

## Phase 2 pickup notes
Phase 2 can start. It owns auth only:
- Sign-in-with-Apple flow.
- Magic-link request/verify flow.
- Session token storage.
- Backend contracts: `/auth/apple`, `/auth/magic-link/request`, `/auth/magic-link/verify`.

Guardrails preserved:
- No billing logic implemented.
- No feature content implemented.
- Locked spec/design-token docs were not modified.
