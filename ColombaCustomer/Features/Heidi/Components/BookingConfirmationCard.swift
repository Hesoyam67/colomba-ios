import ColombaDesign
import SwiftUI

struct BookingConfirmationCard: View {
    let confirmation: HeidiBookingConfirmation

    var body: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
            Label(String(localized: "heidi.confirmation.book.title"), systemImage: "checkmark.seal.fill")
                .font(.colomba.bodyLg)
                .foregroundStyle(Color.colomba.success)
            VStack(alignment: .leading, spacing: ColombaSpacing.space1) {
                Text(confirmation.restaurantName)
                    .font(.colomba.bodyLg)
                    .foregroundStyle(Color.colomba.text.primary)
                Text("\(confirmation.dateText) • \(confirmation.timeText) • \(confirmation.partySize) guests")
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)
                Text(confirmation.status)
                    .font(.colomba.caption)
                    .foregroundStyle(Color.colomba.text.tertiary)
            }
            HStack {
                Button(String(localized: "heidi.confirmation.view_booking")) {}
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button(String(localized: "heidi.confirmation.confirm")) {}
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(ColombaSpacing.space3)
        .background(Color.colomba.bg.raised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
