@testable import ScheduledChangeFeature
import XCTest

final class ScheduledChangeFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ScheduledChangeFeatureModule.self
    }
}
