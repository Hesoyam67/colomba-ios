import ColombaDesign
import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let canSend: Bool
    let send: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                // Voice input placeholder for v2.
            } label: {
                Image(systemName: "mic.fill")
            }
            .accessibilityLabel(Text("heidi.input.voice"))
            TextField(LocalizedStringKey("heidi.input.placeholder"), text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .submitLabel(.send)
                .onSubmit(send)
            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
            }
            .disabled(canSend == false)
            .accessibilityLabel(Text("heidi.input.send"))
        }
        .padding(12)
        .background(Color.colomba.bg.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
