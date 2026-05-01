# Colomba Customer iOS App
![CI](https://github.com/Hesoyam67/colomba-ios/actions/workflows/ios.yml/badge.svg) ![License](https://img.shields.io/badge/license-MIT-blue.svg) ![Swift](https://img.shields.io/badge/swift-5.9-orange.svg) ![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)

## Status

This repository tracks app health through CI, license, Swift, and iOS target badges above.

Phase 1 scaffold for the Colomba B2B customer iOS app.

Canon lives in Drive, not this repo:
- `~/colomba-drive/customer-app/CUSTOMER-APP-SPEC-v0.md`
- `~/colomba-drive/customer-app/CUSTOMER-APP-PLAN-v0.md`
- `~/colomba-drive/customer-app/design-tokens-v0.md`
- `~/colomba-drive/customer-app/handoffs/phase00-to-phase01.md`

Code lives here: `~/colomba-build/customer-app/`.

## Requirements

- Xcode 16
- Swift 5.10
- iOS 18.5 minimum
- SwiftLint

## Local checks

```bash
swift build
for pkg in Packages/* Packages/Features/*; do [ -f "$pkg/Package.swift" ] && (cd "$pkg" && swift build); done
for pkg in Packages/* Packages/Features/*; do [ -f "$pkg/Package.swift" ] && (cd "$pkg" && swift test); done
scripts/measure-cold-start.sh
```

`swift test`, `xcodebuild`, and cold-start measurement require a full Xcode install. Command Line Tools alone can build the package sources but cannot provide XCTest or iOS Simulator.
