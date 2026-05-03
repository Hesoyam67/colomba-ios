import Foundation

@MainActor
public final class HeidiChatViewModel: ObservableObject {
    @Published public private(set) var messages: [HeidiMessage]
    @Published public private(set) var phase: ChatPhase = .idle
    @Published public var draft: String = ""

    private let service: HeidiServiceProtocol

    public init(
        service: HeidiServiceProtocol = MockHeidiService(),
        messages: [HeidiMessage]? = nil
    ) {
        self.service = service
        self.messages = messages ?? [
            HeidiMessage(sender: .assistant, text: String(localized: "heidi.welcome"))
        ]
    }

    public var canSend: Bool {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && phase != .sending
    }

    public func sendDraft() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        draft = ""
        await send(text)
    }

    public func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        let userMessage = HeidiMessage(sender: .user, text: trimmed)
        messages.append(userMessage)
        phase = .sending

        do {
            let stream = try await service.sendMessage(trimmed, history: Array(messages.dropLast()))
            var assistantMessage = HeidiMessage(sender: .assistant, text: "")
            var didAppendAssistant = false
            for try await response in stream {
                phase = .streaming
                apply(response, to: &assistantMessage, didAppendAssistant: &didAppendAssistant)
            }
            if didAppendAssistant == false {
                messages.append(HeidiMessage(sender: .assistant, text: String(localized: "heidi.empty_response")))
            }
            phase = .idle
        } catch {
            messages.append(HeidiMessage(sender: .assistant, text: String(localized: "heidi.error.network")))
            phase = .failed(String(localized: "heidi.error.network"))
        }
    }

    private func apply(
        _ response: HeidiResponse,
        to assistantMessage: inout HeidiMessage,
        didAppendAssistant: inout Bool
    ) {
        switch response {
        case .thinking:
            if didAppendAssistant == false {
                assistantMessage.text = String(localized: "heidi.thinking")
                messages.append(assistantMessage)
                didAppendAssistant = true
            }
        case let .text(chunk):
            if didAppendAssistant == false {
                assistantMessage.text = chunk
                messages.append(assistantMessage)
                didAppendAssistant = true
            } else if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                if messages[index].text == String(localized: "heidi.thinking") {
                    messages[index].text = chunk
                    assistantMessage.text = chunk
                } else {
                    messages[index].text += chunk
                    assistantMessage.text += chunk
                }
            }
        case let .restaurantResults(restaurants):
            let cards = restaurants.map(HeidiCard.restaurant)
            assistantMessage.cards.append(contentsOf: cards)
            upsert(assistantMessage, didAppendAssistant: &didAppendAssistant)
        case let .bookingConfirmation(confirmation):
            assistantMessage.cards.append(.bookingConfirmation(confirmation))
            upsert(assistantMessage, didAppendAssistant: &didAppendAssistant)
        case .done:
            break
        }
    }

    private func upsert(_ message: HeidiMessage, didAppendAssistant: inout Bool) {
        if didAppendAssistant,
           let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
            didAppendAssistant = true
        }
    }
}
