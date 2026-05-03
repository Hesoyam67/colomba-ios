@testable import ColombaCustomer
import XCTest

@MainActor
final class HeidiChatViewModelTests: XCTestCase {
    func test_initialState_hasWelcomeMessage() {
        let model = HeidiChatViewModel(service: FakeHeidiService(script: [.done]))
        XCTAssertEqual(model.messages.count, 1)
        XCTAssertEqual(model.messages.first?.sender, .assistant)
        XCTAssertEqual(model.phase, .idle)
    }

    func test_sendMessage_appendsUserAndAssistantText() async {
        let model = HeidiChatViewModel(service: FakeHeidiService(script: [.text("Grüezi"), .done]))
        await model.send("Find Italian")
        XCTAssertEqual(model.messages.map(\.sender), [.assistant, .user, .assistant])
        XCTAssertEqual(model.messages.last?.text, "Grüezi")
        XCTAssertEqual(model.phase, .idle)
    }

    func test_sendDraft_trimsAndClearsDraft() async {
        let model = HeidiChatViewModel(service: FakeHeidiService(script: [.text("Done"), .done]))
        model.draft = "  book it  "
        await model.sendDraft()
        XCTAssertEqual(model.draft, "")
        XCTAssertEqual(model.messages[1].text, "book it")
    }

    func test_emptyMessage_isIgnored() async {
        let model = HeidiChatViewModel(service: FakeHeidiService(script: [.text("No"), .done]))
        await model.send("   ")
        XCTAssertEqual(model.messages.count, 1)
    }

    func test_streamingChunks_areAppendedToOneAssistantMessage() async {
        let model = HeidiChatViewModel(service: FakeHeidiService(script: [.text("Hel"), .text("lo"), .done]))
        await model.send("Hi")
        XCTAssertEqual(model.messages.last?.text, "Hello")
        XCTAssertEqual(model.messages.filter { $0.sender == .assistant }.count, 2)
    }

    func test_thinking_isReplacedByText() async {
        let model = HeidiChatViewModel(service: FakeHeidiService(script: [.thinking, .text("Ready"), .done]))
        await model.send("Search")
        XCTAssertEqual(model.messages.last?.text, "Ready")
    }

    func test_restaurantCards_areRenderedOnAssistantMessage() async {
        let restaurant = HeidiRestaurantSuggestion(
            id: "bellini",
            name: "Bellini",
            cuisine: "Italian",
            neighborhood: "Kreis 1",
            priceRange: "CHF 40–60",
            summary: "Central"
        )
        let model = HeidiChatViewModel(service: FakeHeidiService(script: [.restaurantResults([restaurant]), .done]))
        await model.send("Italian")
        XCTAssertEqual(model.messages.last?.cards, [.restaurant(restaurant)])
    }

    func test_bookingConfirmationCard_isRendered() async {
        let confirmation = HeidiBookingConfirmation(
            bookingId: "BK1",
            restaurantName: "Bellini",
            dateText: "Saturday",
            timeText: "19:30",
            partySize: 4,
            status: "Pending"
        )
        let model = HeidiChatViewModel(service: FakeHeidiService(script: [.bookingConfirmation(confirmation), .done]))
        await model.send("Book")
        XCTAssertEqual(model.messages.last?.cards, [.bookingConfirmation(confirmation)])
    }

    func test_error_appendsNetworkMessageAndFailedPhase() async {
        let model = HeidiChatViewModel(service: FakeHeidiService(error: StubError()))
        await model.send("Search")
        XCTAssertEqual(model.messages.last?.sender, .assistant)
        guard case .failed = model.phase else {
            XCTFail("Expected failed phase")
            return
        }
    }

    func test_mockServiceIncludesSearchAndBookingCards() async throws {
        let stream = try await MockHeidiService().sendMessage("Book Bellini", history: [])
        var responses: [HeidiResponse] = []
        for try await response in stream { responses.append(response) }
        XCTAssertTrue(responses.contains { response in
            if case .restaurantResults = response { return true }
            return false
        })
        XCTAssertTrue(responses.contains { response in
            if case .bookingConfirmation = response { return true }
            return false
        })
    }
}

private struct FakeHeidiService: HeidiServiceProtocol {
    let script: [HeidiResponse]
    let error: Error?

    init(script: [HeidiResponse] = [], error: Error? = nil) {
        self.script = script
        self.error = error
    }

    func sendMessage(
        _ text: String,
        history: [HeidiMessage]
    ) async throws -> AsyncThrowingStream<HeidiResponse, Error> {
        if let error { throw error }
        return AsyncThrowingStream { continuation in
            script.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }
}

private struct StubError: Error {}
