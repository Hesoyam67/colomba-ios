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
        XCTAssertEqual(try await success.purchase(product: product), .purchased(productID: product.id))
        XCTAssertEqual(try await success.restore(), .restored(productIDs: ProductCatalog.productIDs))

        let cancel = PurchaseService(mode: .simulatorCancel)
        XCTAssertEqual(try await cancel.purchase(product: product), .cancelled)
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
