import XCTest
@testable import PlanFeature

final class PlanFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = PlanFeatureModule.self
    }
}
