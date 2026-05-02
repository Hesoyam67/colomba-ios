# CLAUDE.md - Colomba iOS Customer App

This file is loaded by Claude Code on every session. Keep under 500 lines. Update when patterns prove valuable.

## Project

B2B-with-B2C-extension iOS app for Swiss restaurant owners and their guests.
- Phase 1-3: operator-side (auth, plans, paywall, Stripe portal, receipts) - DONE
- Phase 4-9: consumer-side (onboarding, SMS verify, reservations, i18n, Swiss locale) - SHIPPED
- Phase 10+: profile edit, reservation cancel/modify, TestFlight prep - IN FLIGHT

Repo: Hesoyam67/colomba-ios
Workspace: ColombaCustomer.xcworkspace
Scheme: ColombaCustomer
Min iOS target: 17.0 (will move to 26.0 for App Store mandate before TestFlight)

## Tech Stack (locked)

- UI: SwiftUI only - no UIKit unless wrapping legacy
- Concurrency: async/await - no completion handlers in new code
- Persistence: SwiftData where applicable, Keychain for sensitive
- Networking: URLSession with custom NetworkClient + ColombaError mapping
- DI: Factory pattern via swift-dependencies
- Testing: XCTest + Swift Testing framework
- Localization: en-CH (primary), de-CH, fr-CH, it-CH - Localizable.xcstrings
- Backend: provider-agnostic n8n adapter (no direct vendor coupling)

## Coding Standards (enforced)

- Prefer value types (struct) over reference types (class)
- Use @Observable macro, NOT ObservableObject
- All public API: doc comments required
- Mark every type with appropriate access control (default to internal, fileprivate where possible)
- NO force unwrapping in production code - try! and as! are gate-blockers
- NO print() / NSLog() in non-test code - use os.Logger
- swiftlint --strict --quiet must exit 0 before any commit

## Quality Gates (D3+D4 doctrine - non-negotiable)

Before any PR is merge-ready:
1. swiftlint --strict --quiet exit 0
2. swift test PASS at root and per-package
3. Xcode Debug build PASS
4. rg "try!" and rg "as!" zero hits in src
5. Cold-start regression <=5% (or operator gate-relax decision documented in DECISIONS.md)
6. CI (Xcode 16.4 / iOS 18.5) green
7. Three honest fix attempts max before escalating to operator. Fakes/waivers = SEV-1.

## File Structure

/customer-app/
 ColombaCustomer.xcworkspace
 Packages/
 ColombaCore/ <-- shared models, errors, network
 ColombaUI/ <-- design system, reusable views
 ColombaAuth/ <-- Sign in with Apple, SMS verify
 Sources/
 Features/ <-- one folder per feature module
 Onboarding/
 Reservation/
 Profile/
 scripts/ <-- gen-error-catalog.sh, decisions-index-refresh.sh, lint helpers
 state/ <-- operator state files (Drive-synced)
 mazal/ <-- content lane outputs (Drive-synced)


## Brief format (when operator dispatches a task)

Every brief from operator includes:
- evidence: Drive file IDs or "operator-discretion call"
- STEPS numbered
- DOCTRINES referenced
- Single workstream / clear before reading / no subagents / single attempt unless stated

Briefs name file paths and public API signatures, NOT bodies. Implementation is your job.
Briefs target <=8 KB, hard limit 12 KB.

## Doctrines (lane runtime - must follow)

1. **GH-TOKEN-FALLBACK**: unset GH_TOKEN; unset GITHUB_TOKEN before gh pr create
2. **SCHEME-NAME-VERIFY**: scheme is ColombaCustomer, never anything else
3. **LOCAL-SIM-IS-CI-BACKUP**: when CI flaky, local swift test + Xcode Debug build are valid override paths with operator OK
4. **SWIFTLINT-FIX-PARTIAL**: --fix resolves ~1/3, manual fixes needed for the rest
5. **HESO-DUPLICATE-PR-V1**: check gh pr list --state all before opening to avoid dupes
6. **SHA-PRECISION**: 40-char SHAs from gh api, never typed
7. **D9-LEDGER-APPEND-ONLY**: PHASE-LEDGER.md is append-only, never edit existing rows

## State layer

Operator state lives in Drive: colomba-drive:Colomba/customer-app/state/
Read on every session start:
- APP-STATE.md (current main SHA, doctrines, decision log)
- DASHBOARD.md (live cron output)
- WAKE-PAPU.md (signal from lanes to operator)

Cron jobs run on Heso's Mac:
- HESO lanes digest every 15m
- LEAN custodian poll every 5m
- Feature PR cascade watchdog every 2m
- SHIP-STATE custodian pass every 5m

## Communication patterns

- Slack #colomba-dev: @Claude for tasks. Slack is the trigger surface.
- Drive: state files only, not interactive briefs.
- claude.ai project chat (operator): strategy, doctrine, briefs.
- ext-Claude (browser extension): fallback for UI-only actions.

## Don't

- Don't write code without reading CLAUDE.md, current state files, and the relevant phase brief
- Don't merge PRs without operator approval (material risk)
- Don't push to main directly
- Don't force-push without --force-with-lease and operator approval
- Don't introduce new dependencies without operator approval
- Don't change OpenAPI contracts without operator approval

## Do

- Read state/APP-STATE.md and DASHBOARD.md at session start
- Run swiftlint --strict before every commit
- Open PRs early (draft) to surface CI failures fast
- Append to DECISIONS.md when you make a non-trivial choice
- Update PHASE-LEDGER.md (append-only) when shipping a phase

End of CLAUDE.md.
