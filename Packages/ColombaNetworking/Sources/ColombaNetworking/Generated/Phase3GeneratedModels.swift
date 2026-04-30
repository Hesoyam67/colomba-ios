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

    public let id: String
    public let name: String
    public let tier: Tier
    public let monthlyPriceMinor: Int
    public let includedEvents: Int
    public let features: [String]
    public let recommendedForPersona: String?

    public init(
        id: String,
        name: String,
        tier: Tier,
        monthlyPriceMinor: Int,
        includedEvents: Int,
        features: [String],
        recommendedForPersona: String? = nil
    ) {
        self.id = id
        self.name = name
        self.tier = tier
        self.monthlyPriceMinor = monthlyPriceMinor
        self.includedEvents = includedEvents
        self.features = features
        self.recommendedForPersona = recommendedForPersona
    }
}

public enum UsagePeriod: String, Codable, Equatable, Sendable {
    case currentMonth = "current_month"
    case previousMonth = "previous_month"
}

public struct UsageSnapshot: Codable, Equatable, Sendable {
    public let period: String
    public let usedEvents: Int
    public let includedEvents: Int
    public let overageEvents: Int
    public let planId: String?
    public let updatedAt: Date

    public init(
        period: String,
        usedEvents: Int,
        includedEvents: Int,
        overageEvents: Int,
        planId: String? = nil,
        updatedAt: Date
    ) {
        self.period = period
        self.usedEvents = usedEvents
        self.includedEvents = includedEvents
        self.overageEvents = overageEvents
        self.planId = planId
        self.updatedAt = updatedAt
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
