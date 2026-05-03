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
                googleButton
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
            Text("auth.welcome_title")
                .font(.colomba.display)
                .foregroundStyle(Color.colomba.text.primary)
                .accessibilityLabel("Welcome to Colomba")
            Text("auth.signin_copy")
                .font(.colomba.bodyLg)
                .foregroundStyle(Color.colomba.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Sign in securely with Apple or email magic link")
        }
    }

    @ViewBuilder private var appleButton: some View {
        if isAppleSignInEnabled {
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
            .disabled(state == .authenticatingWithApple || state == .authenticatingWithGoogle)
            .accessibilityLabel("Sign in with Apple")
        } else {
            VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
                Button {
                    authController.recordFailure(String(localized: "auth.apple_unavailable_local_dev"))
                } label: {
                    HStack(spacing: ColombaSpacing.space3) {
                        Image(systemName: "apple.logo")
                            .imageScale(.large)
                        Text("auth.signin_apple")
                            .font(.colomba.bodyMd.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .frame(height: 52)
                .accessibilityLabel("Sign in with Apple unavailable in local development build")

                Text("auth.apple_unavailable_local_dev")
                    .font(.colomba.caption)
                    .foregroundStyle(Color.colomba.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var googleButton: some View {
        Button {
            Task {
                await handleGoogleSignIn()
            }
        } label: {
            HStack(spacing: ColombaSpacing.space3) {
                Image(systemName: "g.circle.fill")
                    .imageScale(.large)
                Text("auth.signin_google")
                    .font(.colomba.bodyMd.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .frame(height: 52)
        .disabled(state == .authenticatingWithApple || state == .authenticatingWithGoogle)
        .accessibilityLabel("Sign in with Google")
    }

    private var divider: some View {
        HStack(spacing: ColombaSpacing.space3) {
            Rectangle()
                .fill(Color.colomba.border.hairline)
                .frame(height: 1)
            Text("auth.or")
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
            Text("auth.email_magic_link")
                .font(.colomba.titleMd)
                .foregroundStyle(Color.colomba.text.primary)
                .accessibilityLabel("Email magic link")
            TextField(String(localized: "auth.email_placeholder"), text: $email)
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
                Text("auth.send_signin_link")
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
                Text(codeSentText(for: challenge.maskedEmail))
                    .font(.colomba.bodyMd)
                    .foregroundStyle(Color.colomba.text.secondary)
                    .accessibilityLabel("Magic code sent to \(challenge.maskedEmail)")
                TextField(String(localized: "auth.code_placeholder"), text: $code)
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
                    Text("auth.verify_code")
                        .font(.colomba.bodyMd.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).count < 6)
                .accessibilityLabel("Verify magic sign-in code")
            }
        }
    }

    /// Format: auth.code_sent_to_format contains one %@ masked email.
    private func codeSentText(for maskedEmail: String) -> String {
        String(format: NSLocalizedString("auth.code_sent_to_format", comment: ""), maskedEmail)
    }

    @ViewBuilder private var stateMessage: some View {
        switch state {
        case .requestingMagicLink:
            loadingMessage(String(localized: "auth.sending_link"), label: String(localized: "auth.sending_link"))
        case .verifyingMagicLink:
            loadingMessage(String(localized: "auth.verifying_code"), label: String(localized: "auth.verifying_code"))
        case .authenticatingWithApple:
            loadingMessage(String(localized: "auth.checking_apple"), label: String(localized: "auth.checking_apple"))
        case .authenticatingWithGoogle:
            loadingMessage(String(localized: "auth.checking_google"), label: String(localized: "auth.checking_google"))
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

    private var isAppleSignInEnabled: Bool {
        Bundle.main.bundleIdentifier != "com.hesoyam.colomba.dev"
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

    private func handleGoogleSignIn() async {
        #if canImport(GoogleSignIn)
        do {
            let token = try await GoogleSignInOAuthClient(configuration: .from()).authorize(scopes: [])
            let credential = GoogleCredentialPayload(
                accessToken: token.accessToken,
                idToken: token.idToken,
                email: token.email,
                fullName: token.fullName,
                scopes: token.scopes
            )
            await authController.signInWithGoogle(credential)
        } catch {
            authController.recordFailure(error.localizedDescription)
        }
        #else
        authController.recordFailure(AuthFailure.missingGoogleCredential.localizedDescription)
        #endif
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
