import ColombaBilling
import Foundation

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published private(set) var state: PaywallState = .idle

    private let catalog: ProductCatalogLoading
    private let purchaseService: Purchasing
    private let machine = PaywallStateMachine()

    init(
        catalog: ProductCatalogLoading = ProductCatalog(fixtureProducts: ProductCatalog.simulatorFixtures),
        purchaseService: Purchasing = PurchaseService()
    ) {
        self.catalog = catalog
        self.purchaseService = purchaseService
    }

    var products: [ColombaProduct] {
        guard case let .ready(products) = state else {
            return []
        }
        return products
    }

    func load() async {
        state = machine.reduce(state: state, event: .load)
        do {
            state = machine.reduce(state: state, event: .productsLoaded(try await catalog.products()))
        } catch {
            state = machine.reduce(state: state, event: .failed(.productsUnavailable))
        }
    }

    func purchase(product: ColombaProduct) async {
        state = machine.reduce(state: state, event: .purchase(product.id))
        do {
            let outcome = try await purchaseService.purchase(product: product)
            if case let .purchased(productID) = outcome {
                PlanEntitlements.grantPaidPlan(forProductID: productID)
            }
            state = machine.reduce(state: state, event: .purchaseCompleted(outcome))
        } catch {
            state = machine.reduce(state: state, event: .failed(.purchaseFailed))
        }
    }

    func restore() async {
        do {
            let outcome = try await purchaseService.restore()
            if case let .restored(productIDs) = outcome, let productID = productIDs.first {
                PlanEntitlements.grantPaidPlan(forProductID: productID)
            }
            state = machine.reduce(state: state, event: .purchaseCompleted(outcome))
        } catch {
            state = machine.reduce(state: state, event: .failed(.restoreFailed))
        }
    }
}
