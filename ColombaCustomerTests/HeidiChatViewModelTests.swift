@testable import ColombaCustomer
import XCTest

@MainActor
final class HeidiChatViewModelTests: XCTestCase {
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
        restaurantName: "Bellini",
        dateText: "Saturday",
        timeText: "19:30",
        partySize: 4
    )
}

private struct StubHeidiService: HeidiServiceProtocol {
    let responses: [HeidiResponse]
    let error: Error?

    init(responses: [HeidiResponse] = [], error: Error? = nil) {
        self.responses = responses
        self.error = error
    }

    func sendMessage(
        _ text: String,
        history: [HeidiChatMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        if let error { throw error }
        let responses = responses
        return AsyncThrowingStream { continuation in
            for response in responses {
                continuation.yield(response)
            }
            continuation.finish()
        }
    }
}
