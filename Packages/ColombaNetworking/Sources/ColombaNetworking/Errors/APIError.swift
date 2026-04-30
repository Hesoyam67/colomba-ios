/// Canonical API error coverage from mazal/OUTBOX/bead-mazal-009/error-catalog-v1.yaml.
public enum APIError: String, Error, Codable, CaseIterable, Equatable, Sendable {
    case authAppleCancelled = "auth.apple_cancelled"
    case authMagicLinkExpired = "auth.magic_link_expired"
    case authMagicLinkInvalid = "auth.magic_link_invalid"
    case authSessionRevoked = "auth.session_revoked"
    case billingPaymentRequired = "billing.payment_required"
    case billingPortalUnavailable = "billing.portal_unavailable"
    case aiSupportUnavailable = "ai.support_unavailable"
    case aiRateLimited = "ai.rate_limited"
    case networkOffline = "network.offline"
    case networkTimeout = "network.timeout"
    case serverInternal = "server.internal"
    case serverMaintenance = "server.maintenance"
    case clientDecodeFailed = "client.decode_failed"
    case unknownUnexpected = "unknown.unexpected"

    public init(errorResponse: ErrorResponse) {
        self = Self(rawValue: errorResponse.code) ?? .unknownUnexpected
    }

    public var isRetryable: Bool {
        switch self {
        case .authSessionRevoked, .billingPaymentRequired, .clientDecodeFailed:
            return false
        case .authAppleCancelled, .authMagicLinkExpired, .authMagicLinkInvalid, .billingPortalUnavailable,
             .aiSupportUnavailable, .aiRateLimited, .networkOffline, .networkTimeout, .serverInternal,
             .serverMaintenance, .unknownUnexpected:
            return true
        }
    }

    public var userMessageKey: String {
        "error." + rawValue
    }
}
