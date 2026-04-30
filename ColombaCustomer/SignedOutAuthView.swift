import AuthenticationServices
import ColombaAuth
import ColombaDesign
import Foundation
import SwiftUI

struct SignedOutAuthView: View {
    let authController: AuthController

    let state: AuthState

    @State private var email = ""
    @State private var code = ""
    @State private var appleNonce = Self.makeNonce()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ColombaSpacing.space6) {
                header
                appleButton
                divider
                magicLinkForm
                stateMessage
            }
            .padding(ColombaSpacing.Screen.margin)
            .frame(maxWidth: 520, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colomba.bg.base)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Colomba sign-in screen")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
            Text("Welcome to Colomba")
                .font(.colomba.display)
                .foregroundStyle(Color.colomba.text.primary)
                .accessibilityLabel("Welcome to Colomba")
            Text("Sign in securely with Apple, or use the email magic link for pilot accounts.")
                .font(.colomba.bodyLg)
                .foregroundStyle(Color.colomba.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Sign in securely with Apple or email magic link")
        }
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            appleNonce = Self.makeNonce()
            request.requestedScopes = [.fullName, .email]
            request.nonce = appleNonce
        } onCompletion: { result in
            handleAppleCompletion(result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.button, style: .continuous))
        .accessibilityLabel("Sign in with Apple")
    }

    private var divider: some View {
        HStack(spacing: ColombaSpacing.space3) {
            Rectangle()
                .fill(Color.colomba.border.hairline)
                .frame(height: 1)
            Text("or")
                .font(.colomba.caption)
                .foregroundStyle(Color.colomba.text.tertiary)
                .accessibilityHidden(true)
            Rectangle()
                .fill(Color.colomba.border.hairline)
                .frame(height: 1)
        }
    }

    private var magicLinkForm: some View {
        VStack(alignment: .leading, spacing: ColombaSpacing.space4) {
            Text("Email magic link")
                .font(.colomba.titleMd)
                .foregroundStyle(Color.colomba.text.primary)
                .accessibilityLabel("Email magic link")
            TextField("owner@example.ch", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(ColombaSpacing.space4)
                .background(Color.colomba.bg.card)
                .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
                .overlay(cardBorder)
                .accessibilityLabel("Email address")
            Button {
                Task {
                    await authController.requestMagicLink(email: email)
                }
            } label: {
                Text("Send sign-in link")
                    .font(.colomba.bodyMd.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send magic sign-in link")
            verifyForm
        }
    }

    @ViewBuilder private var verifyForm: some View {
        if let challenge {
            VStack(alignment: .leading, spacing: ColombaSpacing.space3) {
                Text("We sent a code to \(challenge.maskedEmail).")
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)
                    .accessibilityLabel("Magic code sent to \(challenge.maskedEmail)")
                TextField("482913", text: $code)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .padding(ColombaSpacing.space4)
                    .background(Color.colomba.bg.card)
                    .clipShape(RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous))
                    .overlay(cardBorder)
                    .accessibilityLabel("Magic sign-in code")
                Button {
                    Task {
                        await authController.verifyMagicLink(challenge: challenge, code: code)
                    }
                } label: {
                    Text("Verify code")
                        .font(.colomba.bodyMd.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).count < 6)
                .accessibilityLabel("Verify magic sign-in code")
            }
        }
    }

    @ViewBuilder private var stateMessage: some View {
        switch state {
        case .requestingMagicLink:
            loadingMessage("Sending secure link…", label: "Sending secure magic link")
        case .verifyingMagicLink:
            loadingMessage("Verifying code…", label: "Verifying magic code")
        case .authenticatingWithApple:
            loadingMessage("Checking Apple credential…", label: "Checking Apple credential")
        case let .failed(message):
            Text(message)
                .font(.colomba.caption)
                .foregroundStyle(Color.colomba.error)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Sign-in error: \(message)")
        default:
            EmptyView()
        }
    }

    private var challenge: MagicLinkChallenge? {
        switch state {
        case let .magicLinkSent(challenge), let .verifyingMagicLink(challenge):
            challenge
        default:
            nil
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: ColombaRadii.Component.card, style: .continuous)
            .stroke(Color.colomba.border.hairline, lineWidth: 1)
    }

    private func loadingMessage(_ text: String, label: String) -> some View {
        HStack(spacing: ColombaSpacing.space3) {
            ProgressView()
            Text(text)
                .font(.colomba.caption)
        }
        .foregroundStyle(Color.colomba.text.secondary)
        .accessibilityLabel(label)
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            handleAppleAuthorization(authorization)
        case let .failure(error):
            authController.recordFailure(error.localizedDescription)
        }
    }

    private func handleAppleAuthorization(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authController.recordFailure(AuthFailure.missingAppleCredential.localizedDescription)
            return
        }
        guard let identityToken = string(from: credential.identityToken),
              let authorizationCode = string(from: credential.authorizationCode) else {
            authController.recordFailure(AuthFailure.missingAppleCredential.localizedDescription)
            return
        }
        let payload = AppleCredentialPayload(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            nonce: appleNonce,
            email: credential.email,
            fullName: fullName(from: credential.fullName)
        )
        Task {
            await authController.signInWithApple(payload)
        }
    }

    private func fullName(from components: PersonNameComponents?) -> String? {
        guard let components else {
            return nil
        }
        let formatter = PersonNameComponentsFormatter()
        let name = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    private func string(from data: Data?) -> String? {
        guard let data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func makeNonce() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}
