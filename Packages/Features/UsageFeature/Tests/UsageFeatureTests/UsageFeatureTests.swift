@testable import UsageFeature
import XCTest

final class UsageFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = UsageFeatureModule.self
    }
}
