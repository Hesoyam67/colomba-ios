import Foundation

public protocol ReservationHTTPClientProtocol: Sendable {
    func listRestaurants(refreshToken: String) async throws -> [Restaurant]
    func availability(restaurantId: String, date: Date, refreshToken: String) async throws -> [TimeSlot]
    func createReservation(
        _ request: ReservationRequest,
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
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReservationError.server(status: -1)
            }
            switch httpResponse.statusCode {
            case 200..<300:
                return try decoder.decode(type, from: data)
            case 401:
                throw ReservationError.notAuthenticated
            case 409:
                throw ReservationError.slotUnavailable
            case 422:
                let error = try? decoder.decode(ErrorResponse.self, from: data)
                throw ReservationError.validationFailed(field: error?.field ?? "unknown")
            default:
                throw ReservationError.server(status: httpResponse.statusCode)
            }
        } catch let error as ReservationError {
            throw error
        } catch {
            throw ReservationError.network(underlying: error)
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

    enum CodingKeys: String, CodingKey {
        case restaurantId
        case slotId
        case partySize
        case fullName
        case specialRequests
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(restaurantId, forKey: .restaurantId)
        try container.encode(slotId, forKey: .slotId)
        try container.encode(partySize, forKey: .partySize)
        try container.encode(fullName, forKey: .fullName)
        if let specialRequests {
            try container.encode(specialRequests, forKey: .specialRequests)
        } else {
            try container.encodeNil(forKey: .specialRequests)
        }
    }
}

private struct ErrorResponse: Decodable {
    let error: String?
    let field: String?
}
