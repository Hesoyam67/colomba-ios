import Foundation

public struct HeidiService: HeidiServiceProtocol {
    public static let defaultEndpoint = URL(string: "https://api.colomba-swiss.ch/webhook/heidi/chat") ?? URL(fileURLWithPath: "/")

    private let endpoint: URL
    private let session: URLSession
    private let tokenProvider: @Sendable () async throws -> String?

    public init(
        endpoint: URL = Self.defaultEndpoint,
        session: URLSession = .shared,
        tokenProvider: @escaping @Sendable () async throws -> String? = { nil }
    ) {
        self.endpoint = endpoint
        self.session = session
        self.tokenProvider = tokenProvider
    }

    public func sendMessage(
        _ text: String,
        history: [HeidiMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if let token = try await tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder.heidi.encode(HeidiChatRequest(message: text, history: history))

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200..<300).contains(httpResponse.statusCode) else {
                        throw HeidiServiceError.invalidResponse
                    }
                    for try await line in bytes.lines {
                        guard let response = Self.decodeServerSentEvent(line) else { continue }
                        continuation.yield(response)
                        if response == .done { break }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private static func decodeServerSentEvent(_ line: String) -> HeidiResponse? {
        guard line.hasPrefix("data:") else { return nil }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespacesAndNewlines)
        guard payload != "[DONE]", let data = payload.data(using: .utf8) else {
            return .done
        }
        return try? JSONDecoder.heidi.decode(HeidiResponse.self, from: data)
    }
}

public struct MockHeidiService: HeidiServiceProtocol {
    public var script: [HeidiResponse]
    public var delayNanoseconds: UInt64

    public init(script: [HeidiResponse] = Self.defaultScript, delayNanoseconds: UInt64 = 0) {
        self.script = script
        self.delayNanoseconds = delayNanoseconds
    }

    public func sendMessage(
        _ text: String,
        history: [HeidiMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for response in script {
                    if delayNanoseconds > 0 {
                        try await Task.sleep(nanoseconds: delayNanoseconds)
                    }
                    continuation.yield(response)
                }
                continuation.finish()
            }
        }
    }

    public static let defaultScript: [HeidiResponse] = [
        .thinking,
        .text(String(localized: "heidi.mock.search_intro")),
        .restaurantResults(Self.sampleRestaurants),
        .text(String(localized: "heidi.mock.booking_offer")),
        .bookingConfirmation(Self.sampleBooking),
        .done
    ]

    public static let sampleRestaurants: [HeidiRestaurantSuggestion] = [
        HeidiRestaurantSuggestion(
            id: "bellini",
            name: "Bellini Zürich",
            cuisine: "Italian",
            neighborhood: "Kreis 1",
            priceRange: "CHF 40–60",
            summary: "Warm, central, and good for a Saturday dinner for four."
        ),
        HeidiRestaurantSuggestion(
            id: "linde",
            name: "Zur Linde",
            cuisine: "Swiss",
            neighborhood: "Enge",
            priceRange: "CHF 35–55",
            summary: "Classic Swiss comfort with vegetarian options."
        )
    ]

    public static let sampleBooking = HeidiBookingConfirmation(
        bookingId: "BK-HEIDI-001",
        restaurantName: "Bellini Zürich",
        dateText: "Saturday",
        timeText: "19:30",
        partySize: 4,
        status: "Pending confirmation"
    )
}

public enum HeidiServiceError: Error, Equatable {
    case invalidResponse
}

private struct HeidiChatRequest: Encodable {
    let message: String
    let history: [HeidiMessage]
}

private extension JSONEncoder {
    static var heidi: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var heidi: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
