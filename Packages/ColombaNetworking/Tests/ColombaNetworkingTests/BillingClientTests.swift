@testable import ColombaNetworking
import XCTest

final class BillingClientTests: XCTestCase {
    func testBillingEndpointContract() {
        XCTAssertEqual(BillingAPI.createPortalSession, APIEndpoint(method: .post, path: "/billing/portal"))
    }

    func testCreatePortalSessionReturnsMockUrl() async throws {
        let returnUrl = URL(fileURLWithPath: "/mock/return")
        let session = try await FixtureBillingClient().createPortalSession(returnUrl: returnUrl)

        XCTAssertEqual(session.url.path, "/mock/stripe/customer-portal-session")
        XCTAssertGreaterThan(session.expiresAt.timeIntervalSince1970, 0)
    }
}
