import Foundation

public final class MockReservationClient: ReservationServiceProtocol, @unchecked Sendable {
    public var restaurantsResult: Result<[Restaurant], Error>
    public var availabilityResult: Result<[TimeSlot], Error>
    public var createReservationResult: Result<ReservationConfirmation, Error>
    public private(set) var lastReservationRequest: ReservationRequest?

    public init(
        restaurants: [Restaurant] = [],
        slots: [TimeSlot] = [],
        confirmation: ReservationConfirmation? = nil
    ) {
        self.restaurantsResult = .success(restaurants)
        self.availabilityResult = .success(slots)
        self.createReservationResult = .success(
            confirmation ?? ReservationConfirmation(
                reservationId: "mock-reservation",
                restaurantName: restaurants.first?.name ?? "Mock Restaurant",
                startsAt: slots.first?.startsAt ?? Date(),
                partySize: 2
            )
        )
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
}
