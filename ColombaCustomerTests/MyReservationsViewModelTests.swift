@testable import ColombaCustomer
import XCTest

@MainActor
final class MyReservationsViewModelTests: XCTestCase {
    func test_filteredReservations_upcoming_excludesPast() async {
        let model = makeModel(reservations: [Self.upcoming, Self.past])
        await model.loadReservations()
        model.filter = .upcoming
        XCTAssertEqual(model.filteredReservations, [Self.upcoming])
    }

    func test_filteredReservations_past_includesCancelled() async {
        let model = makeModel(reservations: [Self.upcoming, Self.cancelled])
        await model.loadReservations()
        model.filter = .past
        XCTAssertEqual(model.filteredReservations, [Self.cancelled])
    }

    func test_filteredReservations_past_includesCompleted() async {
        let model = makeModel(reservations: [Self.upcoming, Self.completed])
        await model.loadReservations()
        model.filter = .past
        XCTAssertEqual(model.filteredReservations, [Self.completed])
    }

    func test_filteredReservations_upcoming_excludesCancelled() async {
        let model = makeModel(reservations: [Self.upcoming, Self.cancelled])
        await model.loadReservations()
        model.filter = .upcoming
        XCTAssertEqual(model.filteredReservations, [Self.upcoming])
    }

    func test_loadReservations_idleToLoadingToLoaded() async {
        let model = makeModel(reservations: [Self.upcoming])
        await model.loadReservations()
        XCTAssertEqual(model.phase, .loaded)
        XCTAssertEqual(model.reservations, [Self.upcoming])
    }

    func test_cancel_successUpdatesStatus() async {
        let model = makeModel(reservations: [Self.upcoming])
        await model.loadReservations()
        await model.cancel(Self.upcoming)
        XCTAssertEqual(model.reservations.first?.status, .cancelled)
        XCTAssertEqual(model.phase, .loaded)
    }

    func test_cancel_alreadyCancelled_logsButDoesNotFail() async {
        let service = MockReservationClient(reservations: [Self.upcoming])
        service.cancelReservationResult = .failure(ReservationError.alreadyCancelled)
        let model = MyReservationsViewModel(service: service, now: { Self.now })
        await model.loadReservations()
        await model.cancel(Self.upcoming)
        XCTAssertEqual(model.phase, .loaded)
        XCTAssertEqual(model.reservations.first?.status, .cancelled)
    }

    func test_modify_successUpdatesReservation() async {
        let confirmation = ReservationConfirmation(
            reservationId: "reservation-upcoming",
            restaurantName: "Updated Bistro",
            startsAt: Self.now.addingTimeInterval(172_800),
            partySize: 4
        )
        let service = MockReservationClient(reservations: [Self.upcoming])
        service.modifyReservationResult = .success(confirmation)
        let model = MyReservationsViewModel(service: service, now: { Self.now })
        await model.loadReservations()
        await model.modify(Self.upcoming, newSlotId: "slot-2", newPartySize: 4, newSpecialRequests: "Window")
        XCTAssertEqual(model.phase, .loaded)
        XCTAssertEqual(model.reservations.first?.restaurantName, "Updated Bistro")
        XCTAssertEqual(model.reservations.first?.partySize, 4)
    }

    func test_modify_slotNoLongerAvailable_transitionsToFailed() async {
        let service = MockReservationClient(reservations: [Self.upcoming])
        service.modifyReservationResult = .failure(ReservationError.slotNoLongerAvailable)
        let model = MyReservationsViewModel(service: service, now: { Self.now })
        await model.loadReservations()
        await model.modify(Self.upcoming, newSlotId: "slot-2", newPartySize: 2, newSpecialRequests: nil)
        assertFailed(model.phase, expectedReason: "That time slot is no longer available.")
    }

    func test_modify_deadlinePassed_transitionsToFailed() async {
        let service = MockReservationClient(reservations: [Self.upcoming])
        service.modifyReservationResult = .failure(ReservationError.modifyDeadlinePassed)
        let model = MyReservationsViewModel(service: service, now: { Self.now })
        await model.loadReservations()
        await model.modify(Self.upcoming, newSlotId: "slot-2", newPartySize: 2, newSpecialRequests: nil)
        assertFailed(model.phase, expectedReason: "Reservations can only be modified before they start.")
    }

    private static let now = Date(timeIntervalSince1970: 1_800_000_000)

    private static let upcoming = Reservation(
        id: "reservation-upcoming",
        restaurantId: "restaurant-1",
        restaurantName: "Colomba Bistro",
        startsAt: now.addingTimeInterval(86_400),
        partySize: 2,
        status: .active
    )

    private static let past = Reservation(
        id: "reservation-past",
        restaurantId: "restaurant-1",
        restaurantName: "Colomba Bistro",
        startsAt: now.addingTimeInterval(-86_400),
        partySize: 2,
        status: .active
    )

    private static let cancelled = Reservation(
        id: "reservation-cancelled",
        restaurantId: "restaurant-1",
        restaurantName: "Colomba Bistro",
        startsAt: now.addingTimeInterval(86_400),
        partySize: 2,
        status: .cancelled,
        cancelledAt: now
    )

    private static let completed = Reservation(
        id: "reservation-completed",
        restaurantId: "restaurant-1",
        restaurantName: "Colomba Bistro",
        startsAt: now.addingTimeInterval(-86_400),
        partySize: 2,
        status: .completed
    )

    private func makeModel(reservations: [Reservation]) -> MyReservationsViewModel {
        MyReservationsViewModel(
            service: MockReservationClient(reservations: reservations),
            now: { Self.now }
        )
    }

    private func assertFailed(_ phase: MyReservationsViewModel.Phase, expectedReason: String) {
        guard case let .failed(reason) = phase else {
            XCTFail("Expected failed phase")
            return
        }
        XCTAssertEqual(reason, expectedReason)
    }
}
