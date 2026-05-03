@testable import ColombaCustomer
import XCTest

@MainActor
final class HeidiChatViewModelTests: XCTestCase {
    override func tearDown() {
        HeidiMockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func test_emptyStateShowsWelcomeAndCanNotSendBlankDraft() {
        let model = HeidiChatViewModel(service: StubHeidiService(responses: [.done]))
        XCTAssertEqual(model.messages.count, 1)
        XCTAssertEqual(model.messages.first?.role, .assistant)
        model.draft = "   "
        XCTAssertFalse(model.canSend)
    }

    func test_sendTextAppendsUserAndAssistantResponse() async {
        let model = HeidiChatViewModel(service: StubHeidiService(responses: [.text("Grüezi"), .done]))
        await model.send("hello")
        XCTAssertEqual(model.messages.map(\.role), [.assistant, .user, .assistant])
        XCTAssertEqual(model.messages.last?.text, "Grüezi")
        XCTAssertEqual(model.phase, .idle)
    }

    func test_sendDraftTrimsAndClearsInput() async {
        let model = HeidiChatViewModel(service: StubHeidiService(responses: [.text("Done"), .done]))
        model.draft = "  book Bellini  "
        await model.sendDraft()
        XCTAssertEqual(model.draft, "")
        XCTAssertEqual(model.messages[1].text, "book Bellini")
    }

    func test_streamingTextChunksAreJoined() async {
        let model = HeidiChatViewModel(service: StubHeidiService(responses: [.text("First"), .text("Second"), .done]))
        await model.send("show options")
        XCTAssertEqual(model.messages.last?.text, "First\nSecond")
    }

    func test_errorRemovesPlaceholderAndSetsFailedPhase() async {
        let model = HeidiChatViewModel(service: StubHeidiService(error: HeidiMockError.requestFailed))
        await model.send("error")
        XCTAssertEqual(model.messages.count, 2)
        guard case let .failed(message) = model.phase else {
            XCTFail("Expected failed phase")
            return
        }
        XCTAssertFalse(message.isEmpty)
    }

    func test_restaurantCardsRenderOnAssistantMessage() async {
        let cards = [Self.card]
        let model = HeidiChatViewModel(service: StubHeidiService(responses: [.text("Options"), .restaurantCards(cards), .done]))
        await model.send("Italian Saturday")
        XCTAssertEqual(model.messages.last?.restaurantCards, cards)
    }

    func test_bookingConfirmationRendersOnAssistantMessage() async {
        let model = HeidiChatViewModel(service: StubHeidiService(responses: [.bookingConfirmation(Self.confirmation), .done]))
        await model.send("book it")
        XCTAssertEqual(model.messages.last?.bookingConfirmation, Self.confirmation)
    }

    func test_restaurantCardActionSendsStructuredAvailabilityPrompt() async {
        let service = CapturingHeidiService(responses: [.text("Checking"), .done])
        let model = HeidiChatViewModel(service: service)
        await model.checkAvailability(for: Self.card)
        XCTAssertEqual(service.sentMessages, [
            "Check availability for Bellini (restaurant id: one) around 19:30."
        ])
        XCTAssertEqual(model.messages[1].text, service.sentMessages.first)
    }

    func test_confirmBookingRoutesThroughHeidiService() async {
        let model = HeidiChatViewModel(
            service: StubHeidiService(confirmResponses: [.text("Confirmed"), .bookingConfirmation(Self.confirmation), .done])
        )
        await model.confirmBooking(Self.confirmation)
        XCTAssertEqual(model.messages.last?.text, "Confirmed")
        XCTAssertEqual(model.messages.last?.bookingConfirmation, Self.confirmation)
    }

    func test_cardActionRoutesBuildExpectedDestinations() {
        var state = HeidiCardActionState()
        state.apply(.viewRestaurantDetails(Self.card))
        XCTAssertEqual(state.route?.id, "restaurant-details-one")
        XCTAssertEqual(Self.card.restaurantForDeepLink.id, "one")
        XCTAssertEqual(Self.card.restaurantForDeepLink.name, "Bellini")

        state.apply(.modifyBooking(Self.confirmation))
        XCTAssertEqual(state.route?.id, "modify-booking-booking-1")
        XCTAssertEqual(Self.confirmation.reservationForAction.id, "booking-1")
        XCTAssertEqual(Self.confirmation.reservationForAction.partySize, 4)
    }

    func test_confirmCardActionStagesConfirmationForHeidiService() {
        var state = HeidiCardActionState()
        state.apply(.confirmBooking(Self.confirmation))
        XCTAssertEqual(state.confirmationToSend, Self.confirmation)
    }

    func test_cancelCardActionRequiresSecondConfirmationBeforeSendingCancel() {
        var state = HeidiCardActionState()
        state.apply(.requestCancelConfirmation(Self.confirmation))
        XCTAssertEqual(state.cancelCandidate, Self.confirmation)
        XCTAssertNil(state.cancellationToSend)

        state.apply(.dismissCancelConfirmation)
        XCTAssertNil(state.cancelCandidate)
        XCTAssertNil(state.cancellationToSend)

        state.apply(.requestCancelConfirmation(Self.confirmation))
        state.apply(.confirmCancel)
        XCTAssertNil(state.cancelCandidate)
        XCTAssertEqual(state.cancellationToSend?.id, Self.confirmation.id)
    }

    func test_modifyIntentReturnsAssistantText() async {
        let model = HeidiChatViewModel(service: HeidiService())
        await model.send("change my booking to 8")
        XCTAssertTrue(model.messages.last?.text.contains("move") == true)
    }

    func test_cancelIntentReturnsAssistantText() async {
        let model = HeidiChatViewModel(service: HeidiService())
        await model.send("cancel my booking")
        XCTAssertTrue(model.messages.last?.text.contains("confirm") == true)
    }

    func test_mockSearchReturnsCards() async {
        let model = HeidiChatViewModel(service: HeidiService())
        await model.send("show me Italian restaurants")
        XCTAssertFalse(model.messages.last?.restaurantCards.isEmpty ?? true)
    }

    func test_mockBookingReturnsConfirmation() async {
        let model = HeidiChatViewModel(service: HeidiService())
        await model.send("book Bellini")
        XCTAssertEqual(model.messages.last?.bookingConfirmation?.restaurantName, "Bellini Zürich")
    }

    func test_resetRestoresWelcomeOnly() async {
        let model = HeidiChatViewModel(service: StubHeidiService(responses: [.text("Done"), .done]))
        await model.send("hello")
        model.reset()
        XCTAssertEqual(model.messages.count, 1)
        XCTAssertEqual(model.phase, .idle)
    }

    func test_liveServiceSendsAuthenticatedRequestAndParsesSSE() async throws {
        let baseURL = try Self.makeURL("https://api.example.test/webhook")
        var capturedAuthorization: String?
        var capturedPath: String?
        var capturedBody: [String: Any]?
        HeidiMockURLProtocol.requestHandler = { request in
            capturedAuthorization = request.value(forHTTPHeaderField: "Authorization")
            capturedPath = request.url?.path
            let body = Self.bodyData(from: request)
            capturedBody = try JSONSerialization.jsonObject(with: body) as? [String: Any]

            let data = Data(
                """
                event: message
                data: {"type":"text","content":"Here are good options"}

                event: message
                data: {"type":"restaurants","content":[{"id":"colomba-demo","name":"Colomba Zürich","cuisine":"Swiss premium","address":"Zürich, Switzerland"}]}

                event: message
                data: {"type":"done","ok":true,"sessionId":"ios-test-session"}

                """.utf8
            )
            return (try Self.response(status: 200, url: request.url), data)
        }

        let service = HeidiService(
            mode: .live(
                HeidiLiveConfiguration(
                    baseURL: baseURL,
                    sessionId: "ios-test-session",
                    userId: "customer-1",
                    bearerToken: "access-token"
                )
            ),
            urlSession: Self.urlSession()
        )
        let history = [HeidiChatMessage(role: .assistant, text: "Welcome")]
        let stream = try await service.sendMessage("show restaurants", history: history)
        let responses = try await Self.responses(from: stream)

        XCTAssertEqual(capturedAuthorization, "Bearer access-token")
        XCTAssertEqual(capturedPath, "/webhook/heidi/chat")
        XCTAssertEqual(capturedBody?["sessionId"] as? String, "ios-test-session")
        XCTAssertEqual(capturedBody?["userId"] as? String, "customer-1")
        XCTAssertEqual(capturedBody?["message"] as? String, "show restaurants")
        XCTAssertEqual((capturedBody?["history"] as? [[String: Any]])?.first?["text"] as? String, "Welcome")
        XCTAssertEqual(responses.first, .text("Here are good options"))
        XCTAssertEqual(responses.last, .done)
        guard case let .restaurantCards(cards) = responses.dropFirst().first else {
            XCTFail("Expected restaurant cards")
            return
        }
        XCTAssertEqual(cards.first?.name, "Colomba Zürich")
        XCTAssertEqual(cards.first?.neighborhood, "Zürich, Switzerland")
    }

    func test_liveConfirmBookingUsesChatConfirmedDraftActionContract() async throws {
        let baseURL = try Self.makeURL("https://api.example.test/webhook")
        var capturedPath: String?
        var capturedBody: [String: Any]?
        HeidiMockURLProtocol.requestHandler = { request in
            capturedPath = request.url?.path
            let body = Self.bodyData(from: request)
            capturedBody = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            let data = Data("[{\"type\":\"text\",\"content\":\"Confirmed\"},{\"type\":\"done\"}]".utf8)
            return (try Self.response(status: 200, url: request.url), data)
        }
        let service = HeidiService(
            mode: .live(
                HeidiLiveConfiguration(
                    baseURL: baseURL,
                    sessionId: "ios-test-session",
                    userId: "customer-1",
                    bearerToken: "access-token"
                )
            ),
            urlSession: Self.urlSession()
        )
        let stream = try await service.confirmBooking(Self.confirmation, history: [])
        let responses = try await Self.responses(from: stream)

        XCTAssertEqual(capturedPath, "/webhook/heidi/chat")
        XCTAssertEqual(capturedBody?["confirmed"] as? Bool, true)
        XCTAssertEqual((capturedBody?["draftAction"] as? [String: Any])?["type"] as? String, "confirm_booking")
        XCTAssertEqual(responses.first, .text("Confirmed"))
    }

    func test_liveServiceThrowsOnHTTPError() async throws {
        HeidiMockURLProtocol.requestHandler = { request in
            (try Self.response(status: 401, url: request.url), Data())
        }
        let service = HeidiService(
            mode: .live(
                HeidiLiveConfiguration(
                    baseURL: try Self.makeURL("https://api.example.test/webhook"),
                    sessionId: "ios-test-session",
                    userId: "customer-1",
                    bearerToken: "bad-token"
                )
            ),
            urlSession: Self.urlSession()
        )
        let stream = try await service.sendMessage("hello", history: [])

        do {
            _ = try await Self.responses(from: stream)
            XCTFail("Expected HTTP error")
        } catch HeidiServiceError.server(status: 401) {
            XCTAssertTrue(true)
        }
    }


    private static func responses(
        from stream: AsyncThrowingStream<HeidiResponse, Error>
    ) async throws -> [HeidiResponse] {
        var responses: [HeidiResponse] = []
        for try await response in stream {
            responses.append(response)
        }
        return responses
    }

    private static func urlSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [HeidiMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func makeURL(_ rawValue: String) throws -> URL {
        guard let url = URL(string: rawValue) else {
            throw HeidiTestError.invalidURL
        }
        return url
    }

    private static func response(status: Int, url: URL?) throws -> HTTPURLResponse {
        guard let url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            throw HeidiTestError.invalidResponse
        }
        return response
    }

    private static func bodyData(from request: URLRequest) -> Data {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else {
            return Data()
        }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }

    private static let card = HeidiRestaurantCard(
        id: "one",
        name: "Bellini",
        cuisine: "Italian",
        neighborhood: "Seefeld",
        priceRange: "$$$",
        nextAvailableTime: "19:30",
        shortDescription: "Warm and polished."
    )

    private static let confirmation = HeidiBookingConfirmation(
        id: "booking-1",
        restaurantId: "one",
        restaurantName: "Bellini",
        dateText: "Saturday",
        timeText: "19:30",
        partySize: 4,
        draftAction: HeidiDraftAction(payload: ["reservationId": "booking-1"])
    )
}

private enum HeidiTestError: Error {
    case invalidURL
    case invalidResponse
}

private final class HeidiMockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: HeidiTestError.invalidResponse)
            return
        }
        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class CapturingHeidiService: HeidiServiceProtocol, @unchecked Sendable {
    private let responses: [HeidiResponse]
    private(set) var sentMessages: [String] = []

    init(responses: [HeidiResponse]) {
        self.responses = responses
    }

    func sendMessage(
        _ text: String,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        sentMessages.append(text)
        return stream(responses)
    }

    func confirmBooking(
        _ confirmation: HeidiBookingConfirmation,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        stream(responses)
    }

    private func stream(_ responses: [HeidiResponse]) -> AsyncThrowingStream<HeidiResponse, Error> {
        AsyncThrowingStream { continuation in
            for response in responses {
                continuation.yield(response)
            }
            continuation.finish()
        }
    }
}

