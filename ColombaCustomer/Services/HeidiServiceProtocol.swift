import Foundation

public protocol HeidiServiceProtocol: Sendable {
    func sendMessage(
        _ text: String,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error>
}

public enum HeidiMessageRole: String, Sendable, Equatable, Codable {
    case user
    case assistant
}

public struct HeidiChatMessage: Sendable, Equatable, Identifiable, Codable {
    public let id: UUID
    public let role: HeidiMessageRole
    public var text: String
    public let createdAt: Date
    public var restaurantCards: [HeidiRestaurantCard]
    public var bookingConfirmation: HeidiBookingConfirmation?

    public init(
        id: UUID = UUID(),
        role: HeidiMessageRole,
        text: String,
        createdAt: Date = Date(),
        restaurantCards: [HeidiRestaurantCard] = [],
        bookingConfirmation: HeidiBookingConfirmation? = nil
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.restaurantCards = restaurantCards
        self.bookingConfirmation = bookingConfirmation
    }
}

public struct HeidiRestaurantCard: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let name: String
    public let cuisine: String
    public let neighborhood: String
    public let priceRange: String
    public let nextAvailableTime: String
    public let shortDescription: String

    public init(
        id: String,
        name: String,
        cuisine: String,
        neighborhood: String,
        priceRange: String,
        nextAvailableTime: String,
        shortDescription: String
    ) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.neighborhood = neighborhood
        self.priceRange = priceRange
        self.nextAvailableTime = nextAvailableTime
        self.shortDescription = shortDescription
    }
}

public struct HeidiBookingConfirmation: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let restaurantName: String
    public let dateText: String
    public let timeText: String
    public let partySize: Int
    public let specialRequests: String?

    public init(
        id: String,
        restaurantName: String,
        dateText: String,
        timeText: String,
        partySize: Int,
        specialRequests: String? = nil
    ) {
        self.id = id
        self.restaurantName = restaurantName
        self.dateText = dateText
        self.timeText = timeText
        self.partySize = partySize
        self.specialRequests = specialRequests
    }
}

public enum HeidiResponse: Sendable, Equatable {
    case text(String)
    case restaurantCards([HeidiRestaurantCard])
    case bookingConfirmation(HeidiBookingConfirmation)
    case done
}
