# Beta Gates

## Fast gate
- git diff --check
- swiftlint --strict --quiet
- scripts/dev-fast.sh --build
- scripts/dev-fast.sh --test

## Full gate
- xcrun simctl shutdown all || true
- caffeinate -dimsu -- xcodebuild -scheme ColombaCustomer -destination 'platform=iOS Simulator,name=iPhone 17' test

## Merge gate
- Fast gate pass.
- Full gate pass or explicit TEST_BLOCKER with log.
- PR has Summary, Verification, Risk, Rollback, Blockers.
