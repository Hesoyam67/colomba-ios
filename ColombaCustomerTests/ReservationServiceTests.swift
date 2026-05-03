@testable import ColombaCustomer
import XCTest

final class ReservationServiceTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func test_createReservation_includesAuthHeader() async throws {
        let baseURL = try Self.makeURL("https://n8n.test/webhook")
        var authorizationHeader: String?
        MockURLProtocol.requestHandler = { request in
            authorizationHeader = request.value(forHTTPHeaderField: "Authorization")
            let data = Data(
                """
                {
                  "reservationId": "reservation-1",
                  "restaurantName": "Colomba Bistro",
                  "startsAt": "2026-05-03T18:00:00Z",
                  "partySize": 2
                }
                """.utf8
            )
            return (try Self.response(status: 200, url: request.url), data)
        }
        let client = HTTPReservationClient(baseURL: baseURL, urlSession: Self.urlSession())
        let request = ReservationRequest(
            restaurantId: "restaurant-1",
            slotId: "slot-1",
            partySize: 2,
            fullName: "Papu"
        )
        _ = try await client.createReservation(request, refreshToken: "refresh-token")
        XCTAssertEqual(authorizationHeader, "Bearer refresh-token")
    }

    func test_createReservation_throwsNotAuthenticatedWhenKeychainEmpty() async throws {
        let service = ReservationService(client: UnusedReservationHTTPClient(), keychain: MockKeychain())
        do {
            _ = try await service.createReservation(
                ReservationRequest(
                    restaurantId: "restaurant-1",
                    slotId: "slot-1",
                    partySize: 2,
                    fullName: "Papu"
                )
            )
            XCTFail("Expected not authenticated")
        } catch ReservationError.notAuthenticated {
            XCTAssertTrue(true)
        }
    }

    func test_availability_decodesSlots() async throws {
        let baseURL = try Self.makeURL("https://n8n.test/webhook")
        MockURLProtocol.requestHandler = { request in
            let data = Data(
                """
                {
                  "slots": [
                    {
                      "id": "slot-1",
                      "startsAt": "2026-05-03T18:00:00Z",
                      "durationMinutes": 90
                    }
                  ]
                }
                """.utf8
            )
            return (try Self.response(status: 200, url: request.url), data)
        }
        let client = HTTPReservationClient(baseURL: baseURL, urlSession: Self.urlSession())
        let slots = try await client.availability(
            restaurantId: "restaurant-1",
            date: Date(),
            refreshToken: "refresh-token"
        )
        XCTAssertEqual(slots.map(\.id), ["slot-1"])
        XCTAssertEqual(slots.first?.durationMinutes, 90)
    }

    func test_listMyReservations_decodesArray() async throws {
        let baseURL = try Self.makeURL("https://n8n.test/webhook")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.lastPathComponent, "reservations-list")
            let data = Data(
                """
                {
                  "reservations": [
                    {
                      "reservationId": "reservation-1",
                      "restaurantId": "restaurant-1",
                      "restaurantName": "Colomba Bistro",
                      "startsAt": "2026-05-03T18:00:00Z",
                      "partySize": 2,
                      "specialRequests": null,
                      "status": "active",
                      "cancelledAt": null
                    }
                  ]
                }
                """.utf8
            )
            return (try Self.response(status: 200, url: request.url), data)
        }
        let client = HTTPReservationClient(baseURL: baseURL, urlSession: Self.urlSession())
        let reservations = try await client.listMyReservations(refreshToken: "refresh-token")
        XCTAssertEqual(reservations.map(\.id), ["reservation-1"])
        XCTAssertEqual(reservations.first?.status, .active)
    }

    func test_cancelReservation_includesAuthHeader() async throws {
        let baseURL = try Self.makeURL("https://n8n.test/webhook")
        var authorizationHeader: String?
        MockURLProtocol.requestHandler = { request in
            authorizationHeader = request.value(forHTTPHeaderField: "Authorization")
            XCTAssertEqual(request.url?.lastPathComponent, "reservations-cancel")
            return (try Self.response(status: 204, url: request.url), Data())
        }
        let client = HTTPReservationClient(baseURL: baseURL, urlSession: Self.urlSession())
        try await client.cancelReservation(id: "reservation-1", refreshToken: "refresh-token")
        XCTAssertEqual(authorizationHeader, "Bearer refresh-token")
    }

    func test_modifyReservation_returnsUpdatedConfirmation() async throws {
        let baseURL = try Self.makeURL("https://n8n.test/webhook")
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.lastPathComponent, "reservations-modify")
            let data = Data(
                """
                {
                  "reservationId": "reservation-1",
                  "restaurantName": "Colomba Bistro",
                  "startsAt": "2026-05-03T19:00:00Z",
                  "partySize": 4
                }
                """.utf8
            )
            return (try Self.response(status: 200, url: request.url), data)
        }
        let client = HTTPReservationClient(baseURL: baseURL, urlSession: Self.urlSession())
        let confirmation = try await client.modifyReservation(
            id: "reservation-1",
            slotId: "slot-2",
            partySize: 4,
            specialRequests: "Window",
            refreshToken: "refresh-token"
        )
        XCTAssertEqual(confirmation.reservationId, "reservation-1")
        XCTAssertEqual(confirmation.partySize, 4)
    }

    private static func urlSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func makeURL(_ rawValue: String) throws -> URL {
        guard let url = URL(string: rawValue) else {
            throw TestError.invalidURL
        }
        return url
    }

    private static func response(status: Int, url: URL?) throws -> HTTPURLResponse {
        guard let url, let response = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: nil,
            headerFields: nil
        ) else {
            throw TestError.invalidResponse
        }
        return response
    }
}

private enum TestError: Error {
    case invalidURL
    case invalidResponse
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: TestError.invalidResponse)
            return
        }
        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private struct UnusedReservationHTTPClient: ReservationHTTPClientProtocol {
    func listRestaurants(refreshToken: String) async throws -> [Restaurant] {
        throw ReservationError.server(status: 500)
    }

    func availability(restaurantId: String, date: Date, refreshToken: String) async throws -> [TimeSlot] {
        throw ReservationError.server(status: 500)
    }

    func createReservation(
        _ request: ReservationRequest,
        refreshToken: String
    ) async throws -> ReservationConfirmation {
        throw ReservationError.server(status: 500)
    }

    func listMyReservations(refreshToken: String) async throws -> [Reservation] {
        throw ReservationError.server(status: 500)
    }

    func cancelReservation(id: String, refreshToken: String) async throws {
        throw ReservationError.server(status: 500)
    }

    func modifyReservation(
        id: String,
        slotId: String,
        partySize: Int,
        specialRequests: String?,
        refreshToken: String
    ) async throws -> ReservationConfirmation {
        throw ReservationError.server(status: 500)
    }
}

private final class MockKeychain: KeychainStoring, @unchecked Sendable {
    private var values: [String: String] = [:]

    func setString(_ value: String, forKey key: String) throws { values[key] = value }
    func string(forKey key: String) throws -> String? { values[key] }
    func removeValue(forKey key: String) throws { values.removeValue(forKey: key) }
}
