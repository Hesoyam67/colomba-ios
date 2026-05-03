@testable import ColombaCustomer
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
