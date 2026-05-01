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
                ProgressView(String(localized: "phone_verify.verifying_progress"))
                    .font(.custom(
                        "Inter",
                        size: 17,
                        relativeTo: .body
                    ))
            case .verified:
                statusView(
                    title: String(localized: "phone_verify.verified_title"),
                    message: String(localized: "phone_verify.verified_body"),
                    color: Color.colomba.success
                )
            case .failed(let reason):
                statusView(
                    title: String(localized: "phone_verify.paused_title"),
                    message: reason,
                    color: Color.colomba.error
                )
            }
        }
        .padding(32)
        .frame(maxWidth: 560, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colomba.bg.base)
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("phone_verify.title")
                .font(.custom("Fraunces", size: 34, relativeTo: .largeTitle).weight(.bold))
                .foregroundStyle(Color.colomba.text.primary)
            Text("phone_verify.body")
                .font(.custom("Inter", size: 17, relativeTo: .body))
                .foregroundStyle(Color.colomba.text.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var enteringView: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                Text("phone_verify.country_code")
                    .font(.custom("Inter", size: 17, relativeTo: .body).weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(Color.colomba.bg.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                TextField(String(localized: "phone_verify.phone_placeholder"), text: phoneBinding)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .font(.custom("Inter", size: 17, relativeTo: .body))
                    .padding(14)
                    .background(Color.colomba.bg.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button(String(localized: "phone_verify.send_code")) {
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
            Text(attemptsText)
                .font(.custom("Inter", size: 15, relativeTo: .body))
                .foregroundStyle(Color.colomba.text.secondary)

            Button(String(localized: "phone_verify.verify_code")) {
                Task { await viewModel.verifyCode() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canVerify)

            Button(resendTitle) {
                Task { await viewModel.resend() }
            }
            .disabled(viewModel.resendCooldownSeconds > 0)

            Button(String(localized: "phone_verify.change_number")) {
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
            Button(String(localized: "phone_verify.change_number")) { viewModel.changeNumber() }
        }
    }

    /// Format: phone_verify.resend_in_format contains one integer second count.
    private var resendTitle: String {
        if viewModel.resendCooldownSeconds > 0 {
            return String(
                format: NSLocalizedString("phone_verify.resend_in_format", comment: ""),
                viewModel.resendCooldownSeconds
            )
        }
        return String(localized: "phone_verify.resend_code")
    }

    /// Format: phone_verify.attempts_format contains one integer attempt count.
    private var attemptsText: String {
        String(
            format: NSLocalizedString("phone_verify.attempts_format", comment: ""),
            viewModel.attemptsRemaining
        )
    }

    private var phoneBinding: Binding<String> {
        Binding(get: { viewModel.phoneNumber }, set: { viewModel.updatePhoneNumber($0) })
    }

    private var otpBinding: Binding<String> {
        Binding(get: { viewModel.otp }, set: { viewModel.updateOTP($0) })
    }
}
