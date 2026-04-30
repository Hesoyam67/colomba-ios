@testable import ColombaBilling
import XCTest

final class EntitlementResolverTests: XCTestCase {
    func testEntitlementResolverReturnsTrueForWarmValidReceiptUnderBudget() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "entitlement-\(UUID().uuidString).json")
        let productID = "ch.colomba.customer.piccola.monthly"
        let cache = ReceiptCache(fileURL: fileURL, now: { Date(timeIntervalSince1970: 1_000) })
        try await cache.save(
            CachedReceipt(
                productID: productID,
                transactionID: "tx_123",
                originalTransactionID: "otx_123",
                jws: "signed-jws",
                expirationDate: Date(timeIntervalSince1970: 2_000),
                verifiedAt: Date(timeIntervalSince1970: 1_000)
            )
        )
        let resolver = EntitlementResolver(cache: cache)

        let start = Date()
        let entitled = await resolver.isEntitled(productID: productID)
        let elapsedMs = Date().timeIntervalSince(start) * 1_000

        XCTAssertTrue(entitled)
        XCTAssertLessThan(elapsedMs, 200)
        try? await cache.clear()
    }

    func testEntitlementResolverNeedsReverifyForMissingReceipt() async {
        let cache = ReceiptCache(now: { Date(timeIntervalSince1970: 1_000) })
        let resolver = EntitlementResolver(cache: cache)

        let entitlement = await resolver.entitlement(productID: "missing")
        XCTAssertEqual(entitlement, .needsReverify)
    }
}
