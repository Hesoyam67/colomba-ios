import Foundation

public struct HTTPAccountClient: AccountHTTPClientProtocol, Sendable {
    private let baseURL: URL
    private let urlSession: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = HTTPReservationClient.resolvedBaseURL(),
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func requestDeletion(reauth: AccountDeletionReauth, accessToken: String) async throws {
        let url = baseURL.appending(path: "auth-account-delete")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(AccountDeletionRequest(reauth: reauth))

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AccountDeletionError.server(status: -1)
            }
            switch httpResponse.statusCode {
            case 200..<300:
                return
            default:
                throw mappedError(statusCode: httpResponse.statusCode, data: data)
            }
        } catch let error as AccountDeletionError {
            throw error
        } catch {
            throw AccountDeletionError.network
        }
    }

    private func mappedError(statusCode: Int, data: Data) -> AccountDeletionError {
        let body = try? decoder.decode(AccountDeletionErrorResponse.self, from: data)
        switch statusCode {
        case 401:
            if body?.error == "reauth_required" { return .reauthRequired }
            return .notAuthenticated
        case 409:
            return .subscriptionActive(portalURL: body?.stripeCustomerPortalUrl)
        case 410:
            return .alreadyDeleted
        case 422:
            switch body?.error {
            case "reauth_invalid": return .reauthInvalid
            case "reauth_mismatch": return .reauthMismatch
            default: return .validationFailed
            }
        case 503:
            return .maintenance
        default:
            return .server(status: statusCode)
        }
    }
}

private struct AccountDeletionRequest: Encodable {
    let reauth: ReauthPayload

    init(reauth: AccountDeletionReauth) {
        self.reauth = ReauthPayload(reauth: reauth)
    }
}

private struct ReauthPayload: Encodable {
    let type: String
    let appleIdentityToken: String?
    let magicLinkChallengeId: String?
    let magicLinkCode: String?

    init(reauth: AccountDeletionReauth) {
        switch reauth {
        case let .apple(identityToken):
            self.type = "apple"
            self.appleIdentityToken = identityToken
            self.magicLinkChallengeId = nil
            self.magicLinkCode = nil
        case let .magicLink(challengeId, code):
            self.type = "magic_link"
            self.appleIdentityToken = nil
            self.magicLinkChallengeId = challengeId
            self.magicLinkCode = code
        }
    }
}

private struct AccountDeletionErrorResponse: Decodable {
    let error: String?
    let stripeCustomerPortalUrl: URL?
}
