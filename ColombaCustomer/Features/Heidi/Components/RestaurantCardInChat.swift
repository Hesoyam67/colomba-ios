import ColombaDesign
import SwiftUI

struct RestaurantCardInChat: View {
    let card: HeidiRestaurantCard
    let onViewDetails: (HeidiRestaurantCard) -> Void

    init(card: HeidiRestaurantCard, onViewDetails: @escaping (HeidiRestaurantCard) -> Void = { _ in }) {
        self.card = card
        self.onViewDetails = onViewDetails
    }

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
                onViewDetails(card)
            } label: {
                Label(LocalizedStringKey("heidi.card.view_details"), systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("heidi.restaurant.viewDetails.\(card.id)")
        }
        .padding(12)
        .background(Color.colomba.bg.base)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
