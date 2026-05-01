@testable import ColombaCustomer
import XCTest

@MainActor
final class ReservationViewModelTests: XCTestCase {
    func test_canConfirm_falseWhenDateInPast() async {
        let model = await configuredModel()
        model.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        XCTAssertFalse(model.canConfirm)
    }

    func test_canConfirm_falseWhenSlotNil() async {
        let model = await configuredModel()
        model.selectedSlot = nil
        XCTAssertFalse(model.canConfirm)
    }

    func test_canConfirm_falseWhenPartySizeBelowOne() async {
        let model = await configuredModel()
        model.partySize = 0
        XCTAssertFalse(model.canConfirm)
    }

    func test_canConfirm_falseWhenPartySizeAboveTwelve() async {
        let model = await configuredModel()
        model.partySize = 13
        XCTAssertFalse(model.canConfirm)
    }

    func test_canConfirm_falseWhenNameEmpty() async {
        let model = await configuredModel()
        model.fullName = "   "
        XCTAssertFalse(model.canConfirm)
    }

    func test_canConfirm_trueWhenAllValid() async {
        let model = await configuredModel()
        XCTAssertTrue(model.canConfirm)
    }

    func test_loadRestaurants_idleToLoadingToLoaded() async {
        let service = MockReservationClient(restaurants: [Self.restaurant], slots: [Self.slot])
        let model = ReservationViewModel(service: service, prefilledName: "Papu")
        await model.loadRestaurants()
        XCTAssertEqual(model.phase, .restaurantsLoaded)
        XCTAssertEqual(model.restaurants, [Self.restaurant])
    }

    func test_loadAvailability_setsAvailableSlots() async {
        let model = await configuredModel()
        XCTAssertEqual(model.availableSlots, [Self.slot])
    }

    func test_submit_successTransitionsToConfirmed() async {
        let confirmation = ReservationConfirmation(
            reservationId: "reservation-1",
            restaurantName: Self.restaurant.name,
            startsAt: Self.slot.startsAt,
            partySize: 2
        )
        let service = MockReservationClient(
            restaurants: [Self.restaurant],
            slots: [Self.slot],
            confirmation: confirmation
        )
        let model = ReservationViewModel(service: service, prefilledName: "Papu")
        await model.loadAvailability(for: Self.restaurant, on: model.selectedDate)
        model.selectedSlot = Self.slot
        await model.submit(restaurant: Self.restaurant)
        XCTAssertEqual(model.phase, .confirmed(confirmation))
    }

    func test_submit_slotUnavailable_transitionsToFailed() async {
        let service = MockReservationClient(restaurants: [Self.restaurant], slots: [Self.slot])
        service.createReservationResult = .failure(ReservationError.slotUnavailable)
        let model = ReservationViewModel(service: service, prefilledName: "Papu")
        await model.loadAvailability(for: Self.restaurant, on: model.selectedDate)
        model.selectedSlot = Self.slot
        await model.submit(restaurant: Self.restaurant)
        assertFailed(model.phase, expectedReason: "Slot unavailable")
    }

    func test_submit_notAuthenticated_transitionsToFailed() async {
        let service = MockReservationClient(restaurants: [Self.restaurant], slots: [Self.slot])
        service.createReservationResult = .failure(ReservationError.notAuthenticated)
        let model = ReservationViewModel(service: service, prefilledName: "Papu")
        await model.loadAvailability(for: Self.restaurant, on: model.selectedDate)
        model.selectedSlot = Self.slot
        await model.submit(restaurant: Self.restaurant)
        assertFailed(model.phase, expectedReason: "Please verify your phone again")
    }

    func test_reset_returnsToIdle() async {
        let model = await configuredModel()
        model.reset()
        XCTAssertEqual(model.phase, .idle)
        XCTAssertNil(model.selectedSlot)
        XCTAssertEqual(model.partySize, 2)
    }

    private static let restaurant = Restaurant(
        id: "restaurant-1",
        name: "Colomba Bistro",
        cuisine: "Swiss",
        address: "Bahnhofstrasse 1, Zürich"
    )

    private static let slot = TimeSlot(
        id: "slot-1",
        startsAt: Date().addingTimeInterval(86_400),
        durationMinutes: 90
    )

    private func configuredModel() async -> ReservationViewModel {
        let service = MockReservationClient(restaurants: [Self.restaurant], slots: [Self.slot])
        let model = ReservationViewModel(service: service, prefilledName: "Papu")
        await model.loadAvailability(for: Self.restaurant, on: model.selectedDate)
        model.selectedSlot = Self.slot
        return model
    }

    private func assertFailed(_ phase: ReservationViewModel.Phase, expectedReason: String) {
        guard case let .failed(reason) = phase else {
            XCTFail("Expected failed phase")
            return
        }
        XCTAssertEqual(reason, expectedReason)
    }
}
