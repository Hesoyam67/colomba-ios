import Foundation

public enum UsageAPI {
    public static let getUsage = APIEndpoint(method: .get, path: "/usage")
}

public protocol UsageClient: Sendable {
    func getUsage(period: UsagePeriod) async throws -> UsageSnapshot
}

public struct FixtureUsageClient: UsageClient {
    private let snapshot: UsageSnapshot

    public init(snapshot: UsageSnapshot = .fixtureCurrentMonth) {
        self.snapshot = snapshot
    }

    public func getUsage(period: UsagePeriod = .currentMonth) async throws -> UsageSnapshot {
        UsageSnapshot(
            period: period.rawValue,
            usedMinutes: snapshot.usedMinutes,
            includedMinutes: snapshot.includedMinutes,
            overageMinutes: snapshot.overageMinutes,
            planId: snapshot.planId,
            updatedAt: snapshot.updatedAt
        )
    }
}

public extension UsageSnapshot {
    static let fixtureCurrentMonth = UsageSnapshot(
        period: UsagePeriod.currentMonth.rawValue,
        usedMinutes: 9_200,
        includedMinutes: 10_000,
        overageMinutes: 0,
        planId: "plan_growth_chf_monthly",
        updatedAt: Date(timeIntervalSince1970: 1_777_520_000)
    )
}
