public enum PlansAPI {
    public static let listPlans = APIEndpoint(method: .get, path: "/plans")
}

public protocol PlansClient: Sendable {
    func listPlans() async throws -> PlanList
}

public struct FixturePlansClient: PlansClient {
    public let catalog: PlanList

    public init(catalog: PlanList = .fixtureCatalog) {
        self.catalog = catalog
    }

    public func listPlans() async throws -> PlanList {
        catalog
    }
}

public extension PlanList {
    static let fixtureCatalog = PlanList(
        currency: "CHF",
        plans: [
            Plan(
                id: "plan_starter_chf_monthly",
                name: "Piccola",
                tier: .starter,
                monthlyPriceMinor: 4_900,
                includedEvents: 1_000,
                features: ["Reservation capture", "Basic analytics"],
                recommendedForPersona: "persona_small_beiz"
            ),
            Plan(
                id: "plan_growth_chf_monthly",
                name: "Media",
                tier: .growth,
                monthlyPriceMinor: 14_900,
                includedEvents: 10_000,
                features: ["AI support chat", "Usage alerts", "Team inbox"],
                recommendedForPersona: "persona_mid_bistro"
            ),
            Plan(
                id: "plan_pro_chf_monthly",
                name: "Grande",
                tier: .pro,
                monthlyPriceMinor: 39_900,
                includedEvents: 50_000,
                features: ["Multi-location", "Priority support", "Advanced reporting"],
                recommendedForPersona: "persona_hair_salon_chain"
            )
        ],
        topUps: [
            Plan(
                id: "topup_events_1000_chf",
                name: "1k event top-up",
                tier: .topUp,
                monthlyPriceMinor: 1_900,
                includedEvents: 1_000,
                features: ["One-off event capacity"]
            )
        ]
    )
}
