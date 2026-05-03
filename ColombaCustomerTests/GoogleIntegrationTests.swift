@testable import ColombaCustomer
import Foundation
import ColombaAuth
import XCTest

final class GoogleIntegrationTests: XCTestCase {
    func testGoogleSignInConfigurationUsesProductionClientByDefault() {
        let clientID = GoogleSignInConfiguration.resolveClientID(
            bundleIdentifier: "ch.colomba.customer",
            infoDictionary: [
                "ColombaGoogleOAuthProductionClientID": "production-client",
                "ColombaGoogleOAuthLocalDevClientID": "local-client"
            ]
        )

        XCTAssertEqual(clientID, "production-client")
    }

    func testGoogleSignInConfigurationUsesLocalClientForFreeDevBundle() {
        let clientID = GoogleSignInConfiguration.resolveClientID(
            bundleIdentifier: "com.hesoyam.colomba.dev",
            infoDictionary: [
                "ColombaGoogleOAuthProductionClientID": "production-client",
                "ColombaGoogleOAuthLocalDevClientID": "local-client"
            ]
        )

        XCTAssertEqual(clientID, "local-client")
    }

    func testCalendarServiceRequestsGoogleCalendarScopeAndUpsertsEvent() async throws {
        let oauth = MockGoogleOAuthClient(tokenValue: "token-123")
        let client = MockGoogleCalendarClient(externalID: "evt-123")
        let service = GoogleCalendarService(oauth: oauth, client: client)
        let user = Self.user(provider: .google)
        let event = Self.event

        let result = try await service.sync(event: event, for: user)

        XCTAssertEqual(oauth.requestedScopes, [GoogleCalendarService.requiredScopes])
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests.first?.event, event)
        XCTAssertEqual(client.requests.first?.user.authProvider, .google)
        XCTAssertEqual(client.requests.first?.token.accessToken, "token-123")
        XCTAssertEqual(result, CalendarSyncResult(provider: .google, externalID: "evt-123"))
    }

    func testSheetsServiceRequestsSheetsScopeAndAppendsRow() async throws {
        let oauth = MockGoogleOAuthClient(tokenValue: "sheet-token")
        let client = MockGoogleSheetsClient(result: SheetAppendResult(updatedRange: "Bookings!A2:D2", updatedRows: 1))
        let service = GoogleSheetsService(oauth: oauth, client: client)
        let row = SheetRowDraft(spreadsheetID: "sheet-1", range: "Bookings!A:D", values: ["Bellini", "19:30"])

        let result = try await service.append(row: row)

        XCTAssertEqual(oauth.requestedScopes, [GoogleSheetsService.requiredScopes])
        XCTAssertEqual(client.requests.first?.row, row)
        XCTAssertEqual(client.requests.first?.token.accessToken, "sheet-token")
        XCTAssertEqual(result.updatedRange, "Bookings!A2:D2")
    }

    func testGoogleCalendarHTTPClientPostsCalendarEvent() async throws {
        GoogleIntegrationURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/calendar/v3/calendars/primary/events")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer live-token")
            let body = Self.bodyString(from: request)
            XCTAssertTrue(body.contains("Dinner at Bellini"))
            XCTAssertTrue(body.contains("Vegetarian options"))
            return (
                try Self.response(status: 200, url: request.url),
                Data(#"{"id":"calendar-live-event-1"}"#.utf8)
            )
        }
        defer { GoogleIntegrationURLProtocol.requestHandler = nil }

        let client = GoogleCalendarHTTPClient(
            baseURL: try Self.makeURL("https://google.test"),
            urlSession: Self.urlSession()
        )

        let id = try await client.upsertEvent(
            Self.event,
            user: Self.user(provider: .google),
            token: GoogleOAuthToken(accessToken: "live-token", scopes: GoogleCalendarService.requiredScopes)
        )

        XCTAssertEqual(id, "calendar-live-event-1")
    }

    func testGoogleSheetsHTTPClientAppendsRow() async throws {
        GoogleIntegrationURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/v4/spreadsheets/sheet-123/values/Bookings!A:D/append")
            XCTAssertEqual(request.url?.query, "valueInputOption=USER_ENTERED")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer sheet-token")
            let body = Self.bodyString(from: request)
            XCTAssertTrue(body.contains("Bellini"))
            XCTAssertTrue(body.contains("19:30"))
            return (
                try Self.response(status: 200, url: request.url),
                Data(#"{"updates":{"updatedRange":"Bookings!A2:D2","updatedRows":1}}"#.utf8)
            )
        }
        defer { GoogleIntegrationURLProtocol.requestHandler = nil }

        let client = GoogleSheetsHTTPClient(
            baseURL: try Self.makeURL("https://sheets.test"),
            urlSession: Self.urlSession()
        )

        let result = try await client.appendRow(
            SheetRowDraft(spreadsheetID: "sheet-123", range: "Bookings!A:D", values: ["Bellini", "19:30"]),
            token: GoogleOAuthToken(accessToken: "sheet-token", scopes: GoogleSheetsService.requiredScopes)
        )

        XCTAssertEqual(result, SheetAppendResult(updatedRange: "Bookings!A2:D2", updatedRows: 1))
    }

    func testDispatcherRoutesGoogleUsersToGoogleCalendarService() async throws {
        let google = RecordingCalendarSync(result: CalendarSyncResult(provider: .google, externalID: "google-evt"))
        let apple = RecordingCalendarSync(result: CalendarSyncResult(provider: .apple, externalID: "apple-evt"))
        let dispatcher = CalendarSyncDispatcher(google: google, apple: apple)

        let result = try await dispatcher.sync(event: Self.event, for: Self.user(provider: .google))

        XCTAssertEqual(result.externalID, "google-evt")
        XCTAssertEqual(google.callCount, 1)
        XCTAssertEqual(apple.callCount, 0)
    }

    func testDispatcherRejectsMagicLinkUsersWithoutCalendarProvider() async throws {
        let dispatcher = CalendarSyncDispatcher(google: RecordingCalendarSync())

        do {
            _ = try await dispatcher.sync(event: Self.event, for: Self.user(provider: .magicLink))
            XCTFail("Expected unsupported provider error")
        } catch GoogleIntegrationError.unsupportedAuthProvider(.magicLink) {
            XCTAssertTrue(true)
        }
    }

    private static let event = CalendarEventDraft(
        title: "Dinner at Bellini",
        startsAt: Date(timeIntervalSince1970: 1_777_100_000),
        endsAt: Date(timeIntervalSince1970: 1_777_103_600),
        notes: "Vegetarian options"
    )

    private static func urlSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [GoogleIntegrationURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func makeURL(_ rawValue: String) throws -> URL {
        guard let url = URL(string: rawValue) else { throw GoogleIntegrationTestError.invalidURL }
        return url
    }

    private static func response(status: Int, url: URL?) throws -> HTTPURLResponse {
        guard let url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            throw GoogleIntegrationTestError.invalidResponse
        }
        return response
    }

    private static func bodyString(from request: URLRequest) -> String {
        let data: Data
        if let httpBody = request.httpBody {
            data = httpBody
        } else if let stream = request.httpBodyStream {
            data = GoogleIntegrationURLProtocol.data(from: stream)
        } else {
            data = Data()
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static func user(provider: AuthProvider) -> User {
        User(
            id: "cus-google-test",
            displayName: "Colomba Pilot",
            billingEmail: "pilot@colomba.ch",
            locale: .englishSwitzerland,
            authProvider: provider
        )
    }
}

private final class RecordingCalendarSync: CalendarSyncing, @unchecked Sendable {
    private(set) var callCount = 0
    private let result: CalendarSyncResult

    init(result: CalendarSyncResult = CalendarSyncResult(provider: .google, externalID: "event")) {
        self.result = result
    }

    func sync(event: CalendarEventDraft, for user: User) async throws -> CalendarSyncResult {
        callCount += 1
        return result
    }
}

private enum GoogleIntegrationTestError: Error {
    case invalidURL
    case invalidResponse
}

private final class GoogleIntegrationURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: GoogleIntegrationTestError.invalidResponse)
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

    static func data(from stream: InputStream) -> Data {
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
