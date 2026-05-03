@testable import ColombaCustomer
import ColombaNetworking
import XCTest

@MainActor
final class UsageViewModelTests: XCTestCase {
    func testLoadsUsageFromNetworkThenWarmCache() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "usage-vm-cache-\(UUID().uuidString).json")
        let cache = UsageCache(fileURL: fileURL, now: { Date(timeIntervalSince1970: 1_000) })
        let defaults = Self.makeDefaults()
        let viewModel = UsageViewModel(client: FixtureUsageClient(), cache: cache, defaults: defaults)

        await viewModel.load(preferCache: false)
        XCTAssertEqual(viewModel.snapshot?.usedMinutes, 9_200)
        XCTAssertEqual(viewModel.state, .loaded(.fixtureCurrentMonth, source: .network))

        await viewModel.load()
        XCTAssertEqual(viewModel.state, .loaded(.fixtureCurrentMonth, source: .cache))
        try? await cache.clear()
    }

    func testAccessibilityTextIncludesUnitsAndPeriod() async {
        let viewModel = UsageViewModel()

        let text = viewModel.accessibilityText(for: .fixtureCurrentMonth)

        XCTAssertEqual(text, "9'200 of 10'000 minutes used this month")
    }

    func testPaidPiccolaPlanAppliesOneThousandMinuteEntitlementForThirtyDays() async throws {
        let defaults = Self.makeDefaults()
        let now = Date(timeIntervalSince1970: 1_000)
        PlanEntitlements.grantPaidPlan(
            forProductID: "ch.colomba.customer.piccola.monthly",
            defaults: defaults,
            now: now
        )
        let cache = UsageCache(
            fileURL: FileManager.default.temporaryDirectory
                .appending(path: "usage-vm-cache-\(UUID().uuidString).json")
        )
        let viewModel = UsageViewModel(
            client: FixtureUsageClient(),
            cache: cache,
            defaults: defaults,
            now: { now.addingTimeInterval(60) }
        )

        await viewModel.load(preferCache: false)

        XCTAssertEqual(viewModel.snapshot?.planId, "plan_starter_chf_monthly")
        XCTAssertEqual(viewModel.snapshot?.includedMinutes, 1_000)
        XCTAssertEqual(viewModel.snapshot?.overageMinutes, 8_200)
        try? await cache.clear()
    }

    private static func makeDefaults() -> UserDefaults {
        let suiteName = "colomba-usage-tests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Could not create isolated usage defaults")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
