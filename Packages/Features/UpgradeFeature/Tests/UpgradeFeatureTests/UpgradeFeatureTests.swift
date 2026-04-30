import XCTest
@testable import UpgradeFeature

final class UpgradeFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = UpgradeFeatureModule.self
    }
}
