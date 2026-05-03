import Foundation

public enum AuthState: Equatable, Sendable {
    case restoring
    case signedOut
    case requestingMagicLink(email: String)
    case magicLinkSent(MagicLinkChallenge)
    case verifyingMagicLink(MagicLinkChallenge)
    case authenticatingWithApple
    case authenticatingWithGoogle
    case authenticated(AuthSession)
    case failed(message: String)

    public var session: AuthSession? {
        guard case let .authenticated(session) = self else {
            return nil
        }
        return session
    }
}

public enum AuthFailure: Error, Equatable, LocalizedError, Sendable {
    case missingAppleCredential
    case missingGoogleCredential
    case invalidEmail
    case invalidDisplayName
    case invalidMagicCode
    case storageFailed(String)
    case backendRejected(String)

    public var errorDescription: String? {
        switch self {
        case .missingAppleCredential:
            "Apple did not return a usable credential."
        case .missingGoogleCredential:
            "Google did not return a usable credential."
        case .invalidEmail:
            "Enter a valid email address."
        case .invalidDisplayName:
            "Enter a display name."
        case .invalidMagicCode:
            "Enter the code from your Colomba sign-in email."
        case let .storageFailed(message):
            message
        case let .backendRejected(message):
            message
        }
    }
}
