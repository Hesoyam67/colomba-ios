public enum PaywallError: Error, Equatable, Sendable {
    case productsUnavailable
    case purchaseCancelled
    case purchasePending
    case purchaseFailed
    case restoreFailed
    case verificationFailed

    public var userMessage: String {
        switch self {
        case .productsUnavailable:
            "Products are unavailable. Please try again."
        case .purchaseCancelled:
            "Purchase cancelled."
        case .purchasePending:
            "Purchase pending approval."
        case .purchaseFailed:
            "Purchase failed. Please try again."
        case .restoreFailed:
            "Restore failed. Please try again."
        case .verificationFailed:
            "We could not verify the transaction."
        }
    }
}
