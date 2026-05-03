import Foundation

public final class AccountService: AccountServiceProtocol, @unchecked Sendable {
    private let client: AccountHTTPClientProtocol

    public init(client: AccountHTTPClientProtocol = HTTPAccountClient()) {
        self.client = client
    }

    public func requestDeletion(reauth: AccountDeletionReauth, accessToken: String) async throws {
        guard accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw AccountDeletionError.notAuthenticated
        }
        do {
            try await client.requestDeletion(reauth: reauth, accessToken: accessToken)
        } catch let error as AccountDeletionError {
            throw error
        } catch {
            throw AccountDeletionError.network
        }
    }
}
