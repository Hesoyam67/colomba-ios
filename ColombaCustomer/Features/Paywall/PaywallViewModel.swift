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
            state = machine.reduce(
                state: state,
                event: .purchaseCompleted(try await purchaseService.purchase(product: product))
            )
        } catch {
            state = machine.reduce(state: state, event: .failed(.purchaseFailed))
        }
    }

    func restore() async {
        do {
            state = machine.reduce(state: state, event: .purchaseCompleted(try await purchaseService.restore()))
        } catch {
            state = machine.reduce(state: state, event: .failed(.restoreFailed))
        }
    }
}
