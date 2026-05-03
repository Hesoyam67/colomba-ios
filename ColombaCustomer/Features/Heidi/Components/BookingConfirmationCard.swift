import ColombaDesign
import SwiftUI

struct BookingConfirmationCard: View {
    let confirmation: HeidiBookingConfirmation

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
            Button(LocalizedStringKey("heidi.confirmation.view_booking")) {
                // Deep-link placeholder for mock scaffold.
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color.colomba.success.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
