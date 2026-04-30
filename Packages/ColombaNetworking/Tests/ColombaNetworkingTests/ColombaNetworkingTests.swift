import XCTest
@testable import ColombaNetworking

final class ColombaNetworkingTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaNetworkingModule.self
    }
}
