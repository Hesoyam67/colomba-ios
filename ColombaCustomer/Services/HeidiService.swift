import Foundation

public struct HeidiLiveConfiguration: Sendable, Equatable {
    public let baseURL: URL
    public let sessionId: String
    public let userId: String
    public let bearerToken: String

    public init(
        baseURL: URL = HTTPReservationClient.resolvedBaseURL(),
        sessionId: String,
        userId: String,
        bearerToken: String
    ) {
        self.baseURL = baseURL
        self.sessionId = sessionId
        self.userId = userId
        self.bearerToken = bearerToken
    }
}

public final class HeidiService: HeidiServiceProtocol, @unchecked Sendable {
    public enum Mode: Sendable {
        case mock
        case live(HeidiLiveConfiguration)
    }

    private let mode: Mode
    private let urlSession: URLSession
    private let encoder: JSONEncoder

    public init(mode: Mode = .mock, urlSession: URLSession = .shared) {
        self.mode = mode
        self.urlSession = urlSession
        self.encoder = JSONEncoder()
    }

    public func sendMessage(
        _ text: String,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        switch mode {
        case .mock:
            return mockStream(for: text, history: history)
        case let .live(configuration):
            return liveStream(for: text, history: history, configuration: configuration)
        }
    }

    private func liveStream(
        for text: String,
        history: [HeidiChatMessage],
        configuration: HeidiLiveConfiguration
    ) -> AsyncThrowingStream<HeidiResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try makeLiveRequest(text: text, history: history, configuration: configuration)
                    let (data, response) = try await urlSession.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw HeidiServiceError.invalidResponse
                    }
                    guard 200..<300 ~= httpResponse.statusCode else {
                        throw HeidiServiceError.server(status: httpResponse.statusCode)
                    }

                    let responses = try Self.parseResponses(from: data)
                    for response in responses {
                        continuation.yield(response)
                    }
                    if responses.contains(.done) == false {
                        continuation.yield(.done)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func makeLiveRequest(
        text: String,
        history: [HeidiChatMessage],
        configuration: HeidiLiveConfiguration
    ) throws -> URLRequest {
        let url = configuration.baseURL.appending(path: "heidi/chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/event-stream, application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(
            HeidiLiveRequest(
                sessionId: configuration.sessionId,
                userId: configuration.userId,
                message: text,
                history: history.compactMap(HeidiLiveHistoryMessage.init(message:))
            )
        )
        return request
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

public enum HeidiServiceError: Error, Sendable, Equatable {
    case invalidResponse
    case invalidPayload
    case server(status: Int)
}

public enum HeidiMockError: Error, Sendable, Equatable {
    case requestFailed
}

private struct HeidiLiveRequest: Encodable {
    let sessionId: String
    let userId: String
    let message: String
    let history: [HeidiLiveHistoryMessage]
}

private struct HeidiLiveHistoryMessage: Encodable {
    let role: String
    let text: String

    init?(message: HeidiChatMessage) {
        let trimmed = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        role = message.role.rawValue
        text = trimmed
    }
}

private struct HeidiBatchResponse: Decodable {
    let chunks: [HeidiLiveChunk]
}

private struct HeidiLiveChunk: Decodable {
    let type: String
    let content: JSONValue?
    let text: String?
    let message: String?
    let error: String?
}

private extension HeidiService {
    static func parseResponses(from data: Data) throws -> [HeidiResponse] {
        let decoder = JSONDecoder()
        if let batch = try? decoder.decode(HeidiBatchResponse.self, from: data) {
            return batch.chunks.compactMap(Self.response(for:))
        }

        if let chunks = try? decoder.decode([HeidiLiveChunk].self, from: data) {
            return chunks.compactMap(Self.response(for:))
        }

        guard let body = String(data: data, encoding: .utf8) else {
            throw HeidiServiceError.invalidPayload
        }
        let chunks = body
            .components(separatedBy: "\n\n")
            .compactMap(Self.dataPayload(in:))
            .compactMap { payload in
                try? decoder.decode(HeidiLiveChunk.self, from: Data(payload.utf8))
            }
        guard chunks.isEmpty == false else {
            throw HeidiServiceError.invalidPayload
        }
        return chunks.compactMap(Self.response(for:))
    }

    static func dataPayload(in event: String) -> String? {
        let dataLines = event.split(separator: "\n").compactMap { line -> Substring? in
            guard line.hasPrefix("data:") else { return nil }
            return line.dropFirst(5).drop(while: { $0 == " " })
        }
        guard dataLines.isEmpty == false else { return nil }
        return dataLines.joined(separator: "\n")
    }

    static func response(for chunk: HeidiLiveChunk) -> HeidiResponse? {
        switch chunk.type {
        case "text":
            guard let text = chunk.textValue else { return nil }
            return .text(text)
        case "restaurants":
            guard let restaurants = chunk.content?.arrayValue else { return nil }
            return .restaurantCards(restaurants.compactMap(Self.restaurantCard(from:)))
        case "booking_confirmation":
            guard let object = chunk.content?.objectValue,
                  let confirmation = bookingConfirmation(from: object) else {
                return nil
            }
            return .bookingConfirmation(confirmation)
        case "error":
            return .text(chunk.textValue ?? chunk.error ?? "Heidi hit an error.")
        case "done":
            return .done
        default:
            return nil
        }
    }

    static func restaurantCard(from value: JSONValue) -> HeidiRestaurantCard? {
        guard let object = value.objectValue else { return nil }
        guard let name = object.string(for: "name") else { return nil }
        let id = object.string(for: "id") ?? object.string(for: "restaurantId") ?? name
        let cuisine = object.string(for: "cuisine") ?? "Restaurant"
        let neighborhood = object.string(for: "neighborhood") ?? object.string(for: "address") ?? ""
        let priceRange = object.string(for: "priceRange") ?? object.string(for: "price") ?? ""
        let nextAvailableTime = object.string(for: "nextAvailableTime") ?? object.string(for: "nextAvailable") ?? ""
        let shortDescription = object.string(for: "shortDescription")
            ?? object.string(for: "description")
            ?? neighborhood
        return HeidiRestaurantCard(
            id: id,
            name: name,
            cuisine: cuisine,
            neighborhood: neighborhood,
            priceRange: priceRange,
            nextAvailableTime: nextAvailableTime,
            shortDescription: shortDescription
        )
    }

    static func bookingConfirmation(from object: [String: JSONValue]) -> HeidiBookingConfirmation? {
        let id = object.string(for: "id") ?? object.string(for: "reservationId") ?? "heidi-confirmation"
        let restaurantName = object.string(for: "restaurantName") ?? object.string(for: "name") ?? "Colomba"
        let dateText = object.string(for: "dateText")
            ?? object.string(for: "date")
            ?? object.string(for: "startsAt")
            ?? ""
        let timeText = object.string(for: "timeText") ?? object.string(for: "time") ?? ""
        let partySize = object.int(for: "partySize") ?? 0
        return HeidiBookingConfirmation(
            id: id,
            restaurantName: restaurantName,
            dateText: dateText,
            timeText: timeText,
            partySize: partySize,
            specialRequests: object.string(for: "specialRequests")
        )
    }
}

private extension HeidiLiveChunk {
    var textValue: String? {
        text ?? message ?? content?.stringValue ?? content?.objectValue?.string(for: "message")
    }
}

private enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: Self])
    case array([Self])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: Self].self) {
            self = .object(value)
        } else if let value = try? container.decode([Self].self) {
            self = .array(value)
        } else {
            throw HeidiServiceError.invalidPayload
        }
    }

    var stringValue: String? {
        switch self {
        case let .string(value): return value
        case let .number(value): return String(value)
        case let .bool(value): return String(value)
        case .object, .array, .null: return nil
        }
    }

    var intValue: Int? {
        switch self {
        case let .number(value): return Int(value)
        case let .string(value): return Int(value)
        case .bool, .object, .array, .null: return nil
        }
    }

    var objectValue: [String: Self]? {
        guard case let .object(value) = self else { return nil }
        return value
    }

    var arrayValue: [Self]? {
        guard case let .array(value) = self else { return nil }
        return value
    }
}

private extension [String: JSONValue] {
    func string(for key: String) -> String? {
        self[key]?.stringValue
    }

    func int(for key: String) -> Int? {
        self[key]?.intValue
    }
}
