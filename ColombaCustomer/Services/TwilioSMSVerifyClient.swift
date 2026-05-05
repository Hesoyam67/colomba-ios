import Foundation

public protocol SMSVerifyClientProtocol: Sendable {
    func sendCode(phoneE164: String, locale: AppLanguage) async throws -> SMSChallenge
    func verifyCode(challengeId: String, code: String) async throws -> SMSVerifyResult
}

public struct TwilioSMSVerifyClient: SMSVerifyClientProtocol, Sendable {
    public static let baseURLInfoKey = "ColombaSMSVerifyWebhookBaseURL"

    private let baseURL: URL
    private let urlSession: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        baseURL: URL = Self.resolvedBaseURL(),
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public static func resolvedBaseURL(bundle: Bundle = .main) -> URL {
        for key in [baseURLInfoKey, HTTPReservationClient.baseURLInfoKey] {
            guard
                let rawValue = bundle.object(forInfoDictionaryKey: key) as? String,
                rawValue.isEmpty == false,
                rawValue.contains("$(") == false
            else {
                continue
            }
            guard
                let url = URL(string: rawValue),
                url.scheme?.isEmpty == false,
                url.host?.isEmpty == false
            else {
                fatalError("Invalid SMS verify webhook base URL for Info.plist key \(key).")
            }
            return url
        }
        fatalError(
            "Missing SMS verify webhook base URL. "
                + "Configure ColombaSMSVerifyWebhookBaseURL or ColombaReservationWebhookBaseURL in Info.plist."
        )
    }

    public func sendCode(phoneE164: String, locale: AppLanguage) async throws -> SMSChallenge {
        let request = try makeRequest(
            path: "sms-send",
            body: SendCodeRequest(phone: phoneE164, locale: locale.rawValue)
        )
        return try await perform(request, as: SMSChallenge.self)
    }

    public func verifyCode(challengeId: String, code: String) async throws -> SMSVerifyResult {
        let request = try makeRequest(
            path: "sms-verify",
            body: VerifyCodeRequest(challengeId: challengeId, code: code)
        )
        return try await perform(request, as: SMSVerifyResult.self)
    }

    private func makeRequest<T: Encodable>(path: String, body: T) throws -> URLRequest {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SMSVerifyError.server(status: -1)
            }
            switch httpResponse.statusCode {
            case 200..<300:
                return try decoder.decode(type, from: data)
            case 410:
                throw SMSVerifyError.challengeExpired
            case 422:
                throw SMSVerifyError.wrongCode
            case 429:
                let retry = (try? decoder.decode(RateLimitResponse.self, from: data).retryAfter) ?? 60
                throw SMSVerifyError.rateLimited(retryAfter: retry)
            default:
                throw SMSVerifyError.server(status: httpResponse.statusCode)
            }
        } catch let error as SMSVerifyError {
            throw error
        } catch {
            throw SMSVerifyError.network(underlying: error)
        }
    }
}

private struct SendCodeRequest: Encodable {
    let phone: String
    let locale: String
}

private struct VerifyCodeRequest: Encodable {
    let challengeId: String
    let code: String
}

private struct RateLimitResponse: Decodable {
    let retryAfter: TimeInterval
}
