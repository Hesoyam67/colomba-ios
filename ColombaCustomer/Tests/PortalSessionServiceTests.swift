@testable import ColombaCustomer
import ColombaNetworking
import XCTest

final class PortalSessionServiceTests: XCTestCase {
    func testCreatesHttpsPortalURL() async throws {
        let expected = try XCTUnwrap(URL(string: "https://billing.stripe.test/session_123"))
        let client = FixtureBillingClient(
            session: BillingPortalSession(url: expected, expiresAt: Date(timeIntervalSince1970: 2_000))
        )
        let service = PortalSessionService(
            billingClient: client,
            returnURL: try XCTUnwrap(URL(string: "colomba://billing/return")),
            now: { Date(timeIntervalSince1970: 1_000) }
        )

        let url = try await service.createPortalURL()

        XCTAssertEqual(url, expected)
    }

    func testRejectsNonHttpsPortalURL() async throws {
        let client = FixtureBillingClient(
            session: BillingPortalSession(
                url: URL(fileURLWithPath: "/mock/portal"),
                expiresAt: Date(timeIntervalSince1970: 2_000)
            )
        )
        let service = PortalSessionService(billingClient: client, now: { Date(timeIntervalSince1970: 1_000) })

        do {
            _ = try await service.createPortalURL()
            XCTFail("Expected invalid scheme")
        } catch let error as PortalSessionService.PortalSessionError {
            XCTAssertEqual(error, .invalidScheme)
        }
    }

    func testRejectsExpiredPortalURL() async throws {
        let client = FixtureBillingClient(
            session: BillingPortalSession(
                url: try XCTUnwrap(URL(string: "https://billing.stripe.test/expired")),
                expiresAt: Date(timeIntervalSince1970: 900)
            )
        )
        let service = PortalSessionService(billingClient: client, now: { Date(timeIntervalSince1970: 1_000) })

        do {
            _ = try await service.createPortalURL()
            XCTFail("Expected expired portal session")
        } catch let error as PortalSessionService.PortalSessionError {
            XCTAssertEqual(error, .expired)
        }
    }
}
