import Foundation

public final class MockReservationClient: ReservationServiceProtocol, @unchecked Sendable {
    public var restaurantsResult: Result<[Restaurant], Error>
    public var availabilityResult: Result<[TimeSlot], Error>
    public var createReservationResult: Result<ReservationConfirmation, Error>
    public var listMyReservationsResult: Result<[Reservation], Error>
    public var cancelReservationResult: Result<Void, Error>
    public var modifyReservationResult: Result<ReservationConfirmation, Error>
    public private(set) var lastReservationRequest: ReservationRequest?
    public private(set) var lastCancelledReservationId: String?
    public private(set) var lastModifyRequest: ModifyReservationCall?

    public init(
        restaurants: [Restaurant] = [],
        slots: [TimeSlot] = [],
        confirmation: ReservationConfirmation? = nil,
        reservations: [Reservation] = []
    ) {
        let defaultConfirmation = confirmation ?? ReservationConfirmation(
            reservationId: "mock-reservation",
            restaurantName: restaurants.first?.name ?? "Mock Restaurant",
            startsAt: slots.first?.startsAt ?? Date(),
            partySize: 2
        )
        self.restaurantsResult = .success(restaurants)
        self.availabilityResult = .success(slots)
        self.createReservationResult = .success(defaultConfirmation)
        self.listMyReservationsResult = .success(reservations)
        self.cancelReservationResult = .success(())
        self.modifyReservationResult = .success(defaultConfirmation)
    }

    public func listRestaurants() async throws -> [Restaurant] {
        try restaurantsResult.get()
    }

    public func availability(restaurantId: String, date: Date) async throws -> [TimeSlot] {
        try availabilityResult.get()
    }

    public func createReservation(_ request: ReservationRequest) async throws -> ReservationConfirmation {
        lastReservationRequest = request
        return try createReservationResult.get()
    }

    public func listMyReservations() async throws -> [Reservation] {
        try listMyReservationsResult.get()
    }

    public func cancelReservation(id: String) async throws {
        lastCancelledReservationId = id
        try cancelReservationResult.get()
    }

    public func modifyReservation(
        id: String,
        slotId: String,
        partySize: Int,
        specialRequests: String?
    ) async throws -> ReservationConfirmation {
        lastModifyRequest = ModifyReservationCall(
            id: id,
            slotId: slotId,
            partySize: partySize,
            specialRequests: specialRequests
        )
        return try modifyReservationResult.get()
    }
}

public struct ModifyReservationCall: Sendable, Equatable {
    public let id: String
    public let slotId: String
    public let partySize: Int
    public let specialRequests: String?
}
