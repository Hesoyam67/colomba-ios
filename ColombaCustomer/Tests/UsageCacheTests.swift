@testable import ColombaCustomer
import ColombaNetworking
import XCTest

final class UsageCacheTests: XCTestCase {
    func testStoresAndLoadsWarmCacheUnderBudget() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "usage-cache-\(UUID().uuidString).json")
        let cache = UsageCache(fileURL: fileURL, now: { Date(timeIntervalSince1970: 1_000) })
        try await cache.store(.fixtureCurrentMonth)

        var samples: [TimeInterval] = []
        for _ in 0..<20 {
            let start = Date()
            let snapshot = await cache.load()
            samples.append(Date().timeIntervalSince(start) * 1_000)
            XCTAssertEqual(snapshot?.usedEvents, 9_200)
        }

        let median = samples.sorted()[samples.count / 2]
        XCTAssertLessThan(median, 200)
        try? await cache.clear()
    }

    func testExpiredCacheMisses() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "usage-cache-expired-\(UUID().uuidString).json")
        var currentDate = Date(timeIntervalSince1970: 1_000)
        let cache = UsageCache(fileURL: fileURL, ttl: 300, now: { currentDate })
        try await cache.store(.fixtureCurrentMonth)

        currentDate = Date(timeIntervalSince1970: 1_301)

        let expiredSnapshot = await cache.load()
        XCTAssertNil(expiredSnapshot)
        try? await cache.clear()
    }
}
