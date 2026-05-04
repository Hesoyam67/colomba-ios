# Current Control State

- Mode: STABILIZE
- Code truth: GitHub main
- Decision truth: Drive/repo state files
- Command room: Slack <#C0B240ZRCQ0>
- Open PRs: None
- Current main HEAD: c3296ee

## Current blockers
- Production/root app path still uses AuthController.productionMock / MockAuthService.
- SMS verify still points to example.invalid.
- Full xcodebuild needs simulator cleanup/rerun.
- TestFlight signing/operator fields pending.
- Google Sheets E2E needs staging Spreadsheet ID/range.
- Workspace cloud sync backend live implementation pending.

## Do not start
- Phase 21.
- New UI.
- New integrations.

## Next recommended action
- chore/live-auth-sms-beta-gate
