@testable import ColombaNetworking
import XCTest

final class UsageClientTests: XCTestCase {
    func testUsageEndpointContract() {
        XCTAssertEqual(UsageAPI.getUsage, APIEndpoint(method: .get, path: "/usage"))
    }

    func testGetUsageReturnsRequestedPeriod() async throws {
        let usage = try await FixtureUsageClient().getUsage(period: .previousMonth)

        XCTAssertEqual(usage.period, UsagePeriod.previousMonth.rawValue)
        XCTAssertEqual(usage.usedEvents, 9_200)
        XCTAssertEqual(usage.includedEvents, 10_000)
        XCTAssertEqual(usage.planId, "plan_growth_chf_monthly")
    }
}
