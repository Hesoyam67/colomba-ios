import ColombaDesign
import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: ColombaSpacing.space2) {
            Button {} label: {
                Image(systemName: "mic.fill")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel(Text("heidi.input.voice_placeholder"))

            TextField(String(localized: "heidi.input.placeholder"), text: $text, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(.horizontal, ColombaSpacing.space3)
                .padding(.vertical, ColombaSpacing.space2)
                .background(Color.colomba.bg.raised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .disabled(isSending)

            Button(action: onSend) {
                Image(systemName: isSending ? "hourglass" : "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .accessibilityLabel(Text("heidi.input.send"))
        }
        .padding(ColombaSpacing.space3)
        .background(.thinMaterial)
    }
}
