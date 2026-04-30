@testable import ColombaAuth
import XCTest

final class ColombaAuthTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaAuthModule.self
    }
}
