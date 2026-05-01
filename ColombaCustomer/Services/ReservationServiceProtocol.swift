import Foundation

public protocol ReservationServiceProtocol: Sendable {
    func listRestaurants() async throws -> [Restaurant]
    func availability(restaurantId: String, date: Date) async throws -> [TimeSlot]
    func createReservation(_ request: ReservationRequest) async throws -> ReservationConfirmation
}

public struct Restaurant: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let cuisine: String
    public let address: String
    public let imageURL: URL?

    public init(id: String, name: String, cuisine: String, address: String, imageURL: URL? = nil) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.address = address
        self.imageURL = imageURL
    }
}

public struct TimeSlot: Sendable, Equatable, Hashable, Identifiable, Codable {
    public let id: String
    public let startsAt: Date
    public let durationMinutes: Int

    public init(id: String, startsAt: Date, durationMinutes: Int) {
        self.id = id
        self.startsAt = startsAt
        self.durationMinutes = durationMinutes
    }
}

public struct ReservationRequest: Sendable, Equatable, Codable {
    public let restaurantId: String
    public let slotId: String
    public let partySize: Int
    public let fullName: String
    public let specialRequests: String?

    public init(
        restaurantId: String,
        slotId: String,
        partySize: Int,
        fullName: String,
        specialRequests: String? = nil
    ) {
        self.restaurantId = restaurantId
        self.slotId = slotId
        self.partySize = partySize
        self.fullName = fullName
        self.specialRequests = specialRequests
    }
}

public struct ReservationConfirmation: Sendable, Equatable, Codable {
    public let reservationId: String
    public let restaurantName: String
    public let startsAt: Date
    public let partySize: Int

    public init(reservationId: String, restaurantName: String, startsAt: Date, partySize: Int) {
        self.reservationId = reservationId
        self.restaurantName = restaurantName
        self.startsAt = startsAt
        self.partySize = partySize
    }
}

public enum ReservationError: Error, Sendable {
    case notAuthenticated
    case slotUnavailable
    case validationFailed(field: String)
    case network(underlying: Error)
    case server(status: Int)
}
