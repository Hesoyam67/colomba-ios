import Foundation

public protocol HeidiServiceProtocol: Sendable {
    func sendMessage(
        _ text: String,
        history: [HeidiMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error>
}

public enum ChatPhase: Sendable, Equatable {
    case idle
    case sending
    case streaming
    case failed(String)
}

public struct HeidiMessage: Sendable, Equatable, Identifiable, Codable {
    public enum Sender: String, Sendable, Codable {
        case user
        case assistant
    }

    public var id: UUID
    public var sender: Sender
    public var text: String
    public var cards: [HeidiCard]
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        sender: Sender,
        text: String,
        cards: [HeidiCard] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.cards = cards
        self.createdAt = createdAt
    }
}

public enum HeidiResponse: Sendable, Equatable, Codable {
    case thinking
    case text(String)
    case restaurantResults([HeidiRestaurantSuggestion])
    case bookingConfirmation(HeidiBookingConfirmation)
    case done
}

public enum HeidiCard: Sendable, Equatable, Codable, Identifiable {
    case restaurant(HeidiRestaurantSuggestion)
    case bookingConfirmation(HeidiBookingConfirmation)

    public var id: String {
        switch self {
        case let .restaurant(restaurant):
            return "restaurant-\(restaurant.id)"
        case let .bookingConfirmation(confirmation):
            return "booking-\(confirmation.bookingId)"
        }
    }
}

public struct HeidiRestaurantSuggestion: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let cuisine: String
    public let neighborhood: String
    public let priceRange: String
    public let summary: String

    public init(
        id: String,
        name: String,
        cuisine: String,
        neighborhood: String,
        priceRange: String,
        summary: String
    ) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.neighborhood = neighborhood
        self.priceRange = priceRange
        self.summary = summary
    }
}

public struct HeidiBookingConfirmation: Sendable, Equatable, Identifiable, Codable {
    public var id: String { bookingId }

    public let bookingId: String
    public let restaurantName: String
    public let dateText: String
    public let timeText: String
    public let partySize: Int
    public let status: String

    public init(
        bookingId: String,
        restaurantName: String,
        dateText: String,
        timeText: String,
        partySize: Int,
        status: String
    ) {
        self.bookingId = bookingId
        self.restaurantName = restaurantName
        self.dateText = dateText
        self.timeText = timeText
        self.partySize = partySize
        self.status = status
    }
}
