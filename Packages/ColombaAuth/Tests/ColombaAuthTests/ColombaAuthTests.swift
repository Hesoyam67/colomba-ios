@testable import ColombaAuth
import XCTest

@MainActor
final class ColombaAuthTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaAuthModule.self
    }

    func testRestoreStartsSignedOutWithoutStoredSession() async {
        let controller = makeController()
        await controller.restoreSession()

        XCTAssertEqual(controller.state, AuthState.signedOut)
    }

    func testMagicLinkFlowStoresAuthenticatedSession() async throws {
        let store = InMemoryAuthSessionStore()
        let service = MockAuthService(now: Self.fixedDate)
        let controller = makeController(store: store, service: service)

        await controller.requestMagicLink(email: "owner@alte-post.ch")
        guard case let .magicLinkSent(challenge) = controller.state else {
            return XCTFail("Expected magic link challenge.")
        }

        await controller.verifyMagicLink(challenge: challenge, code: "482913")

        let stored = try store.load()
        XCTAssertEqual(controller.state.session, stored)
        XCTAssertEqual(controller.state.session?.customer.displayName, "Colomba Pilot")
    }

    func testAppleExchangeStoresSession() async throws {
        let store = InMemoryAuthSessionStore()
        let controller = makeController(store: store)
        let credential = AppleCredentialPayload(
            identityToken: "identity-token",
            authorizationCode: "authorization-code",
            nonce: "nonce-123",
            email: "owner@salon.ch",
            fullName: "Salon Owner"
        )

        await controller.signInWithApple(credential)

        XCTAssertEqual(controller.state.session?.customer.displayName, "Salon Owner")
        XCTAssertEqual(try store.load()?.customer.billingEmail, "owner@salon.ch")
    }

    func testMagicLinkURLHandlerExchangesSession() async throws {
        let store = InMemoryAuthSessionStore()
        let controller = makeController(store: store)
        guard let url = URL(string: "colomba://auth/magic?challengeId=mch_url&code=482913") else {
            return XCTFail("Expected valid magic-link URL.")
        }

        await controller.handleMagicLinkURL(url)

        XCTAssertEqual(controller.state.session?.customer.displayName, "Colomba Pilot")
        XCTAssertNotNil(try store.load())
    }

    func testMagicLinkURLParserRejectsNonAuthURL() {
        guard let url = URL(string: "colomba://billing/return?code=482913") else {
            return XCTFail("Expected valid non-auth URL.")
        }

        XCTAssertNil(MagicLinkURLParser.parse(url))
    }

    func testRefreshReplacesAccessToken() async throws {
        let session = Self.sampleSession(accessToken: "old")
        let store = InMemoryAuthSessionStore(session: session)
        let controller = makeController(store: store)

        await controller.restoreSession()
        await controller.refreshSession()

        XCTAssertEqual(controller.state.session?.tokens.accessToken, "mock_access_refreshed")
    }

    func testSignOutClearsStoredSession() async throws {
        let store = InMemoryAuthSessionStore(session: Self.sampleSession(accessToken: "existing"))
        let controller = makeController(store: store)

        await controller.restoreSession()
        controller.signOut()

        XCTAssertEqual(controller.state, AuthState.signedOut)
        XCTAssertNil(try store.load())
    }

    func testUpdateDisplayNamePersistsSession() async throws {
        let store = InMemoryAuthSessionStore(session: Self.sampleSession(accessToken: "existing"))
        let controller = makeController(store: store)

        await controller.restoreSession()
        let updated = try await controller.updateDisplayName("  Bistro Owner  ")

        XCTAssertEqual(updated.customer.displayName, "Bistro Owner")
        XCTAssertEqual(controller.state.session?.customer.displayName, "Bistro Owner")
        XCTAssertEqual(try store.load()?.tokens.accessToken, "existing")
        XCTAssertEqual(try store.load()?.customer.displayName, "Bistro Owner")
    }

    func testSnapshotDescriptorsCoverAuthStates() {
        let challenge = MagicLinkChallenge(
            challengeId: "mch_snapshot",
            maskedEmail: "o***@colomba.ch",
            expiresAt: Self.fixedDate().addingTimeInterval(60),
            cooldownSeconds: 0
        )

        XCTAssertEqual(AuthScreenSnapshot.describe(state: .signedOut), "auth.signedOut.apple+magicLink")
        XCTAssertEqual(AuthScreenSnapshot.describe(state: .magicLinkSent(challenge)), "auth.magic.sent:o***@colomba.ch")
        XCTAssertEqual(
            AuthScreenSnapshot.describe(state: .authenticated(Self.sampleSession(accessToken: "snapshot"))),
            "auth.authenticated:Colomba Pilot"
        )
    }

    private func makeController(
        store: InMemoryAuthSessionStore = InMemoryAuthSessionStore(),
        service: MockAuthService? = nil
    ) -> AuthController {
        let resolvedService = service ?? MockAuthService(now: Self.fixedDate)
        return AuthController(
            sessionStore: store,
            service: resolvedService,
            device: DeviceInfo(deviceId: "ios-test-device", appVersion: "1.0.0"),
            initialState: .restoring
        )
    }

    nonisolated private static func sampleSession(accessToken: String) -> AuthSession {
        AuthSession(
            customer: Customer(
                id: "cus_test",
                displayName: "Colomba Pilot",
                billingEmail: "pilot@colomba.ch",
                locale: .germanSwitzerland
            ),
            tokens: AuthTokens(
                accessToken: accessToken,
                refreshToken: "refresh",
                expiresAt: fixedDate().addingTimeInterval(3600)
            ),
            onboardingRequired: false
        )
    }

    nonisolated private static func fixedDate() -> Date {
        Date(timeIntervalSince1970: 1_777_000_000)
    }
}
