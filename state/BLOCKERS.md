# Blockers

## BACKEND_BLOCKER
- Workspace cloud sync live implementation.

## OPERATOR_BLOCKER
- Google Sheets staging Spreadsheet ID/range.
- Apple signing / TestFlight / export compliance.
- ChatGPT connector write/draft actions are not exposed; Heso Drive handoff remains fallback.

## RESOLVED
- Live auth/SMS beta gate cleared by PR #47.
- Root app auth mock blocker cleared by PR #47.
- SMS example.invalid placeholder blocker cleared by PR #47.
- Simulator preflight busy cleared on retry during PR #47 local gate; GitHub Xcode gate passed.
