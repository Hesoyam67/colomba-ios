import ColombaAuth
@testable import ColombaCustomer
import Foundation
import XCTest

final class HTTPAuthServiceTests: XCTestCase {
    override func tearDown() {
        AuthMockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testRequestMagicLinkPostsExpectedBody() async throws {
        let service = HTTPAuthService(
            baseURL: try Self.makeURL("https://api.colomba-swiss.ch/webhook"),
            urlSession: Self.urlSession()
        )
        var requestBody: [String: String] = [:]

        AuthMockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/webhook/auth/magic-link/request")
            requestBody = try XCTUnwrap(Self.jsonObject(from: request.httpBody))
            let data = Data(
                """
                {
                  "challengeId": "mch_live",
                  "maskedEmail": "o***@colomba.ch",
                  "expiresAt": "2026-05-04T08:45:00Z",
                  "cooldownSeconds": 30
                }
                """.utf8
            )
            return (try Self.response(status: 200, url: request.url), data)
        }

        let challenge = try await service.requestMagicLink(
            email: "owner@colomba.ch",
            locale: .germanSwitzerland
        )

        XCTAssertEqual(requestBody["email"], "owner@colomba.ch")
        XCTAssertEqual(requestBody["locale"], "de-CH")
        XCTAssertEqual(challenge.challengeId, "mch_live")
    }

    func testVerifyMagicLinkMapsInvalidCodeError() async throws {
        let service = HTTPAuthService(
            baseURL: try Self.makeURL("https://api.colomba-swiss.ch/webhook"),
            urlSession: Self.urlSession()
        )
        AuthMockURLProtocol.requestHandler = { request in
            let data = Data(
                """
                {
                  "code": "auth.magic_link_invalid",
                  "message": "Invalid code"
                }
                """.utf8
            )
            return (try Self.response(status: 422, url: request.url), data)
        }

        do {
            _ = try await service.verifyMagicLink(
                challengeId: "mch_123",
                code: "000000",
                device: DeviceInfo(deviceId: "ios-device", appVersion: "1.0")
            )
            XCTFail("Expected invalid code failure")
        } catch let error as AuthFailure {
            XCTAssertEqual(error, .invalidMagicCode)
        }
    }

    func testRefreshSessionPostsRefreshTokenAndDecodesSession() async throws {
        let service = HTTPAuthService(
            baseURL: try Self.makeURL("https://api.colomba-swiss.ch/webhook"),
            urlSession: Self.urlSession()
        )
        var requestBody: [String: Any] = [:]

        AuthMockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/webhook/auth/session/refresh")
            requestBody = try XCTUnwrap(Self.jsonObjectAny(from: request.httpBody))
            let data = Data(
                """
                {
                  "customer": {
                    "id": "cus_live",
                    "displayName": "Colomba Owner",
                    "email": "owner@colomba.ch",
                    "phoneNumber": null,
                    "billingEmail": "owner@colomba.ch",
                    "locale": "de-CH",
                    "authProvider": "magicLink"
                  },
                  "tokens": {
                    "accessToken": "access_live",
                    "refreshToken": "refresh_live",
                    "expiresAt": "2026-05-04T10:00:00Z"
                  },
                  "onboardingRequired": false
                }
                """.utf8
            )
            return (try Self.response(status: 200, url: request.url), data)
        }

        let session = AuthSession(
            customer: Customer(
                id: "cus_old",
                displayName: "Old",
                billingEmail: "owner@colomba.ch",
                locale: .germanSwitzerland
            ),
            tokens: AuthTokens(
                accessToken: "access_old",
                refreshToken: "refresh_live",
                expiresAt: Date(timeIntervalSince1970: 0)
            ),
            onboardingRequired: false
        )

        let refreshed = try await service.refreshSession(
            session,
            device: DeviceInfo(deviceId: "ios-device", appVersion: "1.0")
        )

        XCTAssertEqual(requestBody["refreshToken"] as? String, "refresh_live")
        XCTAssertEqual(
            (requestBody["device"] as? [String: Any])?["deviceId"] as? String,
            "ios-device"
        )
        XCTAssertEqual(refreshed.tokens.accessToken, "access_live")
        XCTAssertEqual(refreshed.customer.displayName, "Colomba Owner")
    }

    private static func urlSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AuthMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func response(status: Int, url: URL?) throws -> HTTPURLResponse {
        let resolvedURL = try XCTUnwrap(url)
        return try XCTUnwrap(
            HTTPURLResponse(
                url: resolvedURL,
                statusCode: status,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
        )
    }

    private static func makeURL(_ raw: String) throws -> URL {
        try XCTUnwrap(URL(string: raw))
    }

    private static func jsonObject(from data: Data?) throws -> [String: String]? {
        guard let data else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: String]
    }

    private static func jsonObjectAny(from data: Data?) throws -> [String: Any]? {
        guard let data else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

private final class AuthMockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(domain: "AuthMockURLProtocol", code: 1)
            )
            return
        }

        do {
            var requestWithBody = request
            if requestWithBody.httpBody == nil, let stream = request.httpBodyStream {
                requestWithBody.httpBody = Self.data(from: stream)
            }
            let (response, data) = try handler(requestWithBody)
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
