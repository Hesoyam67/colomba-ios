import EventKit
import SwiftUI

public struct ReservationConfirmView: View {
    @Environment(\.dismiss)
    private var dismiss
    @State private var calendarMessage: String?
    private let eventStore = EKEventStore()
    private let confirmation: ReservationConfirmation

    public init(confirmation: ReservationConfirmation) {
        self.confirmation = confirmation
    }

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            VStack(spacing: 8) {
                Text("Reservation confirmed")
                    .font(.title.bold())
                Text(confirmation.restaurantName)
                    .font(.headline)
                Text(formattedDate)
                    .foregroundStyle(.secondary)
                Text("Party of \(confirmation.partySize)")
                    .foregroundStyle(.secondary)
                Text(confirmation.reservationId)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
            if let calendarMessage {
                Text(calendarMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Add to Calendar") {
                Task { await addToCalendar() }
            }
            .buttonStyle(.borderedProminent)
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.bordered)
            Spacer(minLength: 0)
        }
        .padding()
        .navigationBarBackButtonHidden(false)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: currentLanguage.bundleIdentifier)
        return formatter.string(from: confirmation.startsAt)
    }

    private var currentLanguage: AppLanguage {
        Bundle.main.preferredLocalizations.compactMap(AppLanguage.init(rawValue:)).first ?? .en
    }

    private func addToCalendar() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                calendarMessage = "Calendar access denied. Share-sheet fallback is planned."
                return
            }
            let event = EKEvent(eventStore: eventStore)
            event.title = "Reservation at \(confirmation.restaurantName)"
            event.startDate = confirmation.startsAt
            event.endDate = confirmation.startsAt.addingTimeInterval(90 * 60)
            event.notes = "Colomba reservation ID: \(confirmation.reservationId)"
            event.calendar = eventStore.defaultCalendarForNewEvents
            try eventStore.save(event, span: .thisEvent, commit: true)
            calendarMessage = "Added to Calendar."
        } catch {
            calendarMessage = "Calendar export unavailable. Share-sheet fallback is planned."
        }
    }
}
