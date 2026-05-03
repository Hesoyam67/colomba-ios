import Foundation

public protocol AccountServiceProtocol: Sendable {
    func requestDeletion(reauth: AccountDeletionReauth, accessToken: String) async throws
}

public protocol AccountHTTPClientProtocol: Sendable {
    func requestDeletion(reauth: AccountDeletionReauth, accessToken: String) async throws
}

public enum AccountDeletionReauth: Equatable, Sendable {
    case apple(identityToken: String)
    case magicLink(challengeId: String, code: String)
}

public enum AccountDeletionError: Error, Equatable, Sendable {
    case notAuthenticated
    case reauthRequired
    case reauthInvalid
    case reauthMismatch
    case subscriptionActive(portalURL: URL?)
    case alreadyDeleted
    case maintenance
    case validationFailed
    case network
    case server(status: Int)
}
