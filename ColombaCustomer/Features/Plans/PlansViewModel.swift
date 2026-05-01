import ColombaNetworking
import Foundation

@MainActor
final class PlansViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(PlanList)
        case failed(APIError)
    }

    @Published private(set) var state: LoadState = .idle
    private let repository: PlansRepositoryProtocol

    init(repository: PlansRepositoryProtocol = PlansRepository()) {
        self.repository = repository
    }

    var plans: [Plan] {
        guard case let .loaded(catalog) = state else {
            return []
        }
        return catalog.plans
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await repository.loadPlans())
        } catch let apiError as APIError {
            state = .failed(apiError)
        } catch {
            state = .failed(.unknownUnexpected)
        }
    }

    func priceText(for plan: Plan, currency: String = "CHF") -> String {
        let francs = Decimal(plan.monthlyPriceMinor) / Decimal(100)
        return String(
            format: NSLocalizedString("plans.price_format", comment: ""),
            currency,
            String(describing: francs)
        )
    }

    func includedEventsText(for plan: Plan) -> String {
        String(
            format: NSLocalizedString("plans.included_events_format", comment: ""),
            plan.includedEvents.formatted()
        )
    }
}
