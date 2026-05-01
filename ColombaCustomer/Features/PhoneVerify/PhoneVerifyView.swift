import ColombaDesign
import SwiftUI

public struct PhoneVerifyView: View {
    @StateObject private var viewModel: PhoneVerifyViewModel

    public init(viewModel: PhoneVerifyViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 24) {
            header

            switch viewModel.phase {
            case .entering:
                enteringView
            case .confirming:
                confirmingView
            case .verifying:
                ProgressView("Verifying code…")
                    .font(.custom(
                        "Inter",
                        size: 17,
                        relativeTo: .body
                    ))
            case .verified:
                statusView(
                    title: "Phone verified",
                    message: "You can continue onboarding.",
                    color: Color.colomba.success
                )
            case .failed(let reason):
                statusView(title: "Verification paused", message: reason, color: Color.colomba.error)
            }
        }
        .padding(32)
        .frame(maxWidth: 560, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colomba.bg.base)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Verify your phone")
                .font(.custom("Fraunces", size: 34, relativeTo: .largeTitle).weight(.bold))
                .foregroundStyle(Color.colomba.text.primary)
            Text("We’ll send a 6-digit SMS code to your Swiss mobile number.")
                .font(.custom("Inter", size: 17, relativeTo: .body))
                .foregroundStyle(Color.colomba.text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var enteringView: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                Text("+41")
                    .font(.custom("Inter", size: 17, relativeTo: .body).weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(Color.colomba.bg.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                TextField("79 123 45 67", text: phoneBinding)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .font(.custom("Inter", size: 17, relativeTo: .body))
                    .padding(14)
                    .background(Color.colomba.bg.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button("Send code") {
                Task { await viewModel.sendCode() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isPhoneValid)
        }
    }

    private var confirmingView: some View {
        VStack(spacing: 18) {
            OTPInputView(code: otpBinding) { _ in
                Task { await viewModel.verifyCode() }
            }
            Text("Attempts remaining: \(viewModel.attemptsRemaining)")
                .font(.custom("Inter", size: 15, relativeTo: .body))
                .foregroundStyle(Color.colomba.text.secondary)

            Button("Verify code") {
                Task { await viewModel.verifyCode() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canVerify)

            Button(resendTitle) {
                Task { await viewModel.resend() }
            }
            .disabled(viewModel.resendCooldownSeconds > 0)

            Button("Change number") {
                viewModel.changeNumber()
            }
        }
    }

    private func statusView(title: String, message: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.custom("Fraunces", size: 28, relativeTo: .title).weight(.bold))
                .foregroundStyle(color)
            Text(message)
                .font(.custom("Inter", size: 17, relativeTo: .body))
                .foregroundStyle(Color.colomba.text.secondary)
                .multilineTextAlignment(.center)
            Button("Change number") { viewModel.changeNumber() }
        }
    }

    private var resendTitle: String {
        viewModel.resendCooldownSeconds > 0 ? "Resend in \(viewModel.resendCooldownSeconds)s" : "Resend code"
    }

    private var phoneBinding: Binding<String> {
        Binding(get: { viewModel.phoneNumber }, set: { viewModel.updatePhoneNumber($0) })
    }

    private var otpBinding: Binding<String> {
        Binding(get: { viewModel.otp }, set: { viewModel.updateOTP($0) })
    }
}
