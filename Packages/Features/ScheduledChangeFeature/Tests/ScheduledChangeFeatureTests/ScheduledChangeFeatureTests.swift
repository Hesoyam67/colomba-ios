import XCTest
@testable import ScheduledChangeFeature

final class ScheduledChangeFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ScheduledChangeFeatureModule.self
    }
}
