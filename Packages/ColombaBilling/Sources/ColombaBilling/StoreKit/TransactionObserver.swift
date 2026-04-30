import Foundation
import StoreKit

public actor TransactionObserver {
    public private(set) var verifiedProductIDs: [String] = []

    public init() {}

    public func recordVerified(productID: String) {
        guard !verifiedProductIDs.contains(productID) else {
            return
        }
        verifiedProductIDs.append(productID)
    }

    public func observeUpdates() async {
        for await result in Transaction.updates {
            if case let .verified(transaction) = result {
                recordVerified(productID: transaction.productID)
                await transaction.finish()
            }
        }
    }
}
