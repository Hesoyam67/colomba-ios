import ColombaDesign
import SwiftUI

@MainActor
struct HeidiChatView: View {
    @StateObject private var viewModel: HeidiChatViewModel

    init() {
        _viewModel = StateObject(wrappedValue: HeidiChatViewModel())
    }

    init(viewModel: HeidiChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                onRestaurantAction: { card in
                                    Task { await viewModel.checkAvailability(for: card) }
                                }
                            )
                            .id(message.id)
                        }
                        if viewModel.phase == .sending {
                            HStack {
                                Label(LocalizedStringKey("heidi.thinking"), systemImage: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(Color.colomba.text.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            if case let .failed(message) = viewModel.phase {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.colomba.error)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            ChatInputBar(text: $viewModel.draft, canSend: viewModel.canSend) {
                Task { await viewModel.sendDraft() }
            }
        }
        .background(Color.colomba.bg.base)
        .navigationTitle(Text("heidi.nav_title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(LocalizedStringKey("heidi.reset")) {
                    viewModel.reset()
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

#Preview {
    NavigationStack {
        HeidiChatView()
    }
}
