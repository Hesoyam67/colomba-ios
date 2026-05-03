import ColombaDesign
import SwiftUI

struct RestaurantCardInChat: View {
    let restaurant: HeidiRestaurantSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: ColombaSpacing.space1) {
                    Text(restaurant.name)
                        .font(.colomba.bodyLg)
                        .foregroundStyle(Color.colomba.text.primary)
                    Text("\(restaurant.cuisine) • \(restaurant.neighborhood) • \(restaurant.priceRange)")
                        .font(.colomba.caption)
                        .foregroundStyle(Color.colomba.text.secondary)
                }
                Spacer()
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundStyle(Color.colomba.primary)
            }
            Text(restaurant.summary)
                .font(.colomba.bodyMd)
                .foregroundStyle(Color.colomba.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(String(localized: "heidi.restaurant.select")) {}
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityLabel(
                    Text(
                        String(
                            format: NSLocalizedString("heidi.restaurant.select_accessibility", comment: ""),
                            restaurant.name
                        )
                    )
                )
        }
        .padding(ColombaSpacing.space3)
        .background(Color.colomba.bg.raised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
