@testable import ColombaCore
import XCTest

final class ColombaCoreTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaCoreModule.self
    }
}
