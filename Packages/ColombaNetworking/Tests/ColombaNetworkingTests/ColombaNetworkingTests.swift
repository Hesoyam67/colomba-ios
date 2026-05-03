@testable import ColombaNetworking
import XCTest

final class ColombaNetworkingTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaNetworkingModule.self
    }

    func testPhaseTwoAuthEndpointContracts() {
        XCTAssertEqual(AuthAPI.appleExchange, APIEndpoint(method: .post, path: "/auth/apple"))
        XCTAssertEqual(AuthAPI.googleExchange, APIEndpoint(method: .post, path: "/auth/google"))
        XCTAssertEqual(AuthAPI.magicLinkRequest, APIEndpoint(method: .post, path: "/auth/magic-link/request"))
        XCTAssertEqual(AuthAPI.magicLinkVerify, APIEndpoint(method: .post, path: "/auth/magic-link/verify"))
        XCTAssertEqual(AuthAPI.sessionRefresh, APIEndpoint(method: .post, path: "/auth/session/refresh"))
    }
}
