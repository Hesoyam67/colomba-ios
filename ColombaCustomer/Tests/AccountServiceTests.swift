@testable import ColombaCustomer
import XCTest

final class AccountServiceTests: XCTestCase {
    func testServiceRejectsMissingAccessToken() async throws {
        let client = MockAccountHTTPClient()
        let service = AccountService(client: client)
        do {
            try await service.requestDeletion(reauth: .apple(identityToken: "jwt"), accessToken: " ")
            XCTFail("Expected notAuthenticated")
        } catch AccountDeletionError.notAuthenticated {
            XCTAssertNil(client.receivedAccessToken)
        }
    }

    func testServiceForwardsClientError() async throws {
        let client = MockAccountHTTPClient(error: AccountDeletionError.reauthMismatch)
        let service = AccountService(client: client)
        do {
            try await service.requestDeletion(reauth: .apple(identityToken: "jwt"), accessToken: "access")
            XCTFail("Expected reauthMismatch")
        } catch AccountDeletionError.reauthMismatch {
            XCTAssertEqual(client.receivedAccessToken, "access")
        }
    }

    func testHTTPRequestUsesDeleteEndpointAuthHeaderAndMagicLinkBody() async throws {
        let baseURL = try Self.makeURL("https://n8n.test/webhook")
        var capturedJSON: [String: Any]?
        AccountDeletionURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.lastPathComponent, "auth-account-delete")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
            let body = Self.bodyData(from: request)
            capturedJSON = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            return (try Self.response(status: 204, url: request.url), Data())
        }
        let client = HTTPAccountClient(baseURL: baseURL, urlSession: Self.urlSession())

        try await client.requestDeletion(
            reauth: .magicLink(challengeId: "mch_123", code: "482913"),
            accessToken: "access-token"
        )

        let reauth = try XCTUnwrap(capturedJSON?["reauth"] as? [String: String])
        XCTAssertEqual(reauth["type"], "magic_link")
        XCTAssertEqual(reauth["magicLinkChallengeId"], "mch_123")
        XCTAssertEqual(reauth["magicLinkCode"], "482913")
    }

    func testHTTPMapsStripeSubscriptionConflictWithPortalURL() async throws {
        let expected = try Self.makeURL("https://billing.stripe.test/session")
        AccountDeletionURLProtocol.requestHandler = { request in
            (
                try Self.response(status: 409, url: request.url),
                Data("{\"error\":\"subscription_active\",\"stripeCustomerPortalUrl\":\"\(expected.absoluteString)\"}".utf8)
            )
        }
        let client = HTTPAccountClient(baseURL: try Self.makeURL("https://n8n.test/webhook"), urlSession: Self.urlSession())
        do {
            try await client.requestDeletion(reauth: .apple(identityToken: "jwt"), accessToken: "access")
            XCTFail("Expected subscriptionActive")
        } catch AccountDeletionError.subscriptionActive(let portalURL) {
            XCTAssertEqual(portalURL, expected)
        }
    }

    func testHTTPMapsReauthInvalid() async throws {
        AccountDeletionURLProtocol.requestHandler = { request in
            (try Self.response(status: 422, url: request.url), Data("{\"error\":\"reauth_invalid\"}".utf8))
        }
        let client = HTTPAccountClient(baseURL: try Self.makeURL("https://n8n.test/webhook"), urlSession: Self.urlSession())
        do {
            try await client.requestDeletion(reauth: .apple(identityToken: "jwt"), accessToken: "access")
            XCTFail("Expected reauthInvalid")
        } catch AccountDeletionError.reauthInvalid {
            XCTAssertTrue(true)
        }
    }

    func testHTTPMapsMaintenance() async throws {
        AccountDeletionURLProtocol.requestHandler = { request in
            (try Self.response(status: 503, url: request.url), Data("{\"error\":\"server_maintenance\"}".utf8))
        }
        let client = HTTPAccountClient(baseURL: try Self.makeURL("https://n8n.test/webhook"), urlSession: Self.urlSession())
        do {
            try await client.requestDeletion(reauth: .apple(identityToken: "jwt"), accessToken: "access")
            XCTFail("Expected maintenance")
        } catch AccountDeletionError.maintenance {
            XCTAssertTrue(true)
        }
    }

    override func tearDown() {
        AccountDeletionURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private static func urlSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AccountDeletionURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func makeURL(_ rawValue: String) throws -> URL {
        guard let url = URL(string: rawValue) else { throw AccountDeletionTestError.invalidURL }
        return url
    }

    private static func response(status: Int, url: URL?) throws -> HTTPURLResponse {
        guard let url, let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            throw AccountDeletionTestError.invalidResponse
        }
        return response
    }

    private static func bodyData(from request: URLRequest) -> Data {
        if let httpBody = request.httpBody { return httpBody }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

private final class MockAccountHTTPClient: AccountHTTPClientProtocol, @unchecked Sendable {
    let error: Error?
    private(set) var receivedAccessToken: String?

    init(error: Error? = nil) {
        self.error = error
    }

    func requestDeletion(reauth: AccountDeletionReauth, accessToken: String) async throws {
        receivedAccessToken = accessToken
        if let error { throw error }
    }
}

private enum AccountDeletionTestError: Error {
    case invalidURL
    case invalidResponse
}

private final class AccountDeletionURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: AccountDeletionTestError.invalidResponse)
            return
        }
        do {
            var requestWithBody = request
            if requestWithBody.httpBody == nil, let stream = request.httpBodyStream {
                requestWithBody.httpBody = Self.data(from: stream)
            }
            let (response, data) = try requestHandler(requestWithBody)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func data(from stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 1_024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
