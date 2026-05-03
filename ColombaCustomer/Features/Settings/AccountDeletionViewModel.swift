import Foundation
import Observation

@MainActor
@Observable
final class AccountDeletionViewModel {
    enum State: Equatable {
        case idle
        case confirming
        case deleting
        case deleted
        case blockedBySubscription(URL?)
        case failed(AccountDeletionError)
    }

    var confirmationText = ""
    var magicLinkChallengeId = ""
    var magicLinkCode = ""
    private(set) var state: State = .idle

    private let service: AccountServiceProtocol
    private let accessToken: String
    private let signOut: @MainActor () -> Void

    init(
        service: AccountServiceProtocol = AccountService(),
        accessToken: String?,
        signOut: @escaping @MainActor () -> Void
    ) {
        self.service = service
        self.accessToken = accessToken ?? ""
        self.signOut = signOut
    }

    var canSubmitMagicLinkDeletion: Bool {
        confirmationAccepted && magicLinkChallengeId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
            magicLinkCode.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6 && state != .deleting
    }

    var confirmationAccepted: Bool {
        confirmationText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "DELETE"
    }

    var isDeleting: Bool { state == .deleting }

    func startConfirmation() {
        state = .confirming
    }

    func resetError() {
        if case .failed = state { state = .confirming }
    }

    func requestDeletionWithApple(identityToken: String) async {
        guard confirmationAccepted else {
            state = .failed(.validationFailed)
            return
        }
        await requestDeletion(.apple(identityToken: identityToken))
    }

    func requestDeletionWithMagicLink() async {
        guard canSubmitMagicLinkDeletion else {
            state = .failed(.validationFailed)
            return
        }
        await requestDeletion(
            .magicLink(
                challengeId: magicLinkChallengeId.trimmingCharacters(in: .whitespacesAndNewlines),
                code: magicLinkCode.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
    }

    func finishDeletedFlow() {
        guard state == .deleted else { return }
        signOut()
    }

    private func requestDeletion(_ reauth: AccountDeletionReauth) async {
        state = .deleting
        do {
            try await service.requestDeletion(reauth: reauth, accessToken: accessToken)
            state = .deleted
        } catch let error as AccountDeletionError {
            switch error {
            case let .subscriptionActive(portalURL):
                state = .blockedBySubscription(portalURL)
            default:
                state = .failed(error)
            }
        } catch {
            state = .failed(.network)
        }
    }
}

extension AccountDeletionViewModel.State {
    var errorMessage: String? {
        guard case let .failed(error) = self else { return nil }
        return error.localizedAccountDeletionMessage
    }
}

extension AccountDeletionError {
    var localizedAccountDeletionMessage: String {
        switch self {
        case .notAuthenticated:
            String(localized: "account_deletion.error_not_authenticated")
        case .reauthRequired:
            String(localized: "account_deletion.error_reauth_required")
        case .reauthInvalid:
            String(localized: "account_deletion.error_reauth_invalid")
        case .reauthMismatch:
            String(localized: "account_deletion.error_reauth_mismatch")
        case .subscriptionActive:
            String(localized: "account_deletion.error_subscription_active")
        case .alreadyDeleted:
            String(localized: "account_deletion.error_already_deleted")
        case .maintenance:
            String(localized: "account_deletion.error_maintenance")
        case .validationFailed:
            String(localized: "account_deletion.error_validation")
        case .network:
            String(localized: "account_deletion.error_network")
        case .server:
            String(localized: "account_deletion.error_server")
        }
    }
}
