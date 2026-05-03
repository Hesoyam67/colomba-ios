import Foundation

public enum AuthLocale: String, Codable, Equatable, Sendable {
    case englishSwitzerland = "en-CH"
    case germanSwitzerland = "de-CH"
    case frenchSwitzerland = "fr-CH"
    case italianSwitzerland = "it-CH"
}

public struct DeviceInfo: Codable, Equatable, Sendable {
    public let deviceId: String
    public let appVersion: String
    public let pushToken: String?

    public init(deviceId: String, appVersion: String, pushToken: String? = nil) {
        self.deviceId = deviceId
        self.appVersion = appVersion
        self.pushToken = pushToken
    }
}

public enum AuthProvider: String, Codable, Equatable, Sendable {
    case apple
    case google
    case magicLink
}

public struct Customer: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let email: String?
    public let phoneNumber: String?
    public let billingEmail: String
    public let locale: AuthLocale
    public let authProvider: AuthProvider

    public init(
        id: String,
        displayName: String,
        email: String? = nil,
        phoneNumber: String? = nil,
        billingEmail: String? = nil,
        locale: AuthLocale,
        authProvider: AuthProvider = .magicLink
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email ?? billingEmail
        self.phoneNumber = phoneNumber
        self.billingEmail = billingEmail ?? email ?? ""
        self.locale = locale
        self.authProvider = authProvider
    }
}

public typealias User = Customer

public struct AuthTokens: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date

    public init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

public struct AuthSession: Codable, Equatable, Sendable {
    public let customer: Customer
    public let tokens: AuthTokens
    public let onboardingRequired: Bool

    public init(customer: Customer, tokens: AuthTokens, onboardingRequired: Bool) {
        self.customer = customer
        self.tokens = tokens
        self.onboardingRequired = onboardingRequired
    }
}

public struct MagicLinkChallenge: Codable, Equatable, Sendable {
    public let challengeId: String
    public let maskedEmail: String
    public let expiresAt: Date
    public let cooldownSeconds: Int

    public init(challengeId: String, maskedEmail: String, expiresAt: Date, cooldownSeconds: Int) {
        self.challengeId = challengeId
        self.maskedEmail = maskedEmail
        self.expiresAt = expiresAt
        self.cooldownSeconds = cooldownSeconds
    }
}
