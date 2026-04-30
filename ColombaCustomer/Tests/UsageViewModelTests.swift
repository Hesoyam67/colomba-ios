@testable import ColombaCustomer
import ColombaNetworking
import XCTest

@MainActor
final class UsageViewModelTests: XCTestCase {
    func testLoadsUsageFromNetworkThenWarmCache() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "usage-vm-cache-\(UUID().uuidString).json")
        let cache = UsageCache(fileURL: fileURL, now: { Date(timeIntervalSince1970: 1_000) })
        let viewModel = UsageViewModel(client: FixtureUsageClient(), cache: cache)

        await viewModel.load(preferCache: false)
        XCTAssertEqual(viewModel.snapshot?.usedEvents, 9_200)
        XCTAssertEqual(viewModel.state, .loaded(.fixtureCurrentMonth, source: .network))

        await viewModel.load()
        XCTAssertEqual(viewModel.state, .loaded(.fixtureCurrentMonth, source: .cache))
        try? await cache.clear()
    }

    func testAccessibilityTextIncludesUnitsAndPeriod() async {
        let viewModel = UsageViewModel()

        let text = viewModel.accessibilityText(for: .fixtureCurrentMonth)

        XCTAssertEqual(text, "9'200 of 10'000 events used this month")
    }
}
