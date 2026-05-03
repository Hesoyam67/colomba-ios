@testable import ColombaCustomer
import XCTest

@MainActor
final class AccountDeletionViewModelTests: XCTestCase {
    func testConfirmationRequiresDeleteKeyword() {
        let viewModel = AccountDeletionViewModel(service: MockAccountService(), accessToken: "token", signOut: {})
        viewModel.confirmationText = "delete"
        XCTAssertTrue(viewModel.confirmationAccepted)
        viewModel.confirmationText = "keep"
        XCTAssertFalse(viewModel.confirmationAccepted)
    }

    func testMagicLinkSubmitRequiresConfirmationChallengeAndCode() {
        let viewModel = AccountDeletionViewModel(service: MockAccountService(), accessToken: "token", signOut: {})
        viewModel.confirmationText = "DELETE"
        viewModel.magicLinkChallengeId = "mch_123"
        viewModel.magicLinkCode = "123456"
        XCTAssertTrue(viewModel.canSubmitMagicLinkDeletion)
    }

    func testMagicLinkSubmitRejectsShortCode() {
        let viewModel = AccountDeletionViewModel(service: MockAccountService(), accessToken: "token", signOut: {})
        viewModel.confirmationText = "DELETE"
        viewModel.magicLinkChallengeId = "mch_123"
        viewModel.magicLinkCode = "12345"
        XCTAssertFalse(viewModel.canSubmitMagicLinkDeletion)
    }

    func testRequestDeletionWithMagicLinkSendsTrimmedPayload() async {
        let service = MockAccountService()
        let viewModel = AccountDeletionViewModel(service: service, accessToken: "token", signOut: {})
        viewModel.confirmationText = " DELETE "
        viewModel.magicLinkChallengeId = " mch_123 "
        viewModel.magicLinkCode = " 123456 "

        await viewModel.requestDeletionWithMagicLink()

        XCTAssertEqual(viewModel.state, .deleted)
        XCTAssertEqual(service.receivedReauth, .magicLink(challengeId: "mch_123", code: "123456"))
        XCTAssertEqual(service.receivedAccessToken, "token")
    }

    func testValidationFailureDoesNotCallService() async {
        let service = MockAccountService()
        let viewModel = AccountDeletionViewModel(service: service, accessToken: "token", signOut: {})
        viewModel.confirmationText = "NOPE"
        viewModel.magicLinkChallengeId = "mch_123"
        viewModel.magicLinkCode = "123456"

        await viewModel.requestDeletionWithMagicLink()

        XCTAssertEqual(viewModel.state, .failed(.validationFailed))
        XCTAssertNil(service.receivedReauth)
    }

    func testSubscriptionActiveMovesToBlockedState() async throws {
        let portalURL = try XCTUnwrap(URL(string: "https://billing.stripe.test/session"))
        let service = MockAccountService(error: AccountDeletionError.subscriptionActive(portalURL: portalURL))
        let viewModel = AccountDeletionViewModel(service: service, accessToken: "token", signOut: {})
        viewModel.confirmationText = "DELETE"
        viewModel.magicLinkChallengeId = "mch_123"
        viewModel.magicLinkCode = "123456"

        await viewModel.requestDeletionWithMagicLink()

        XCTAssertEqual(viewModel.state, .blockedBySubscription(portalURL))
    }

    func testFinishDeletedFlowSignsOutOnlyAfterSuccess() async {
        var signOutCount = 0
        let viewModel = AccountDeletionViewModel(service: MockAccountService(), accessToken: "token") { signOutCount += 1 }
        viewModel.finishDeletedFlow()
        XCTAssertEqual(signOutCount, 0)
        viewModel.confirmationText = "DELETE"
        viewModel.magicLinkChallengeId = "mch_123"
        viewModel.magicLinkCode = "123456"
        await viewModel.requestDeletionWithMagicLink()
        viewModel.finishDeletedFlow()
        XCTAssertEqual(signOutCount, 1)
    }
}

@MainActor
private final class MockAccountService: AccountServiceProtocol, @unchecked Sendable {
    let error: Error?
    private(set) var receivedReauth: AccountDeletionReauth?
    private(set) var receivedAccessToken: String?

    init(error: Error? = nil) {
        self.error = error
    }

    func requestDeletion(reauth: AccountDeletionReauth, accessToken: String) async throws {
        receivedReauth = reauth
        receivedAccessToken = accessToken
        if let error { throw error }
    }
}
