# Colomba iOS Customer App

SwiftUI customer app for [colomba-swiss.ch](https://colomba-swiss.ch), the Swiss telephone-reception and reservation assistant platform.

[![iOS CI](https://github.com/Hesoyam67/colomba-ios/actions/workflows/ios-customer-app.yml/badge.svg)](https://github.com/Hesoyam67/colomba-ios/actions/workflows/ios-customer-app.yml)
![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)
![License: Proprietary](https://img.shields.io/badge/license-Proprietary-lightgrey.svg)

## What this is

Colomba Customer is the SwiftUI iOS app that pairs with Colomba's telephone-reception backend. It covers the customer-facing surfaces for onboarding, SMS verification, reservations, plans, usage, and settings.

## Tech stack

- SwiftUI
- PhoneNumberKit
- Twilio Verify
- n8n webhook integration
- StoreKit 2 + Stripe
- SwiftLint strict mode

## Project layout

```text
.
├── ColombaCustomer/              # iOS app target and feature UI
│   ├── Features/                 # App feature screens and flows
│   ├── Resources/                # Localized strings and assets
│   └── RootView.swift            # Root navigation/container
├── Packages/                     # Local Swift packages
│   ├── ColombaAuth/              # Authentication and verification logic
│   └── Features/                 # Feature modules
├── scripts/                      # Local validation and measurement scripts
└── .github/workflows/ios-customer-app.yml # GitHub Actions CI workflow
```

## Localization

The app targets English plus Swiss German, French, and Italian locales: `en`, `de-CH`, `fr-CH`, and `it-CH`. Some strings may still carry `TODO_TRANSLATE` while copy is pending final review.

## Build & run

- Xcode 16.4
- Scheme: `ColombaCustomer`
- Recommended simulator: iPhone 16 / iOS 18.5

Open the project in Xcode, select the `ColombaCustomer` scheme, choose an iPhone 16 simulator running iOS 18.5, then build and run.

## CI

GitHub Actions CI is defined in `.github/workflows/ios-customer-app.yml` and runs the iOS validation lane for this repository.

## Local checks

```bash
scripts/dev-fast.sh
scripts/dev-fast.sh --build
scripts/dev-fast.sh --test
scripts/measure-cold-start.sh
```

`scripts/dev-fast.sh` runs the root Swift package plus every local package under `Packages/*` and `Packages/Features/*`. On non-macOS runners, set `ALLOW_SKIP_NON_DARWIN=1` only when an intentional skip is expected.

`swift test`, `xcodebuild`, and cold-start measurement require a full Xcode install. Command Line Tools alone can build the package sources but cannot provide XCTest or iOS Simulator.

## License

Proprietary. All rights reserved.
