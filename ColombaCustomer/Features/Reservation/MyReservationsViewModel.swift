import Foundation

@MainActor
public final class MyReservationsViewModel: ObservableObject {
    public enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case cancelling(reservationId: String)
        case modifying(reservationId: String)
        case failed(reason: String)
    }

    public enum Filter: Equatable {
        case upcoming
        case past
    }

    @Published public private(set) var phase: Phase = .idle
    @Published public private(set) var reservations: [Reservation] = []
    @Published public var filter: Filter = .upcoming

    private let service: ReservationServiceProtocol
    private let now: () -> Date

    public var filteredReservations: [Reservation] {
        let currentDate = now()
        return reservations
            .filter { reservation in
                switch filter {
                case .upcoming:
                    reservation.status == .active && reservation.startsAt > currentDate
                case .past:
                    reservation.status != .active || reservation.startsAt <= currentDate
                }
            }
            .sorted { lhs, rhs in
                switch filter {
                case .upcoming:
                    lhs.startsAt < rhs.startsAt
                case .past:
                    lhs.startsAt > rhs.startsAt
                }
            }
    }

    public init(service: ReservationServiceProtocol, now: @escaping () -> Date = Date.init) {
        self.service = service
        self.now = now
    }

    public func loadReservations() async {
        phase = .loading
        do {
            reservations = try await service.listMyReservations()
            phase = .loaded
        } catch {
            phase = .failed(reason: Self.userMessage(for: error))
        }
    }

    public func refresh() async {
        await loadReservations()
    }

    public func cancel(_ reservation: Reservation) async {
        phase = .cancelling(reservationId: reservation.id)
        do {
            try await service.cancelReservation(id: reservation.id)
            markCancelled(reservationId: reservation.id, cancelledAt: now())
            phase = .loaded
        } catch ReservationError.alreadyCancelled {
            markCancelled(reservationId: reservation.id, cancelledAt: reservation.cancelledAt ?? now())
            phase = .loaded
        } catch {
            phase = .failed(reason: Self.userMessage(for: error))
        }
    }

    public func modify(
        _ reservation: Reservation,
        newSlotId: String,
        newPartySize: Int,
        newSpecialRequests: String?
    ) async {
        phase = .modifying(reservationId: reservation.id)
        do {
            let confirmation = try await service.modifyReservation(
                id: reservation.id,
                slotId: newSlotId,
                partySize: newPartySize,
                specialRequests: newSpecialRequests
            )
            replaceReservation(reservation, with: confirmation, specialRequests: newSpecialRequests)
            phase = .loaded
        } catch {
            phase = .failed(reason: Self.userMessage(for: error))
        }
    }

    public func applyModifiedReservation(
        _ reservation: Reservation,
        confirmation: ReservationConfirmation,
        specialRequests: String?
    ) {
        replaceReservation(reservation, with: confirmation, specialRequests: specialRequests)
        phase = .loaded
    }

    private func markCancelled(reservationId: String, cancelledAt: Date) {
        reservations = reservations.map { reservation in
            guard reservation.id == reservationId else { return reservation }
            return Reservation(
                id: reservation.id,
                restaurantId: reservation.restaurantId,
                restaurantName: reservation.restaurantName,
                startsAt: reservation.startsAt,
                partySize: reservation.partySize,
                specialRequests: reservation.specialRequests,
                status: .cancelled,
                cancelledAt: cancelledAt
            )
        }
    }

    private func replaceReservation(
        _ reservation: Reservation,
        with confirmation: ReservationConfirmation,
        specialRequests: String?
    ) {
        reservations = reservations.map { item in
            guard item.id == reservation.id else { return item }
            return Reservation(
                id: confirmation.reservationId,
                restaurantId: item.restaurantId,
                restaurantName: confirmation.restaurantName,
                startsAt: confirmation.startsAt,
                partySize: confirmation.partySize,
                specialRequests: specialRequests,
                status: .active,
                cancelledAt: nil
            )
        }
    }

    private static func userMessage(for error: Error) -> String {
        guard let reservationError = error as? ReservationError else {
            return "Reservation service unavailable"
        }
        switch reservationError {
        case .notAuthenticated:
            return "Please verify your phone again"
        case .slotUnavailable, .slotNoLongerAvailable:
            return String(localized: "reservation.error.slotNoLongerAvailable")
        case let .validationFailed(field):
            return "Invalid reservation field: \(field)"
        case .network:
            return "Network error"
        case let .server(status):
            return "Reservation server error (\(status))"
        case .alreadyCancelled:
            return String(localized: "reservation.error.alreadyCancelled")
        case .modifyDeadlinePassed:
            return String(localized: "reservation.error.modifyDeadlinePassed")
        }
    }
}
