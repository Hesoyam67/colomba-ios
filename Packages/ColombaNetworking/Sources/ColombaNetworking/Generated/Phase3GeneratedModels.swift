// Generated from mazal/OUTBOX/bead-mazal-007/openapi-v2-phase3-prep.yaml.
// Source operationIds: listPlans, getUsage, createBillingPortalSession.

import Foundation

public enum GeneratedPhase3API {
    public static let contractVersion = "2.0.0-phase3-prep"
}

public struct PlanList: Codable, Equatable, Sendable {
    public let currency: String
    public let plans: [Plan]
    public let topUps: [Plan]

    public init(currency: String, plans: [Plan], topUps: [Plan]) {
        self.currency = currency
        self.plans = plans
        self.topUps = topUps
    }
}

public struct Plan: Codable, Equatable, Sendable {
    public enum Tier: String, Codable, Equatable, Sendable {
        case starter
        case growth
        case pro
        case enterprise
        case topUp = "top_up"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case tier
        case monthlyPriceMinor
        case includedMinutes
        case includedEvents
        case features
        case recommendedForPersona
    }

    public let id: String
    public let name: String
    public let tier: Tier
    public let monthlyPriceMinor: Int
    public let includedMinutes: Int
    public let features: [String]
    public let recommendedForPersona: String?

    public init(
        id: String,
        name: String,
        tier: Tier,
        monthlyPriceMinor: Int,
        includedMinutes: Int,
        features: [String],
        recommendedForPersona: String? = nil
    ) {
        self.id = id
        self.name = name
        self.tier = tier
        self.monthlyPriceMinor = monthlyPriceMinor
        self.includedMinutes = includedMinutes
        self.features = features
        self.recommendedForPersona = recommendedForPersona
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        tier = try container.decode(Tier.self, forKey: .tier)
        monthlyPriceMinor = try container.decode(Int.self, forKey: .monthlyPriceMinor)
        includedMinutes = try container.decodeIfPresent(Int.self, forKey: .includedMinutes)
            ?? container.decode(Int.self, forKey: .includedEvents)
        features = try container.decode([String].self, forKey: .features)
        recommendedForPersona = try container.decodeIfPresent(String.self, forKey: .recommendedForPersona)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(tier, forKey: .tier)
        try container.encode(monthlyPriceMinor, forKey: .monthlyPriceMinor)
        try container.encode(includedMinutes, forKey: .includedMinutes)
        try container.encode(features, forKey: .features)
        try container.encodeIfPresent(recommendedForPersona, forKey: .recommendedForPersona)
    }
}

public enum UsagePeriod: String, Codable, Equatable, Sendable {
    case currentMonth = "current_month"
    case previousMonth = "previous_month"
}

public struct UsageSnapshot: Codable, Equatable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case period
        case usedMinutes
        case includedMinutes
        case overageMinutes
        case usedEvents
        case includedEvents
        case overageEvents
        case planId
        case updatedAt
    }

    public let period: String
    public let usedMinutes: Int
    public let includedMinutes: Int
    public let overageMinutes: Int
    public let planId: String?
    public let updatedAt: Date

    public init(
        period: String,
        usedMinutes: Int,
        includedMinutes: Int,
        overageMinutes: Int,
        planId: String? = nil,
        updatedAt: Date
    ) {
        self.period = period
        self.usedMinutes = usedMinutes
        self.includedMinutes = includedMinutes
        self.overageMinutes = overageMinutes
        self.planId = planId
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        period = try container.decode(String.self, forKey: .period)
        usedMinutes = try container.decodeIfPresent(Int.self, forKey: .usedMinutes)
            ?? container.decode(Int.self, forKey: .usedEvents)
        includedMinutes = try container.decodeIfPresent(Int.self, forKey: .includedMinutes)
            ?? container.decode(Int.self, forKey: .includedEvents)
        overageMinutes = try container.decodeIfPresent(Int.self, forKey: .overageMinutes)
            ?? container.decode(Int.self, forKey: .overageEvents)
        planId = try container.decodeIfPresent(String.self, forKey: .planId)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(period, forKey: .period)
        try container.encode(usedMinutes, forKey: .usedMinutes)
        try container.encode(includedMinutes, forKey: .includedMinutes)
        try container.encode(overageMinutes, forKey: .overageMinutes)
        try container.encodeIfPresent(planId, forKey: .planId)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

public struct BillingPortalSession: Codable, Equatable, Sendable {
    public let url: URL
    public let expiresAt: Date

    public init(url: URL, expiresAt: Date) {
        self.url = url
        self.expiresAt = expiresAt
    }
}

public struct BillingPortalRequest: Codable, Equatable, Sendable {
    public let returnUrl: URL

    public init(returnUrl: URL) {
        self.returnUrl = returnUrl
    }
}

public struct ErrorResponse: Codable, Equatable, Sendable {
    public let code: String
    public let message: String
    public let retryAfterSeconds: Int?

    public init(code: String, message: String, retryAfterSeconds: Int? = nil) {
        self.code = code
        self.message = message
        self.retryAfterSeconds = retryAfterSeconds
    }
}

public struct FixturePersona: Codable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let locale: String
    public let currency: String
    public let businessType: String
    public let staffCount: Int
    public let planHint: Plan.Tier

    public init(
        id: String,
        label: String,
        locale: String,
        currency: String,
        businessType: String,
        staffCount: Int,
        planHint: Plan.Tier
    ) {
        self.id = id
        self.label = label
        self.locale = locale
        self.currency = currency
        self.businessType = businessType
        self.staffCount = staffCount
        self.planHint = planHint
    }
}
