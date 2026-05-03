import ColombaAuth
import ColombaDesign
import SwiftUI

struct AccountDeletionView: View {
    @Environment(\.openURL) private var openURL
    @State private var viewModel: AccountDeletionViewModel

    init(authController: AuthController) {
        _viewModel = State(
            initialValue: AccountDeletionViewModel(
                accessToken: authController.state.session?.tokens.accessToken,
                signOut: { authController.signOut() }
            )
        )
    }

    init(viewModel: AccountDeletionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: ColombaSpacing.space2) {
                    Text(String(localized: "account_deletion.warning_title"))
                        .font(.colomba.bodyLg)
                        .foregroundStyle(Color.colomba.error)
                    Text(String(localized: "account_deletion.warning_body"))
                        .font(.body)
                        .foregroundStyle(Color.colomba.text.secondary)
                }
                .accessibilityElement(children: .combine)
            }

            Section(String(localized: "account_deletion.confirm_section")) {
                Text(String(localized: "account_deletion.confirm_instruction"))
                    .font(.colomba.caption)
                    .foregroundStyle(Color.colomba.text.secondary)
                TextField(String(localized: "account_deletion.confirm_placeholder"), text: $viewModel.confirmationText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityLabel(Text(String(localized: "account_deletion.confirm_accessibility")))
            }

            Section(String(localized: "account_deletion.reauth_section")) {
                Text(String(localized: "account_deletion.magic_link_help"))
                    .font(.colomba.caption)
                    .foregroundStyle(Color.colomba.text.secondary)
                TextField(String(localized: "account_deletion.challenge_id"), text: $viewModel.magicLinkChallengeId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(String(localized: "account_deletion.magic_code"), text: $viewModel.magicLinkCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                Button {
                    Task { await viewModel.requestDeletionWithMagicLink() }
                } label: {
                    if viewModel.isDeleting {
                        ProgressView()
                    } else {
                        Text(String(localized: "account_deletion.delete_cta"))
                    }
                }
                .disabled(!viewModel.canSubmitMagicLinkDeletion)
                .accessibilityHint(Text(String(localized: "account_deletion.delete_hint")))
            }

            switch viewModel.state {
            case let .blockedBySubscription(url):
                Section {
                    Text(String(localized: "account_deletion.subscription_blocked_body"))
                        .foregroundStyle(Color.colomba.text.secondary)
                    if let url {
                        Button(String(localized: "account_deletion.open_billing_portal")) {
                            openURL(url)
                        }
                    }
                }
            case .deleted:
                Section {
                    Text(String(localized: "account_deletion.deleted_body"))
                        .foregroundStyle(Color.colomba.text.secondary)
                    Button(String(localized: "account_deletion.done_cta")) {
                        viewModel.finishDeletedFlow()
                    }
                }
            default:
                if let message = viewModel.state.errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(Color.colomba.error)
                            .accessibilityLabel(Text(message))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.colomba.bg.base)
        .navigationTitle(String(localized: "account_deletion.title"))
        .onAppear { viewModel.startConfirmation() }
    }
}

#Preview {
    NavigationStack {
        AccountDeletionView(authController: .productionMock())
    }
}
