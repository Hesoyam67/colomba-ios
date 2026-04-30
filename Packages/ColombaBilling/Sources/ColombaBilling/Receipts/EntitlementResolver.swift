import Foundation

public struct EntitlementResolver: Sendable {
    public enum Entitlement: Equatable, Sendable {
        case entitled
        case needsReverify
    }

    private let cache: ReceiptCache

    public init(cache: ReceiptCache) {
        self.cache = cache
    }

    public func isEntitled(productID: String) async -> Bool {
        switch await cache.entitlementState(productID: productID) {
        case .entitled:
            return true
        case .needsReverify:
            return false
        }
    }

    public func entitlement(productID: String) async -> Entitlement {
        switch await cache.entitlementState(productID: productID) {
        case .entitled:
            return .entitled
        case .needsReverify:
            return .needsReverify
        }
    }
}
