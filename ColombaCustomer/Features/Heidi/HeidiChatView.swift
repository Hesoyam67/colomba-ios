import ColombaDesign
import SwiftUI

struct HeidiChatView: View {
    @StateObject private var viewModel: HeidiChatViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: HeidiChatViewModel())
    }

    @MainActor
    init(viewModel: HeidiChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: ColombaSpacing.space3) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(ColombaSpacing.Screen.margin)
                }
                .background(Color.colomba.bg.base)
                .onChange(of: viewModel.messages) { _, messages in
                    guard let last = messages.last else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            ChatInputBar(
                text: $viewModel.draft,
                isSending: viewModel.phase == .sending,
                onSend: {
                    Task { await viewModel.sendDraft() }
                }
            )
        }
        .navigationTitle(Text("heidi.nav_title"))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("heidi.accessibility.chat"))
    }
}

#Preview {
    NavigationStack {
        HeidiChatView()
    }
}
