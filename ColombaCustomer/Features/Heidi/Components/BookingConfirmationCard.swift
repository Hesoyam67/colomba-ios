import ColombaDesign
import SwiftUI

struct BookingConfirmationCard: View {
    @Environment(\.openURL)
    private var openURL

    let confirmation: HeidiBookingConfirmation
    let onConfirm: (HeidiBookingConfirmation) -> Void
    let onModify: (HeidiBookingConfirmation) -> Void
    let onCancel: (HeidiBookingConfirmation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(LocalizedStringKey("heidi.confirmation.book.title"), systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Color.colomba.success)
            Text(confirmation.restaurantName)
                .font(.title3.weight(.semibold))
            Text(
                String(
                    format: String(localized: "heidi.confirmation.details_format"),
                    confirmation.dateText,
                    confirmation.timeText,
                    confirmation.partySize
                )
            )
            .font(.subheadline)
            .foregroundStyle(Color.colomba.text.secondary)
            if let specialRequests = confirmation.specialRequests, specialRequests.isEmpty == false {
                Text(specialRequests)
                    .font(.caption)
                    .foregroundStyle(Color.colomba.text.secondary)
            }
            Label(
                LocalizedStringKey("heidi.confirmation.saved_in_reservations"),
                systemImage: "calendar.badge.checkmark"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.colomba.text.secondary)
            Text(confirmation.id)
                .font(.caption2.monospaced())
                .foregroundStyle(Color.colomba.text.secondary)
            Button {
                openURL(confirmation.reservationDeepLinkURL)
            } label: {
                Label(LocalizedStringKey("heidi.confirmation.view_booking"), systemImage: "arrow.forward.circle")
            }
            .buttonStyle(.bordered)

            HStack {
                Button(LocalizedStringKey("heidi.confirmation.confirm_booking")) {
                    onConfirm(confirmation)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("heidi.booking.confirm.\(confirmation.id)")

                Button(LocalizedStringKey("heidi.confirmation.modify")) {
                    onModify(confirmation)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("heidi.booking.modify.\(confirmation.id)")

                Button(LocalizedStringKey("heidi.confirmation.cancel"), role: .destructive) {
                    onCancel(confirmation)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("heidi.booking.cancel.\(confirmation.id)")
            }
        }
        .padding(12)
        .background(Color.colomba.success.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
