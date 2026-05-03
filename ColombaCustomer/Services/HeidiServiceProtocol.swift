import Foundation

public protocol HeidiServiceProtocol: Sendable {
    func sendMessage(
        _ text: String,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error>

    func confirmBooking(
        _ confirmation: HeidiBookingConfirmation,
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
    public let address: String?

    public init(
        id: String,
        name: String,
        cuisine: String,
        neighborhood: String,
        priceRange: String,
        nextAvailableTime: String,
        shortDescription: String,
        address: String? = nil
    ) {
        self.id = id
        self.name = name
        self.cuisine = cuisine
        self.neighborhood = neighborhood
        self.priceRange = priceRange
        self.nextAvailableTime = nextAvailableTime
        self.shortDescription = shortDescription
        self.address = address
    }
}

public struct HeidiBookingConfirmation: Sendable, Equatable, Identifiable, Codable {
    public let id: String
    public let restaurantId: String?
    public let restaurantName: String
    public let dateText: String
    public let timeText: String
    public let startsAt: Date?
    public let slotId: String?
    public let partySize: Int
    public let specialRequests: String?
    public let draftAction: HeidiDraftAction?
    public var reservationDeepLinkURL: URL { AppRouter.DeepLink.reservation(id: id).url }

    public init(
        id: String,
        restaurantId: String? = nil,
        restaurantName: String,
        dateText: String,
        timeText: String,
        startsAt: Date? = nil,
        slotId: String? = nil,
        partySize: Int,
        specialRequests: String? = nil,
        draftAction: HeidiDraftAction? = nil
    ) {
        self.id = id
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.dateText = dateText
        self.timeText = timeText
        self.startsAt = startsAt
        self.slotId = slotId
        self.partySize = partySize
        self.specialRequests = specialRequests
        self.draftAction = draftAction
    }
}

public struct HeidiDraftAction: Sendable, Equatable, Codable {
    public let type: String
    public let payload: [String: String]

    public init(type: String = "confirm_booking", payload: [String: String] = [:]) {
        self.type = type
        self.payload = payload
    }
}

public enum HeidiResponse: Sendable, Equatable {
    case text(String)
    case restaurantCards([HeidiRestaurantCard])
    case bookingConfirmation(HeidiBookingConfirmation)
    case done
}

public enum HeidiCardRoute: Hashable, Identifiable {
    case restaurantDetails(HeidiRestaurantCard)
    case modifyBooking(HeidiBookingConfirmation)

    public var id: String {
        switch self {
        case let .restaurantDetails(card):
            return "restaurant-details-\(card.id)"
        case let .modifyBooking(confirmation):
            return "modify-booking-\(confirmation.id)"
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public enum HeidiCardButtonAction: Sendable, Equatable {
    case viewRestaurantDetails(HeidiRestaurantCard)
    case confirmBooking(HeidiBookingConfirmation)
    case modifyBooking(HeidiBookingConfirmation)
    case requestCancelConfirmation(HeidiBookingConfirmation)
    case dismissCancelConfirmation
    case confirmCancel
}

public struct HeidiCardActionState: Sendable, Equatable {
    public var route: HeidiCardRoute?
    public var confirmationToSend: HeidiBookingConfirmation?
    public var cancelCandidate: HeidiBookingConfirmation?
    public var cancellationToSend: Reservation?

    public init(
        route: HeidiCardRoute? = nil,
        confirmationToSend: HeidiBookingConfirmation? = nil,
        cancelCandidate: HeidiBookingConfirmation? = nil,
        cancellationToSend: Reservation? = nil
    ) {
        self.route = route
        self.confirmationToSend = confirmationToSend
        self.cancelCandidate = cancelCandidate
        self.cancellationToSend = cancellationToSend
    }

    public mutating func apply(_ action: HeidiCardButtonAction) {
        switch action {
        case let .viewRestaurantDetails(card):
            route = .restaurantDetails(card)
        case let .confirmBooking(confirmation):
            confirmationToSend = confirmation
        case let .modifyBooking(confirmation):
            route = .modifyBooking(confirmation)
        case let .requestCancelConfirmation(confirmation):
            cancelCandidate = confirmation
        case .dismissCancelConfirmation:
            cancelCandidate = nil
        case .confirmCancel:
            cancellationToSend = cancelCandidate?.reservationForAction
            cancelCandidate = nil
        }
    }
}

public extension HeidiRestaurantCard {
    var restaurantForDeepLink: Restaurant {
        Restaurant(
            id: id,
            name: name,
            cuisine: cuisine,
            address: address ?? neighborhood
        )
    }
}

public extension HeidiBookingConfirmation {
    var reservationForAction: Reservation {
        Reservation(
            id: id,
            restaurantId: restaurantId ?? id,
            restaurantName: restaurantName,
            startsAt: startsAt ?? Date(timeIntervalSinceNow: 86_400),
            partySize: partySize,
            specialRequests: specialRequests,
            status: .active
        )
    }

    var restaurantForAction: Restaurant {
        Restaurant(
            id: restaurantId ?? id,
            name: restaurantName,
            cuisine: "",
            address: ""
        )
    }
}
