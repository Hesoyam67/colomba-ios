@testable import ColombaNetworking
import XCTest

final class APIErrorTests: XCTestCase {
    func testErrorCatalogCoverageFromBead009() {
        let catalogCodes: Set<String> = [
            "auth.apple_cancelled",
            "auth.magic_link_expired",
            "auth.magic_link_invalid",
            "auth.session_revoked",
            "billing.payment_required",
            "billing.portal_unavailable",
            "ai.support_unavailable",
            "ai.rate_limited",
            "network.offline",
            "network.timeout",
            "server.internal",
            "server.maintenance",
            "client.decode_failed",
            "unknown.unexpected"
        ]

        XCTAssertEqual(Set(APIError.allCases.map(\.rawValue)), catalogCodes)
    }

    func testUnknownErrorResponseMapsToUnexpected() {
        let error = APIError(errorResponse: ErrorResponse(code: "new.future.error", message: "Future"))

        XCTAssertEqual(error, .unknownUnexpected)
    }
}
