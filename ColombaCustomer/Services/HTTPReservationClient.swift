import Foundation

public protocol ReservationHTTPClientProtocol: Sendable {
    func listRestaurants(refreshToken: String) async throws -> [Restaurant]
    func availability(restaurantId: String, date: Date, refreshToken: String) async throws -> [TimeSlot]
    func createReservation(
        _ request: ReservationRequest,
        refreshToken: String
    ) async throws -> ReservationConfirmation
    func listMyReservations(refreshToken: String) async throws -> [Reservation]
    func cancelReservation(id: String, refreshToken: String) async throws
    func modifyReservation(
        id: String,
        slotId: String,
        partySize: Int,
        specialRequests: String?,
        refreshToken: String
    ) async throws -> ReservationConfirmation
}

public struct HTTPReservationClient: ReservationHTTPClientProtocol, Sendable {
    public static let baseURLInfoKey = "ColombaReservationWebhookBaseURL"

    public static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://n8n.colomba.placeholder/webhook") else {
            fatalError("invalid placeholder URL")
        }
        return url
    }()

    private let baseURL: URL
    private let urlSession: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(baseURL: URL = Self.resolvedBaseURL(), urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public static func resolvedBaseURL(bundle: Bundle = .main) -> URL {
        guard
            let rawValue = bundle.object(forInfoDictionaryKey: baseURLInfoKey) as? String,
            rawValue.isEmpty == false,
            rawValue.contains("$(") == false,
            let url = URL(string: rawValue)
        else {
            return defaultBaseURL
        }
        return url
    }

    public func listRestaurants(refreshToken: String) async throws -> [Restaurant] {
        let request = try makeRequest(
            path: "restaurants-list",
            refreshToken: refreshToken,
            body: EmptyRequest()
        )
        let response = try await perform(request, as: RestaurantListResponse.self)
        return response.restaurants
    }

    public func availability(
        restaurantId: String,
        date: Date,
        refreshToken: String
    ) async throws -> [TimeSlot] {
        let body = AvailabilityRequest(restaurantId: restaurantId, date: Self.formattedDay(date))
        let request = try makeRequest(
            path: "reservations-availability",
            refreshToken: refreshToken,
            body: body
        )
        let response = try await perform(request, as: AvailabilityResponse.self)
        return response.slots
    }

    public func createReservation(
        _ request: ReservationRequest,
        refreshToken: String
    ) async throws -> ReservationConfirmation {
        let body = CreateReservationRequest(request: request)
        let urlRequest = try makeRequest(
            path: "reservations-create",
            refreshToken: refreshToken,
            body: body
        )
        return try await perform(urlRequest, as: ReservationConfirmation.self)
    }

    public func listMyReservations(refreshToken: String) async throws -> [Reservation] {
        let request = try makeRequest(
            path: "reservations-list",
            refreshToken: refreshToken,
            body: EmptyRequest()
        )
        let response = try await perform(request, as: ReservationListResponse.self)
        return response.reservations
    }

    public func cancelReservation(id: String, refreshToken: String) async throws {
        let request = try makeRequest(
            path: "reservations-cancel",
            refreshToken: refreshToken,
            body: ReservationIDRequest(reservationId: id)
        )
        try await performEmpty(request)
    }

    public func modifyReservation(
        id: String,
        slotId: String,
        partySize: Int,
        specialRequests: String?,
        refreshToken: String
    ) async throws -> ReservationConfirmation {
        let request = try makeRequest(
            path: "reservations-modify",
            refreshToken: refreshToken,
            body: ModifyReservationRequest(
                reservationId: id,
                slotId: slotId,
                partySize: partySize,
                specialRequests: specialRequests
            )
        )
        return try await perform(request, as: ReservationConfirmation.self)
    }

    private func makeRequest<T: Encodable>(
        path: String,
        refreshToken: String,
        body: T
    ) throws -> URLRequest {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(body)
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReservationError.server(status: -1)
        }
        switch httpResponse.statusCode {
        case 200..<300:
            return try decoder.decode(type, from: data)
        default:
            throw mappedError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    private func performEmpty(_ request: URLRequest) async throws {
        let (data, response) = try await data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReservationError.server(status: -1)
        }
        switch httpResponse.statusCode {
        case 200..<300:
            return
        default:
            throw mappedError(statusCode: httpResponse.statusCode, data: data)
        }
    }

    private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch let error as ReservationError {
            throw error
        } catch {
            throw ReservationError.network(underlying: error)
        }
    }

    private func mappedError(statusCode: Int, data: Data) -> ReservationError {
        let error = try? decoder.decode(ErrorResponse.self, from: data)
        switch statusCode {
        case 401:
            return .notAuthenticated
        case 409:
            return error?.error == "slot_unavailable" ? .slotNoLongerAvailable : .slotUnavailable
        case 410:
            return .alreadyCancelled
        case 422:
            if error?.field == "startsAt" {
                return .modifyDeadlinePassed
            }
            return .validationFailed(field: error?.field ?? "unknown")
        default:
            return .server(status: statusCode)
        }
    }

    private static func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct EmptyRequest: Encodable {}

private struct RestaurantListResponse: Decodable {
    let restaurants: [Restaurant]
}

private struct AvailabilityRequest: Encodable {
    let restaurantId: String
    let date: String
}

private struct AvailabilityResponse: Decodable {
    let slots: [TimeSlot]
}

private struct ReservationListResponse: Decodable {
    let reservations: [Reservation]
}

private struct ReservationIDRequest: Encodable {
    let reservationId: String
}

private struct ModifyReservationRequest: Encodable {
    let reservationId: String
    let slotId: String
    let partySize: Int
    let specialRequests: String?
}

private struct CreateReservationRequest: Encodable {
    let restaurantId: String
    let slotId: String
    let partySize: Int
    let fullName: String
    let specialRequests: String?

    init(request: ReservationRequest) {
        self.restaurantId = request.restaurantId
        self.slotId = request.slotId
        self.partySize = request.partySize
        self.fullName = request.fullName
        self.specialRequests = request.specialRequests
    }
}

private struct ErrorResponse: Decodable {
    let error: String?
    let field: String?
}
