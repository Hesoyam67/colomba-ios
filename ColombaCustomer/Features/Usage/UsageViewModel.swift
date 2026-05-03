import ColombaNetworking
import Foundation

@MainActor
final class UsageViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(UsageSnapshot, source: Source)
        case failed(String)
    }

    enum Source: Equatable {
        case cache
        case network
    }

    @Published private(set) var state: State = .idle

    private let client: UsageClient
    private let cache: UsageCache
    private let defaults: UserDefaults
    private let now: () -> Date

    init(
        client: UsageClient = FixtureUsageClient(),
        cache: UsageCache = UsageCache(),
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = { Date() }
    ) {
        self.client = client
        self.cache = cache
        self.defaults = defaults
        self.now = now
    }

    var snapshot: UsageSnapshot? {
        guard case let .loaded(snapshot, _) = state else {
            return nil
        }
        return snapshot
    }

    func load(preferCache: Bool = true) async {
        if preferCache, let cached = await cache.load() {
            state = .loaded(applyPaidPlanEntitlement(to: cached), source: .cache)
            return
        }
        state = .loading
        do {
            let snapshot = applyPaidPlanEntitlement(to: try await client.getUsage(period: .currentMonth))
            try await cache.store(snapshot)
            state = .loaded(snapshot, source: .network)
        } catch {
            state = .failed(String(localized: "usage.unavailable"))
        }
    }

    func refresh() async {
        await load(preferCache: false)
    }

    func progress(for snapshot: UsageSnapshot) -> Double {
        guard snapshot.includedMinutes > 0 else {
            return 0
        }
        return min(Double(snapshot.usedMinutes) / Double(snapshot.includedMinutes), 1)
    }

    func usageText(for snapshot: UsageSnapshot) -> String {
        String(
            format: NSLocalizedString("usage.text_format", comment: ""),
            snapshot.usedMinutes.formatted(),
            snapshot.includedMinutes.formatted()
        )
    }

    func accessibilityText(for snapshot: UsageSnapshot) -> String {
        String(
            format: NSLocalizedString("usage.accessibility_format", comment: ""),
            snapshot.usedMinutes.formatted(),
            snapshot.includedMinutes.formatted()
        )
    }

    private func applyPaidPlanEntitlement(to snapshot: UsageSnapshot) -> UsageSnapshot {
        guard let planId = PlanEntitlements.activePaidPlanID(defaults: defaults, now: now()),
              let includedMinutes = PlanEntitlements.includedMinutes(for: planId) else {
            return snapshot
        }
        return UsageSnapshot(
            period: snapshot.period,
            usedMinutes: snapshot.usedMinutes,
            includedMinutes: includedMinutes,
            overageMinutes: max(snapshot.usedMinutes - includedMinutes, 0),
            planId: planId,
            updatedAt: snapshot.updatedAt
        )
    }
}

enum PlanEntitlements {
    static let selectedPlanIDKey = "colomba.plans.selectedPlanId"
    static let activePaidPlanIDKey = "colomba.plans.activePaidPlanId"
    static let activePaidPlanExpiresAtKey = "colomba.plans.activePaidPlanExpiresAt"
    static let paidPlanDuration: TimeInterval = 30 * 24 * 60 * 60

    private static let productToPlanID = [
        "ch.colomba.customer.piccola.monthly": "plan_starter_chf_monthly",
        "ch.colomba.customer.media.monthly": "plan_growth_chf_monthly",
        "ch.colomba.customer.grande.monthly": "plan_pro_chf_monthly"
    ]

    private static let includedMinutesByPlanID = [
        "plan_starter_chf_monthly": 1_000,
        "plan_growth_chf_monthly": 10_000,
        "plan_pro_chf_monthly": 50_000
    ]

    static func includedMinutes(for planID: String) -> Int? {
        includedMinutesByPlanID[planID]
    }

    static func grantPaidPlan(
        forProductID productID: String,
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) {
        let planID = productToPlanID[productID]
            ?? (includedMinutesByPlanID[productID] == nil ? nil : productID)
            ?? selectedPlanID(defaults: defaults)
        guard let planID else { return }
        defaults.set(planID, forKey: activePaidPlanIDKey)
        defaults.set(now.addingTimeInterval(paidPlanDuration).timeIntervalSince1970, forKey: activePaidPlanExpiresAtKey)
    }

    static func activePaidPlanID(defaults: UserDefaults = .standard, now: Date = Date()) -> String? {
        guard let planID = defaults.string(forKey: activePaidPlanIDKey), planID.isEmpty == false else {
            return nil
        }
        let expiresAt = defaults.double(forKey: activePaidPlanExpiresAtKey)
        guard expiresAt > now.timeIntervalSince1970 else {
            return nil
        }
        return planID
    }

    private static func selectedPlanID(defaults: UserDefaults) -> String? {
        guard let planID = defaults.string(forKey: selectedPlanIDKey), planID.isEmpty == false else {
            return nil
        }
        return planID
    }
}
