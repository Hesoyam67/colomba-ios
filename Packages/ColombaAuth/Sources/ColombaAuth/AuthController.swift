import Foundation
import Observation

@MainActor
@Observable
public final class AuthController {
    public private(set) var state: AuthState

    private let sessionStore: AuthSessionStore
    private let service: AuthService
    private let device: DeviceInfo
    private let locale: AuthLocale

    public init(
        sessionStore: AuthSessionStore,
        service: AuthService,
        device: DeviceInfo = DeviceInfo(deviceId: "ios-phase2-mock", appVersion: "1.0.0"),
        locale: AuthLocale = .germanSwitzerland,
        initialState: AuthState = .restoring
    ) {
        self.sessionStore = sessionStore
        self.service = service
        self.device = device
        self.locale = locale
        state = initialState
    }

    public static func productionMock() -> AuthController {
        AuthController(sessionStore: KeychainAuthSessionStore(), service: MockAuthService())
    }

    public func restoreSession() async {
        do {
            if let session = try sessionStore.load() {
                state = .authenticated(session)
            } else {
                state = .signedOut
            }
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    public func requestMagicLink(email: String) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@") else {
            state = .failed(message: AuthFailure.invalidEmail.localizedDescription)
            return
        }
        state = .requestingMagicLink(email: trimmedEmail)
        do {
            let challenge = try await service.requestMagicLink(email: trimmedEmail, locale: locale)
            state = .magicLinkSent(challenge)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    public func verifyMagicLink(challenge: MagicLinkChallenge, code: String) async {
        await completeMagicLink(challenge: challenge, code: code)
    }

    public func handleMagicLinkURL(_ url: URL) async {
        guard let credential = MagicLinkURLParser.parse(url) else {
            return
        }
        let challenge = MagicLinkChallenge(
            challengeId: credential.challengeId,
            maskedEmail: "your Colomba email",
            expiresAt: Date().addingTimeInterval(60),
            cooldownSeconds: 0
        )
        await completeMagicLink(challenge: challenge, code: credential.code)
    }

    private func completeMagicLink(challenge: MagicLinkChallenge, code: String) async {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedCode.count >= 6 else {
            state = .failed(message: AuthFailure.invalidMagicCode.localizedDescription)
            return
        }
        state = .verifyingMagicLink(challenge)
        do {
            let session = try await service.verifyMagicLink(
                challengeId: challenge.challengeId,
                code: trimmedCode,
                device: device
            )
            try sessionStore.save(session)
            state = .authenticated(session)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    public func signInWithApple(_ credential: AppleCredentialPayload) async {
        state = .authenticatingWithApple
        do {
            let session = try await service.exchangeAppleCredential(credential, device: device)
            try sessionStore.save(session)
            state = .authenticated(session)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    public func refreshSession() async {
        guard let session = state.session else {
            state = .signedOut
            return
        }
        do {
            let refreshed = try await service.refreshSession(session, device: device)
            try sessionStore.save(refreshed)
            state = .authenticated(refreshed)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    public func signOut() {
        do {
            try sessionStore.clear()
            state = .signedOut
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    public func recordFailure(_ message: String) {
        state = .failed(message: message)
    }
}
