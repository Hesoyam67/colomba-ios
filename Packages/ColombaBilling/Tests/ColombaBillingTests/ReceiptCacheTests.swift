@testable import ColombaBilling
import XCTest

final class ReceiptCacheTests: XCTestCase {
    func testPersistsAndLoadsReceiptAsCodableJSON() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "receipts-\(UUID().uuidString).json")
        let cache = ReceiptCache(fileURL: fileURL, now: { Date(timeIntervalSince1970: 1_000) })
        let receipt = Self.receipt(verifiedAt: Date(timeIntervalSince1970: 1_000))

        try await cache.save(receipt)
        let data = try Data(contentsOf: fileURL)
        XCTAssertLessThanOrEqual(data.count, 256 * 1_024)

        let reloaded = ReceiptCache(fileURL: fileURL, now: { Date(timeIntervalSince1970: 1_001) })
        try await reloaded.load()

        let state = await reloaded.entitlementState(productID: receipt.productID)
        XCTAssertEqual(state, .entitled(receipt))
        try? await cache.clear()
    }

    func testExpiredReceiptNeedsReverifyWithoutRevokingCachedReceipt() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "receipts-expired-\(UUID().uuidString).json")
        let receipt = Self.receipt(verifiedAt: Date(timeIntervalSince1970: 1_000))
        let cache = ReceiptCache(fileURL: fileURL, ttl: 86_400, now: { Date(timeIntervalSince1970: 90_000) })

        try await cache.save(receipt)

        let state = await cache.entitlementState(productID: receipt.productID)
        let receipts = await cache.allReceipts()
        XCTAssertEqual(state, .needsReverify(receipt))
        XCTAssertEqual(receipts, [receipt])
        try? await cache.clear()
    }

    func testCacheEvictsOldestToStayUnderCap() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "receipts-cap-\(UUID().uuidString).json")
        let cache = ReceiptCache(fileURL: fileURL, maxBytes: 700, now: { Date(timeIntervalSince1970: 1_000) })

        try await cache.save(Self.receipt(productID: "old", verifiedAt: Date(timeIntervalSince1970: 900)))
        try await cache.save(Self.receipt(productID: "new", verifiedAt: Date(timeIntervalSince1970: 1_000)))

        let data = try Data(contentsOf: fileURL)
        XCTAssertLessThanOrEqual(data.count, 700)
        let receipts = await cache.allReceipts()
        XCTAssertEqual(receipts.map(\.productID), ["new"])
        try? await cache.clear()
    }

    private static func receipt(
        productID: String = "ch.colomba.customer.media.monthly",
        verifiedAt: Date
    ) -> CachedReceipt {
        CachedReceipt(
            productID: productID,
            transactionID: "tx_\(productID)",
            originalTransactionID: "otx_\(productID)",
            jws: String(repeating: "jws", count: 40),
            expirationDate: Date(timeIntervalSince1970: 200_000),
            verifiedAt: verifiedAt
        )
    }
}
