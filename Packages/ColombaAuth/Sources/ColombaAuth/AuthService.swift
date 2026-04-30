import ColombaNetworking
import Foundation

public protocol AuthService {
    func requestMagicLink(email: String, locale: AuthLocale) async throws -> MagicLinkChallenge
    func verifyMagicLink(challengeId: String, code: String, device: DeviceInfo) async throws -> AuthSession
    func exchangeAppleCredential(_ credential: AppleCredentialPayload, device: DeviceInfo) async throws -> AuthSession
    func refreshSession(_ session: AuthSession, device: DeviceInfo) async throws -> AuthSession
}

public struct AppleCredentialPayload: Equatable, Sendable {
    public let identityToken: String
    public let authorizationCode: String
    public let nonce: String
    public let email: String?
    public let fullName: String?

    public init(
        identityToken: String,
        authorizationCode: String,
        nonce: String,
        email: String? = nil,
        fullName: String? = nil
    ) {
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.nonce = nonce
        self.email = email
        self.fullName = fullName
    }
}

public final class MockAuthService: AuthService {
    private let now: () -> Date

    public private(set) var touchedEndpoints: [APIEndpoint] = []

    public init(now: @escaping () -> Date = { Date() }) {
        self.now = now
    }

    public func requestMagicLink(email: String, locale: AuthLocale) async throws -> MagicLinkChallenge {
        touchedEndpoints.append(AuthAPI.magicLinkRequest)
        guard email.contains("@") else {
            throw AuthFailure.invalidEmail
        }
        return MagicLinkChallenge(
            challengeId: "mch_mock_phase2",
            maskedEmail: mask(email),
            expiresAt: now().addingTimeInterval(15 * 60),
            cooldownSeconds: 30
        )
    }

    public func verifyMagicLink(challengeId: String, code: String, device: DeviceInfo) async throws -> AuthSession {
        touchedEndpoints.append(AuthAPI.magicLinkVerify)
        guard !challengeId.isEmpty, code.count >= 6, !device.deviceId.isEmpty else {
            throw AuthFailure.invalidMagicCode
        }
        return makeSession(email: "pilot@colomba.local", name: "Colomba Pilot")
    }

    public func exchangeAppleCredential(
        _ credential: AppleCredentialPayload,
        device: DeviceInfo
    ) async throws -> AuthSession {
        touchedEndpoints.append(AuthAPI.appleExchange)
        guard !credential.identityToken.isEmpty,
              !credential.authorizationCode.isEmpty,
              !credential.nonce.isEmpty,
              !device.deviceId.isEmpty else {
            throw AuthFailure.missingAppleCredential
        }
        return makeSession(email: credential.email ?? "apple@colomba.local", name: credential.fullName ?? "Colomba Owner")
    }

    public func refreshSession(_ session: AuthSession, device: DeviceInfo) async throws -> AuthSession {
        touchedEndpoints.append(AuthAPI.sessionRefresh)
        guard !session.tokens.refreshToken.isEmpty, !device.deviceId.isEmpty else {
            throw AuthFailure.backendRejected("Refresh token rejected.")
        }
        return AuthSession(
            customer: session.customer,
            tokens: AuthTokens(
                accessToken: "mock_access_refreshed",
                refreshToken: session.tokens.refreshToken,
                expiresAt: now().addingTimeInterval(60 * 60)
            ),
            onboardingRequired: session.onboardingRequired
        )
    }

    private func makeSession(email: String, name: String) -> AuthSession {
        AuthSession(
            customer: Customer(
                id: "cus_mock_phase2",
                displayName: name,
                billingEmail: email,
                locale: .germanSwitzerland
            ),
            tokens: AuthTokens(
                accessToken: "mock_access_phase2",
                refreshToken: "mock_refresh_phase2",
                expiresAt: now().addingTimeInterval(60 * 60)
            ),
            onboardingRequired: false
        )
    }

    private func mask(_ email: String) -> String {
        let parts = email.split(separator: "@", maxSplits: 1).map(String.init)
        guard parts.count == 2, let first = parts.first?.first else {
            return "***"
        }
        return "\(first)***@\(parts[1])"
    }
}
