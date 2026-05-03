import ColombaDesign
import SwiftUI

struct RestaurantCardInChat: View {
    let card: HeidiRestaurantCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name)
                        .font(.headline)
                    Text("\(card.cuisine) • \(card.neighborhood) • \(card.priceRange)")
                        .font(.caption)
                        .foregroundStyle(Color.colomba.text.secondary)
                }
                Spacer()
                Text(card.nextAvailableTime)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.colomba.primary)
            }
            Text(card.shortDescription)
                .font(.subheadline)
                .foregroundStyle(Color.colomba.text.secondary)
            Button {
                // Mock-only scaffold: live booking action will route through Heidi backend in Lane 2.
            } label: {
                Label(LocalizedStringKey("heidi.card.check_availability"), systemImage: "clock")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(Color.colomba.bg.base)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
