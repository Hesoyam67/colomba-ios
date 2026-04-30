import XCTest
@testable import ColombaAuth

final class ColombaAuthTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaAuthModule.self
    }
}
