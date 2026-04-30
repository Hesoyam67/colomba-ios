@testable import PlanFeature
import XCTest

final class PlanFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = PlanFeatureModule.self
    }
}
