import ColombaNetworking

protocol PlansRepositoryProtocol: Sendable {
    func loadPlans() async throws -> PlanList
}

struct PlansRepository: PlansRepositoryProtocol {
    private let client: PlansClient

    init(client: PlansClient = FixturePlansClient()) {
        self.client = client
    }

    func loadPlans() async throws -> PlanList {
        try await client.listPlans()
    }
}
