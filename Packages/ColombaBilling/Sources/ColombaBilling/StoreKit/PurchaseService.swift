import Foundation

public enum PurchaseOutcome: Equatable, Sendable {
    case purchased(productID: String)
    case restored(productIDs: [String])
    case cancelled
    case pending
}

public protocol Purchasing: Sendable {
    func purchase(product: ColombaProduct) async throws -> PurchaseOutcome
    func restore() async throws -> PurchaseOutcome
}

public struct PurchaseService: Purchasing {
    public enum Mode: Sendable {
        case simulatorSuccess
        case simulatorCancel
        case simulatorPending
    }

    private let mode: Mode

    public init(mode: Mode = .simulatorSuccess) {
        self.mode = mode
    }

    public func purchase(product: ColombaProduct) async throws -> PurchaseOutcome {
        switch mode {
        case .simulatorSuccess:
            return .purchased(productID: product.id)
        case .simulatorCancel:
            return .cancelled
        case .simulatorPending:
            return .pending
        }
    }

    public func restore() async throws -> PurchaseOutcome {
        switch mode {
        case .simulatorSuccess:
            return .restored(productIDs: ProductCatalog.productIDs)
        case .simulatorCancel:
            return .cancelled
        case .simulatorPending:
            return .pending
        }
    }
}
