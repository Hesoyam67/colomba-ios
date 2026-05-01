# Colomba iOS

Colomba iOS is the native iOS client for Colomba, a Swiss Voice-AI receptionist B2B SaaS for restaurants.

## Requirements

- Xcode 16 or newer
- Swift 5.10 or newer
- iOS 17 minimum deployment target
- SwiftLint for local style checks

## Build

Open the project in Xcode and select an available iOS 17+ simulator or connected device.

For command-line builds, detect installed simulator destinations instead of hard-coding a device/OS pair:

```bash
xcrun simctl list devices available --json | jq
```

Then use an available destination from that output for local build and test commands.

## Test

```bash
swiftlint
# Run the app test plan from Xcode or CI using an available iOS 17+ destination.
```

Do not merge PRs while CI is red or pending.

## License

MIT. See [LICENSE](LICENSE).

## Contact

For product or engineering questions, open a GitHub issue or contact the Colomba maintainers.
