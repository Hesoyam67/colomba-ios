import XCTest
@testable import ColombaCore

final class ColombaCoreTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaCoreModule.self
    }
}
