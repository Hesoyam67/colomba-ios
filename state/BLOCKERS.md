# Blockers

## BACKEND_BLOCKER
- Workspace cloud sync live implementation.

## OPERATOR_BLOCKER
- Apple signing / TestFlight / export compliance.
- Google Sheets staging Spreadsheet ID/range.
- ChatGPT connector write/draft actions are not exposed; Heso Drive handoff remains fallback.

## RESOLVED
- PR #47 live auth/SMS beta gate is in main.
- PR #46 control state merge is in main.
- Root app auth mock blocker cleared by PR #47.
- SMS example.invalid placeholder blocker cleared by PR #47.
- Simulator preflight busy cleared on retry during PR #47 local gate; GitHub Xcode gate passed.
- Non-Colomba workstreams parked by Colomba-only cutover.
