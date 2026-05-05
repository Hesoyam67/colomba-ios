# Current Control State

- Mode: STABILIZE
- Code truth: GitHub main
- Decision truth: Drive/repo state files
- Command room: Slack <#C0B240ZRCQ0>
- Open PRs: #46 — chore: install GPT-only autonomous control state
- Current main HEAD: 0111a26

## OpenClaw execution model
- model: openai-codex/gpt-5.5
- reasoning_effort: xhigh
- fallback: openai-codex/gpt-5.4

## Resolved by PR #47
- Root auth mock blocker cleared: production/root app path now uses live auth wiring instead of AuthController.productionMock / MockAuthService.
- SMS placeholder blocker cleared: Twilio SMS verify no longer silently falls back to example.invalid.

## Current blockers
- Apple signing / TestFlight / export compliance operator fields pending.
- Google Sheets E2E needs staging Spreadsheet ID/range.
- Workspace cloud sync backend live implementation pending.
- ChatGPT Slack/Drive write actions are not exposed; Heso Drive handoff remains fallback.

## Do not start
- Phase 21.
- New UI.
- New integrations.
- Non-Colomba workstreams.

## Next recommended action
- Merge refreshed PR #46 after green checks, then continue beta signing/TestFlight/Sheets blockers.
