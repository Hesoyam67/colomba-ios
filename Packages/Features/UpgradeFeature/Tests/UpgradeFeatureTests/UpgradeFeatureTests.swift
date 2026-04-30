@testable import UpgradeFeature
import XCTest

final class UpgradeFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = UpgradeFeatureModule.self
    }
}
