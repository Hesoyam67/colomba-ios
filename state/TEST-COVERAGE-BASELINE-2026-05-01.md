# Test Coverage Baseline — 2026-05-01

Branch: `chore/test-coverage-baseline-2026-05-01`
Validation scope: package/unit-test lane only; no xcodebuild per instruction.

## Tests per target

| Test target | Swift files | XCTest functions |
|---|---:|---:|
| `Packages/ColombaAuth/Tests/ColombaAuthTests` | 1 | 9 |
| `Packages/ColombaBilling/Tests/ColombaBillingTests` | 4 | 9 |
| `Packages/ColombaBilling/Tests/StoreKitTests` | 1 | 3 |
| `Packages/ColombaCore/Tests/ColombaCoreTests` | 1 | 1 |
| `Packages/ColombaDesign/Tests/ColombaDesignTests` | 1 | 4 |
| `Packages/ColombaNetworking/Tests/ColombaNetworkingTests` | 5 | 16 |
| `Packages/Features/AccountFeature/Tests/AccountFeatureTests` | 1 | 1 |
| `Packages/Features/InvoicesFeature/Tests/InvoicesFeatureTests` | 1 | 1 |
| `Packages/Features/PlanFeature/Tests/PlanFeatureTests` | 1 | 1 |
| `Packages/Features/ScheduledChangeFeature/Tests/ScheduledChangeFeatureTests` | 1 | 1 |
| `Packages/Features/TopUpFeature/Tests/TopUpFeatureTests` | 1 | 1 |
| `Packages/Features/UpgradeFeature/Tests/UpgradeFeatureTests` | 1 | 1 |
| `Packages/Features/UsageFeature/Tests/UsageFeatureTests` | 1 | 1 |
| `Tests/ColombaCustomerWorkspaceTests` | 1 | 1 |

## Top 10 untested public types in requested scope

Requested scope: `ColombaCustomer/` and root `Sources/`.

No untested public types found in the requested scope. `Sources/ColombaCustomerWorkspace/WorkspaceModule.swift` is already covered by the workspace sentinel test; `ColombaCustomer/` currently has no public declarations in the app target.

## Suggested first 5 unit tests to add

- `APIError.billingPaymentRequired.isRetryable == false` — locks down non-retryable payment state.
- `APIError.networkTimeout.isRetryable == true` — protects offline/timeout retry behavior.
- `APIError.userMessageKey` prefixes raw catalog values — guards localization key contract.
- Known `ErrorResponse.code` maps to catalog case — protects server/client error mapping.
- `ErrorResponse.retryAfterSeconds` preserves throttling metadata — cheap model coverage for future retry UI.

## Tests added in this branch

- Added the five low-dependency `ColombaNetworking` tests above in `APIErrorTests.swift`.
- These are pure model/error-contract tests with no network, StoreKit, simulator, or xcodebuild dependency.
