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
                Text("reservation.confirmed")
                    .font(.title.bold())
                Text(confirmation.restaurantName)
                    .font(.headline)
                Text(formattedDate)
                    .foregroundStyle(.secondary)
                Text(partyText)
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
            Button(String(localized: "reservation.add_to_calendar")) {
                Task { await addToCalendar() }
            }
            .buttonStyle(.borderedProminent)
            Button(String(localized: "reservation.done")) {
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

    /// Format: reservation.party_of_format contains one integer party size.
    private var partyText: String {
        String(format: NSLocalizedString("reservation.party_of_format", comment: ""), confirmation.partySize)
    }

    /// Format: reservation.calendar_title_format contains one restaurant name.
    private var calendarTitle: String {
        String(format: NSLocalizedString("reservation.calendar_title_format", comment: ""), confirmation.restaurantName)
    }

    /// Format: reservation.calendar_notes_format contains one reservation ID.
    private var calendarNotes: String {
        String(format: NSLocalizedString("reservation.calendar_notes_format", comment: ""), confirmation.reservationId)
    }

    private func addToCalendar() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                calendarMessage = String(localized: "reservation.calendar_denied")
                return
            }
            let event = EKEvent(eventStore: eventStore)
            event.title = calendarTitle
            event.startDate = confirmation.startsAt
            event.endDate = confirmation.startsAt.addingTimeInterval(90 * 60)
            event.notes = calendarNotes
            event.calendar = eventStore.defaultCalendarForNewEvents
            try eventStore.save(event, span: .thisEvent, commit: true)
            calendarMessage = String(localized: "reservation.calendar_added")
        } catch {
            calendarMessage = String(localized: "reservation.calendar_unavailable")
        }
    }
}
