import Combine
import Foundation

@MainActor
public final class HeidiChatViewModel: ObservableObject {
    public enum ChatPhase: Sendable, Equatable {
        case idle
        case sending
        case failed(String)
    }

    @Published public private(set) var messages: [HeidiChatMessage]
    @Published public private(set) var phase: ChatPhase = .idle
    @Published public var draft: String = ""

    private let service: HeidiServiceProtocol

    public init(service: HeidiServiceProtocol = HeidiService()) {
        self.service = service
        self.messages = [
            HeidiChatMessage(role: .assistant, text: String(localized: "heidi.welcome"))
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

        messages.append(HeidiChatMessage(role: .user, text: trimmed))
        phase = .sending
        var assistant = HeidiChatMessage(role: .assistant, text: "")
        messages.append(assistant)
        let assistantIndex = messages.index(before: messages.endIndex)

        do {
            let stream = try await service.sendMessage(trimmed, history: messages)
            for try await response in stream {
                switch response {
                case let .text(chunk):
                    assistant.text = append(chunk, to: assistant.text)
                case let .restaurantCards(cards):
                    assistant.restaurantCards = cards
                case let .bookingConfirmation(confirmation):
                    assistant.bookingConfirmation = confirmation
                case .done:
                    break
                }
                messages[assistantIndex] = assistant
            }
            if assistant.text.isEmpty,
               assistant.restaurantCards.isEmpty,
               assistant.bookingConfirmation == nil {
                messages.remove(at: assistantIndex)
            }
            phase = .idle
        } catch {
            messages.remove(at: assistantIndex)
            phase = .failed(String(localized: "heidi.error.network"))
        }
    }

    public func reset() {
        phase = .idle
        draft = ""
        messages = [HeidiChatMessage(role: .assistant, text: String(localized: "heidi.welcome"))]
    }

    private func append(_ chunk: String, to current: String) -> String {
        guard current.isEmpty == false else { return chunk }
        return "\(current)\n\(chunk)"
    }
}
