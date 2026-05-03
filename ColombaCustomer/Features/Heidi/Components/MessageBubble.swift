import ColombaDesign
import SwiftUI

struct MessageBubble: View {
    let message: HeidiMessage

    var body: some View {
        HStack {
            if message.sender == .user { Spacer(minLength: ColombaSpacing.space8) }
            VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
                if message.text.isEmpty == false {
                    Text(message.text)
                        .font(.colomba.bodyMd)
                        .foregroundStyle(foregroundColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(message.cards) { card in
                    switch card {
                    case let .restaurant(restaurant):
                        RestaurantCardInChat(restaurant: restaurant)
                    case let .bookingConfirmation(confirmation):
                        BookingConfirmationCard(confirmation: confirmation)
                    }
                }
            }
            .padding(ColombaSpacing.space4)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.colomba.border.hairline, lineWidth: message.sender == .assistant ? 1 : 0)
            )
            if message.sender == .assistant { Spacer(minLength: ColombaSpacing.space8) }
        }
        .accessibilityElement(children: .combine)
    }

    private var backgroundColor: Color {
        message.sender == .user ? Color.colomba.primary : Color.colomba.bg.card
    }

    private var foregroundColor: Color {
        message.sender == .user ? .white : Color.colomba.text.primary
    }
}
