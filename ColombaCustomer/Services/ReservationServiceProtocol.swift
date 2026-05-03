import Foundation

public protocol ReservationServiceProtocol: Sendable {
    func listRestaurants() async throws -> [Restaurant]
    func availability(restaurantId: String, date: Date) async throws -> [TimeSlot]
    func createReservation(_ request: ReservationRequest) async throws -> ReservationConfirmation
    func listMyReservations() async throws -> [Reservation]
    func cancelReservation(id: String) async throws
    func modifyReservation(
        id: String,
        slotId: String,
        partySize: Int,
        specialRequests: String?
    ) async throws -> ReservationConfirmation
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

public struct Reservation: Sendable, Equatable, Identifiable, Codable {
    public enum Status: String, Sendable, Equatable, Codable {
        case active
        case cancelled
        case completed
    }

    public let id: String
    public let restaurantId: String
    public let restaurantName: String
    public let startsAt: Date
    public let partySize: Int
    public let specialRequests: String?
    public let status: Status
    public let cancelledAt: Date?

    public init(
        id: String,
        restaurantId: String,
        restaurantName: String,
        startsAt: Date,
        partySize: Int,
        specialRequests: String? = nil,
        status: Status,
        cancelledAt: Date? = nil
    ) {
        self.id = id
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.startsAt = startsAt
        self.partySize = partySize
        self.specialRequests = specialRequests
        self.status = status
        self.cancelledAt = cancelledAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "reservationId"
        case restaurantId
        case restaurantName
        case startsAt
        case partySize
        case specialRequests
        case status
        case cancelledAt
    }
}

public extension Reservation {
    var canModify: Bool {
        status == .active && startsAt > Date()
    }
}

public enum ReservationError: Error, Sendable {
    case notAuthenticated
    case slotUnavailable
    case validationFailed(field: String)
    case network(underlying: Error)
    case server(status: Int)
    case alreadyCancelled
    case slotNoLongerAvailable
    case modifyDeadlinePassed
}
