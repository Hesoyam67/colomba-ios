import ColombaBilling

enum PaywallState: Equatable {
    case idle
    case loadingProducts
    case ready([ColombaProduct])
    case purchasing(String)
    case purchased(String)
    case cancelled
    case pending
    case failed(PaywallError)
}

struct PaywallStateMachine {
    func reduce(state: PaywallState, event: PaywallEvent) -> PaywallState {
        switch event {
        case .load:
            return .loadingProducts
        case let .productsLoaded(products):
            return products.isEmpty ? .failed(.productsUnavailable) : .ready(products)
        case let .purchase(productID):
            return .purchasing(productID)
        case let .purchaseCompleted(outcome):
            switch outcome {
            case let .purchased(productID):
                return .purchased(productID)
            case .restored:
                return state
            case .cancelled:
                return .cancelled
            case .pending:
                return .pending
            }
        case let .failed(error):
            return .failed(error)
        }
    }
}

enum PaywallEvent: Equatable {
    case load
    case productsLoaded([ColombaProduct])
    case purchase(String)
    case purchaseCompleted(PurchaseOutcome)
    case failed(PaywallError)
}
