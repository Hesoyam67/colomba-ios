import Foundation

public final class HeidiService: HeidiServiceProtocol, @unchecked Sendable {
    public enum Mode: Sendable {
        case mock
    }

    private let mode: Mode

    public init(mode: Mode = .mock) {
        self.mode = mode
    }

    public func sendMessage(
        _ text: String,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        switch mode {
        case .mock:
            return mockStream(for: text, history: history)
        }
    }

    private func mockStream(
        for text: String,
        history: [HeidiChatMessage]
    ) -> AsyncThrowingStream<HeidiResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let lowercased = text.lowercased()
                if lowercased.contains("error") {
                    continuation.finish(throwing: HeidiMockError.requestFailed)
                    return
                }

                let delay: UInt64 = 20_000_000
                if lowercased.contains("cancel") {
                    continuation.yield(
                        .text("I can help cancel bookings. In the live flow I would ask you to confirm first.")
                    )
                } else if lowercased.contains("change") || lowercased.contains("modify") {
                    continuation.yield(.text("I found your booking and can move it to 20:00 if you confirm."))
                } else if lowercased.contains("book") || lowercased.contains("confirm") {
                    continuation.yield(.text("Perfect — I booked this for you."))
                    try? await Task.sleep(nanoseconds: delay)
                    continuation.yield(.bookingConfirmation(Self.mockConfirmation))
                } else {
                    continuation.yield(.text("Here are a few places I found for you."))
                    try? await Task.sleep(nanoseconds: delay)
                    continuation.yield(.restaurantCards(Self.mockRestaurants))
                }
                continuation.yield(.done)
                continuation.finish()
            }
        }
    }

    public static let mockRestaurants: [HeidiRestaurantCard] = [
        HeidiRestaurantCard(
            id: "bellini",
            name: "Bellini Zürich",
            cuisine: "Italian",
            neighborhood: "Seefeld",
            priceRange: "$$$",
            nextAvailableTime: "19:30",
            shortDescription: "Elegant pasta, warm lighting, good vegetarian options."
        ),
        HeidiRestaurantCard(
            id: "lindenhof",
            name: "Lindenhof Stube",
            cuisine: "Swiss",
            neighborhood: "Altstadt",
            priceRange: "$$",
            nextAvailableTime: "20:00",
            shortDescription: "Classic Swiss plates near the old town viewpoint."
        ),
        HeidiRestaurantCard(
            id: "limmat",
            name: "Limmat Garden",
            cuisine: "Modern European",
            neighborhood: "Kreis 5",
            priceRange: "$$",
            nextAvailableTime: "18:45",
            shortDescription: "Casual seasonal menu with terrace seating."
        )
    ]

    public static let mockConfirmation = HeidiBookingConfirmation(
        id: "BK-HEIDI-001",
        restaurantName: "Bellini Zürich",
        dateText: "Saturday",
        timeText: "19:30",
        partySize: 4,
        specialRequests: "Vegetarian options"
    )
}

public enum HeidiMockError: Error, Sendable, Equatable {
    case requestFailed
}
