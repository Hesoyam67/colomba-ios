import Foundation
import StoreKit

public struct ColombaProduct: Equatable, Sendable, Identifiable {
    public let id: String
    public let displayName: String
    public let displayPrice: String
    public let interval: String

    public init(id: String, displayName: String, displayPrice: String, interval: String = "month") {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
        self.interval = interval
    }
}

public protocol ProductCatalogLoading: Sendable {
    func products() async throws -> [ColombaProduct]
}

public struct ProductCatalog: ProductCatalogLoading {
    public static let productIDs: [String] = [
        "ch.colomba.customer.piccola.monthly",
        "ch.colomba.customer.media.monthly",
        "ch.colomba.customer.grande.monthly"
    ]

    private let fixtureProducts: [ColombaProduct]?

    public init(fixtureProducts: [ColombaProduct]? = nil) {
        self.fixtureProducts = fixtureProducts
    }

    public func products() async throws -> [ColombaProduct] {
        if let fixtureProducts {
            return fixtureProducts
        }
        return try await Product.products(for: Self.productIDs).map { product in
            ColombaProduct(
                id: product.id,
                displayName: product.displayName,
                displayPrice: product.displayPrice
            )
        }
    }

    public static let simulatorFixtures: [ColombaProduct] = [
        ColombaProduct(id: "ch.colomba.customer.piccola.monthly", displayName: "Piccola", displayPrice: "CHF 49.00"),
        ColombaProduct(id: "ch.colomba.customer.media.monthly", displayName: "Media", displayPrice: "CHF 149.00"),
        ColombaProduct(id: "ch.colomba.customer.grande.monthly", displayName: "Grande", displayPrice: "CHF 399.00")
    ]
}
