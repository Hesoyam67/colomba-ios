import Foundation
import SwiftUI

@MainActor
public final class ReservationViewModel: ObservableObject {
    public enum Phase: Equatable {
        case idle
        case loadingRestaurants
        case restaurantsLoaded
        case loadingAvailability
        case availabilityLoaded
        case submitting
        case confirmed(ReservationConfirmation)
        case failed(reason: String)
    }

    @Published public private(set) var phase: Phase = .idle
    @Published public private(set) var restaurants: [Restaurant] = []
    @Published public private(set) var availableSlots: [TimeSlot] = []
    @Published public var selectedDate: Date
    @Published public var selectedSlot: TimeSlot?
    @Published public var partySize: Int = 2
    @Published public var fullName: String
    @Published public var specialRequests: String = ""

    private let service: ReservationServiceProtocol
    private let calendar: Calendar

    public var canConfirm: Bool {
        let localMidnight = calendar.startOfDay(for: Date())
        let selectedMidnight = calendar.startOfDay(for: selectedDate)
        guard selectedMidnight >= localMidnight else { return false }
        guard let selectedSlot, availableSlots.contains(selectedSlot) else { return false }
        guard (1...12).contains(partySize) else { return false }
        guard fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return false
        }
        return specialRequests.utf8.count <= 500
    }

    public init(
        service: ReservationServiceProtocol,
        prefilledName: String,
        calendar: Calendar = .current
    ) {
        self.service = service
        self.calendar = calendar
        self.fullName = prefilledName
        let today = calendar.startOfDay(for: Date())
        self.selectedDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    public func loadRestaurants() async {
        phase = .loadingRestaurants
        do {
            restaurants = try await service.listRestaurants()
            phase = .restaurantsLoaded
        } catch {
            phase = .failed(reason: Self.userMessage(for: error))
        }
    }

    public func loadAvailability(for restaurant: Restaurant, on date: Date) async {
        phase = .loadingAvailability
        do {
            let slots = try await service.availability(restaurantId: restaurant.id, date: date)
            availableSlots = slots
            if let selectedSlot, slots.contains(selectedSlot) == false {
                self.selectedSlot = nil
            }
            phase = .availabilityLoaded
        } catch {
            availableSlots = []
            selectedSlot = nil
            phase = .failed(reason: Self.userMessage(for: error))
        }
    }

    public func submit(restaurant: Restaurant) async {
        guard canConfirm, let selectedSlot else {
            phase = .failed(reason: "Please complete the reservation details")
            return
        }
        phase = .submitting
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRequests = specialRequests.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = ReservationRequest(
            restaurantId: restaurant.id,
            slotId: selectedSlot.id,
            partySize: partySize,
            fullName: trimmedName,
            specialRequests: trimmedRequests.isEmpty ? nil : trimmedRequests
        )
        do {
            let confirmation = try await service.createReservation(request)
            phase = .confirmed(confirmation)
        } catch {
            phase = .failed(reason: Self.userMessage(for: error))
        }
    }

    public func reset() {
        phase = .idle
        restaurants = []
        availableSlots = []
        selectedSlot = nil
        partySize = 2
        specialRequests = ""
        let today = calendar.startOfDay(for: Date())
        selectedDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    private static func userMessage(for error: Error) -> String {
        guard let reservationError = error as? ReservationError else {
            return "Reservation service unavailable"
        }
        switch reservationError {
        case .notAuthenticated:
            return "Please verify your phone again"
        case .slotUnavailable:
            return "Slot unavailable"
        case let .validationFailed(field):
            return "Invalid reservation field: \(field)"
        case .network:
            return "Network error"
        case let .server(status):
            return "Reservation server error (\(status))"
        }
    }
}
