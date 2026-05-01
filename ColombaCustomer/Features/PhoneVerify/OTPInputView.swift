import SwiftUI

public struct OTPInputView: View {
    @Binding private var code: String
    private let length: Int = 6
    private let onComplete: (String) -> Void
    @FocusState private var isFocused: Bool

    public init(code: Binding<String>, onComplete: @escaping (String) -> Void) {
        self._code = code
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            TextField("", text: sanitizedBinding)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0.01)
                .accessibilityIdentifier("phoneVerify.otp.hiddenField")

            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    Text(character(at: index))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .frame(width: 44, height: 52)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(index == code.count ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .onAppear { isFocused = true }
        .onChange(of: code) { _, newValue in
            guard newValue.count == length else { return }
            onComplete(newValue)
        }
    }

    private var sanitizedBinding: Binding<String> {
        Binding(
            get: { code },
            set: { code = String($0.filter(\.isNumber).prefix(length)) }
        )
    }

    private func character(at index: Int) -> String {
        guard index < code.count else { return "" }
        let codeIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[codeIndex])
    }
}
