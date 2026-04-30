@testable import ColombaNetworking
import XCTest

final class ColombaNetworkingTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaNetworkingModule.self
    }
}
