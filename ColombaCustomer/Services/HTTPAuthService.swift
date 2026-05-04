import ColombaAuth
import ColombaNetworking
import Foundation

struct HTTPAuthService: AuthService, Sendable {
    private let baseURL: URL
    private let urlSession: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL = HTTPReservationClient.resolvedBaseURL(),
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func requestMagicLink(email: String, locale: AuthLocale) async throws -> MagicLinkChallenge {
        try await perform(
            path: AuthAPI.magicLinkRequest.path,
            body: MagicLinkRequestBody(email: email, locale: locale.rawValue),
            as: MagicLinkChallenge.self
        )
    }

    func verifyMagicLink(challengeId: String, code: String, device: DeviceInfo) async throws -> AuthSession {
        try await perform(
            path: AuthAPI.magicLinkVerify.path,
            body: MagicLinkVerifyRequestBody(challengeId: challengeId, code: code, device: device),
            as: AuthSession.self
        )
    }

    func exchangeAppleCredential(_ credential: AppleCredentialPayload, device: DeviceInfo) async throws -> AuthSession {
        try await perform(
            path: AuthAPI.appleExchange.path,
            body: AppleExchangeRequestBody(credential: credential, device: device),
            as: AuthSession.self
        )
    }

    func exchangeGoogleCredential(
        _ credential: GoogleCredentialPayload,
        device: DeviceInfo
    ) async throws -> AuthSession {
        try await perform(
            path: AuthAPI.googleExchange.path,
            body: GoogleExchangeRequestBody(credential: credential, device: device),
            as: AuthSession.self
        )
    }

    func refreshSession(_ session: AuthSession, device: DeviceInfo) async throws -> AuthSession {
        try await perform(
            path: AuthAPI.sessionRefresh.path,
            body: RefreshSessionRequestBody(refreshToken: session.tokens.refreshToken, device: device),
            as: AuthSession.self
        )
    }

    private func perform<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        as type: Response.Type
    ) async throws -> Response {
        let request = try makeRequest(path: path, body: body)
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthFailure.backendRejected("Colomba auth returned an invalid response.")
            }
            guard 200..<300 ~= httpResponse.statusCode else {
                let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
                throw mappedFailure(statusCode: httpResponse.statusCode, errorResponse: errorResponse)
            }
            do {
                return try decoder.decode(type, from: data)
            } catch {
                throw AuthFailure.backendRejected("Colomba auth returned unreadable data.")
            }
        } catch let error as AuthFailure {
            throw error
        } catch {
            throw AuthFailure.backendRejected("Couldn't reach Colomba auth right now.")
        }
    }

    private func makeRequest<Body: Encodable>(path: String, body: Body) throws -> URLRequest {
        let url = url(for: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return request
    }

    private func url(for path: String) -> URL {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appending(path: normalizedPath)
    }

    private func mappedFailure(statusCode: Int, errorResponse: ErrorResponse?) -> AuthFailure {
        if let errorResponse {
            switch APIError(errorResponse: errorResponse) {
            case .authMagicLinkInvalid:
                return .invalidMagicCode
            case .authMagicLinkExpired:
                return .backendRejected("That magic-link code expired. Request a new sign-in email.")
            case .authSessionRevoked:
                return .backendRejected("Your session expired. Please sign in again.")
            default:
                return .backendRejected(errorResponse.message)
            }
        }

        if statusCode == 401 || statusCode == 403 {
            return .backendRejected("Your session expired. Please sign in again.")
        }
        return .backendRejected("Colomba auth is unavailable right now.")
    }
}

private struct MagicLinkRequestBody: Encodable {
    let email: String
    let locale: String
}

private struct MagicLinkVerifyRequestBody: Encodable {
    let challengeId: String
    let code: String
    let device: DeviceInfo
}

private struct AppleExchangeRequestBody: Encodable {
    let identityToken: String
    let authorizationCode: String
    let nonce: String
    let email: String?
    let fullName: String?
    let device: DeviceInfo

    init(credential: AppleCredentialPayload, device: DeviceInfo) {
        self.identityToken = credential.identityToken
        self.authorizationCode = credential.authorizationCode
        self.nonce = credential.nonce
        self.email = credential.email
        self.fullName = credential.fullName
        self.device = device
    }
}

private struct GoogleExchangeRequestBody: Encodable {
    let accessToken: String
    let idToken: String?
    let email: String?
    let fullName: String?
    let scopes: [String]
    let device: DeviceInfo

    init(credential: GoogleCredentialPayload, device: DeviceInfo) {
        self.accessToken = credential.accessToken
        self.idToken = credential.idToken
        self.email = credential.email
        self.fullName = credential.fullName
        self.scopes = credential.scopes.sorted()
        self.device = device
    }
}

private struct RefreshSessionRequestBody: Encodable {
    let refreshToken: String
    let device: DeviceInfo
}
