import XCTest
@testable import ColombaAuth

@MainActor
final class ProfileEditViewModelTests: XCTestCase {
    func testUpdateDisplayNameTrimsAndPersists() async throws {
        let store = InMemoryAuthSessionStore(session: Self.sampleSession)
        let controller = AuthController(
            sessionStore: store,
            service: MockAuthService(),
            initialState: .authenticated(Self.sampleSession)
        )

        let updated = try await controller.updateDisplayName("  Updated Owner  ")

        XCTAssertEqual(updated.customer.displayName, "Updated Owner")
        XCTAssertEqual(controller.state.session?.customer.displayName, "Updated Owner")
        XCTAssertEqual(try store.load()?.customer.displayName, "Updated Owner")
        XCTAssertEqual(try store.load()?.tokens.accessToken, "access")
    }

    func testUpdateDisplayNameRejectsBlankName() async throws {
        let store = InMemoryAuthSessionStore(session: Self.sampleSession)
        let controller = AuthController(
            sessionStore: store,
            service: MockAuthService(),
            initialState: .authenticated(Self.sampleSession)
        )

        do {
            _ = try await controller.updateDisplayName("   ")
            XCTFail("Expected blank display name to fail")
        } catch AuthFailure.invalidDisplayName {
            XCTAssertEqual(try store.load()?.customer.displayName, "Original Owner")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateDisplayNameRejectsNamesOverSixtyCharacters() async throws {
        let store = InMemoryAuthSessionStore(session: Self.sampleSession)
        let controller = AuthController(
            sessionStore: store,
            service: MockAuthService(),
            initialState: .authenticated(Self.sampleSession)
        )

        do {
            _ = try await controller.updateDisplayName(String(repeating: "A", count: 61))
            XCTFail("Expected long display name to fail")
        } catch AuthFailure.invalidDisplayName {
            XCTAssertEqual(try store.load()?.customer.displayName, "Original Owner")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private static let sampleSession = AuthSession(
        customer: Customer(
            id: "cus_profile_test",
            displayName: "Original Owner",
            email: "owner@example.ch",
            phoneNumber: "+41791234567",
            locale: .englishSwitzerland
        ),
        tokens: AuthTokens(
            accessToken: "access",
            refreshToken: "refresh",
            expiresAt: Date(timeIntervalSince1970: 1_777_000_000)
        ),
        onboardingRequired: false
    )
}
