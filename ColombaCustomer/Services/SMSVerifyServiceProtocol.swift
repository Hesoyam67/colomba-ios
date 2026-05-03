import Foundation

public protocol SMSVerifyServiceProtocol: Sendable {
    func sendCode(phoneE164: String, locale: AppLanguage) async throws -> SMSChallenge
    func verifyCode(challengeId: String, code: String) async throws -> SMSVerifyResult
}

public struct SMSChallenge: Sendable, Equatable, Decodable {
    public let challengeId: String
    public let expiresAt: Date

    public init(challengeId: String, expiresAt: Date) {
        self.challengeId = challengeId
        self.expiresAt = expiresAt
    }
}

public struct SMSVerifyResult: Sendable, Equatable, Decodable {
    public let verified: Bool
    public let refreshToken: String?

    public init(verified: Bool, refreshToken: String?) {
        self.verified = verified
        self.refreshToken = refreshToken
    }
}

public enum SMSVerifyError: Error, @unchecked Sendable {
    case invalidPhone
    case rateLimited(retryAfter: TimeInterval)
    case challengeExpired
    case wrongCode
    case network(underlying: Error)
    case server(status: Int)
}
