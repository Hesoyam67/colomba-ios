# Handoff — Phase 1 → Phase 2

From session: `agent:main:ios-app:phase01`
To session: `agent:main:ios-app:phase02`
Status: **PENDING_XCODE_GATE** — scaffold is staged and source builds pass, but full Phase 1 is blocked until Xcode.app is installed and the iPhone 12 cold-start gate prints a real number under 1.5s.
Commit: `e5260e2` (`Phase 1 iOS customer app scaffold`).

## What shipped in Phase 1 source
- XcodeGen spec at `project.yml` and generated `ColombaCustomer.xcodeproj` / `ColombaCustomer.xcworkspace`.
- Lean SwiftUI app target in `ColombaCustomer/`:
  - `ColombaCustomerApp.swift`
  - `AppEnvironment.swift`
  - `AppRouter.swift`
  - `RootView.swift`
  - `Assets.xcassets/`
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

## Verification already run on Heso
Environment:
- macOS 26.4.1
- `xcode-select -p` → `/Library/Developer/CommandLineTools`
- Xcode.app: **absent**
- Swift CLI: Apple Swift 6.3.1, package tools pinned to Swift 5.10

Passed:
- `xcodegen generate --spec project.yml`
- `bash -n scripts/measure-cold-start.sh`
- root `swift build --disable-sandbox`
- `swift build --disable-sandbox` for every package under `Packages/*` and `Packages/Features/*`

Blocked by missing full Xcode:
- `swift test` root/per-package: XCTest unavailable under CLT-only toolchain.
- `swiftlint --strict`: Homebrew SwiftLint install requires Xcode.app.
- `xcodebuild` / iOS Simulator build.
- `scripts/measure-cold-start.sh`: exits `PAPU_NEEDED_XCODE` before build/launch.

## Xcode install blocker
Attempts made:
- App Store CLI install via `mas install 497799835`.
- Homebrew SwiftLint install to unblock lint locally.

Observed blocker:
- `mas install 497799835` requires sudo password / terminal auth.
- `brew install swiftlint` also refuses under CLT-only setup because it requires full Xcode.

Papu action needed:
1. Install Xcode 16 in `/Applications/Xcode.app` or provide the Mac password for the install/switch step.
2. Then run:
   ```bash
   cd ~/colomba-build/customer-app
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   swift test
   for pkg in Packages/* Packages/Features/*; do [ -f "$pkg/Package.swift" ] && (cd "$pkg" && swift test); done
   swiftlint --strict
   scripts/measure-cold-start.sh
   ```
3. If `scripts/measure-cold-start.sh` prints `<1500`, Phase 1 can be marked `DONE_PHASE1` and Phase 2 can start.

## Phase 2 pickup notes
Do not start Phase 2 until the Xcode/cold-start gate is closed.

When unblocked, Phase 2 owns auth only:
- Sign-in-with-Apple flow.
- Magic-link request/verify flow.
- Session token storage.
- Backend contracts: `/auth/apple`, `/auth/magic-link/request`, `/auth/magic-link/verify`.

Guardrails preserved:
- No billing logic implemented.
- No feature content implemented.
- Locked spec/design-token docs were not modified.
