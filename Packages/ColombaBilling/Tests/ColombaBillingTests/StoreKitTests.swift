@testable import ColombaBilling
import XCTest

final class StoreKitTests: XCTestCase {
    func testProductsLoadFromSimulatorCatalog() async throws {
        let products = try await ProductCatalog(fixtureProducts: ProductCatalog.simulatorFixtures).products()

        XCTAssertEqual(products.map(\.id), ProductCatalog.productIDs)
        XCTAssertEqual(products.map(\.displayPrice), ["CHF 49.00", "CHF 149.00", "CHF 399.00"])
    }

    func testPurchaseSucceedsRestoreSucceedsAndCancelHandled() async throws {
        let product = ColombaProduct(
            id: "ch.colomba.customer.media.monthly",
            displayName: "Media",
            displayPrice: "CHF 149.00"
        )

        let success = PurchaseService(mode: .simulatorSuccess)
        let purchaseOutcome = try await success.purchase(product: product)
        let restoreOutcome = try await success.restore()
        XCTAssertEqual(purchaseOutcome, .purchased(productID: product.id))
        XCTAssertEqual(restoreOutcome, .restored(productIDs: ProductCatalog.productIDs))

        let cancel = PurchaseService(mode: .simulatorCancel)
        let cancelOutcome = try await cancel.purchase(product: product)
        XCTAssertEqual(cancelOutcome, .cancelled)
    }

    func testStoreKitErrorsHaveLocalizedUserMessages() {
        for error in [
            PaywallError.productsUnavailable,
            .purchaseCancelled,
            .purchasePending,
            .purchaseFailed,
            .restoreFailed,
            .verificationFailed
        ] {
            XCTAssertFalse(error.userMessage.isEmpty)
        }
    }
}
