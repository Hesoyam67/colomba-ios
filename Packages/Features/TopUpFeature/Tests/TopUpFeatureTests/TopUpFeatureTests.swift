@testable import TopUpFeature
import XCTest

final class TopUpFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = TopUpFeatureModule.self
    }
}