private struct StubHeidiService: HeidiServiceProtocol {
    let responses: [HeidiResponse]
    let confirmResponses: [HeidiResponse]
    let error: Error?

    init(responses: [HeidiResponse] = [], confirmResponses: [HeidiResponse] = [], error: Error? = nil) {
        self.responses = responses
        self.confirmResponses = confirmResponses
        self.error = error
    }

    func sendMessage(
        _ text: String,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        if let error { throw error }
        return stream(responses)
    }

    func confirmBooking(
        _ confirmation: HeidiBookingConfirmation,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        if let error { throw error }
        return stream(confirmResponses)
    }

    private func stream(_ responses: [HeidiResponse]) -> AsyncThrowingStream<HeidiResponse, Error> {
        AsyncThrowingStream { continuation in
            for response in responses {
                continuation.yield(response)
            }
            continuation.finish()
        }
    }
}

@MainActor
final class HeidiDeepLinkTests: XCTestCase {
    func test_reservationDeepLinkRoundTripsFromBookingConfirmation() {
        let confirmation = HeidiBookingConfirmation(
            id: "reservation-123",
            restaurantName: "Bellini Zürich",
            dateText: "Saturday",
            timeText: "19:30",
            partySize: 4
        )

        XCTAssertEqual(confirmation.reservationDeepLinkURL.absoluteString, "colomba://reservations/reservation-123")
        XCTAssertEqual(
            AppRouter.DeepLink(url: confirmation.reservationDeepLinkURL),
            .reservation(id: "reservation-123")
        )
    }

    func test_httpsAppReservationDeepLinkParses() throws {
        let url = try XCTUnwrap(URL(string: "https://colomba-swiss.ch/app/reservations/reservation-123"))
        XCTAssertEqual(AppRouter.DeepLink(url: url), .reservation(id: "reservation-123"))
    }
}
