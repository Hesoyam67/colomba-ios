import ColombaDesign
import SwiftUI

struct MessageBubble: View {
    let message: HeidiChatMessage
    let onRestaurantDetails: (HeidiRestaurantCard) -> Void
    let onConfirmBooking: (HeidiBookingConfirmation) -> Void
    let onModifyBooking: (HeidiBookingConfirmation) -> Void
    let onCancelBooking: (HeidiBookingConfirmation) -> Void

    init(
        message: HeidiChatMessage,
        onRestaurantDetails: @escaping (HeidiRestaurantCard) -> Void = { _ in },
        onConfirmBooking: @escaping (HeidiBookingConfirmation) -> Void = { _ in },
        onModifyBooking: @escaping (HeidiBookingConfirmation) -> Void = { _ in },
        onCancelBooking: @escaping (HeidiBookingConfirmation) -> Void = { _ in }
    ) {
        self.message = message
        self.onRestaurantDetails = onRestaurantDetails
        self.onConfirmBooking = onConfirmBooking
        self.onModifyBooking = onModifyBooking
        self.onCancelBooking = onCancelBooking
    }

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 48) }
            VStack(alignment: .leading, spacing: 10) {
                if message.text.isEmpty == false {
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(message.role == .user ? .white : Color.colomba.text.primary)
                }
                ForEach(message.restaurantCards) { card in
                    RestaurantCardInChat(card: card, onViewDetails: onRestaurantDetails)
                }
                if let confirmation = message.bookingConfirmation {
                    BookingConfirmationCard(
                        confirmation: confirmation,
                        onConfirm: onConfirmBooking,
                        onModify: onModifyBooking,
                        onCancel: onCancelBooking
                    )
                }
            }
            .padding(14)
            .background(message.role == .user ? Color.colomba.primary : Color.colomba.bg.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(message.role == .user ? 0 : 0.06), radius: 8, y: 2)
            if message.role == .assistant { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .combine)
    }
}
