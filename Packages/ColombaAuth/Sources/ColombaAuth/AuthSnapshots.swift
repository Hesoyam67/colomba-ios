public enum AuthScreenSnapshot {
    public static func describe(state: AuthState) -> String {
        switch state {
        case .restoring:
            "auth.restore.loading"
        case .signedOut:
            "auth.signedOut.apple+google+magicLink"
        case let .requestingMagicLink(email):
            "auth.magic.requesting:\(email)"
        case let .magicLinkSent(challenge):
            "auth.magic.sent:\(challenge.maskedEmail)"
        case let .verifyingMagicLink(challenge):
            "auth.magic.verifying:\(challenge.challengeId)"
        case .authenticatingWithApple:
            "auth.apple.exchanging"
        case .authenticatingWithGoogle:
            "auth.google.exchanging"
        case let .authenticated(session):
            "auth.authenticated:\(session.customer.displayName)"
        case let .failed(message):
            "auth.error:\(message)"
        }
    }
}
