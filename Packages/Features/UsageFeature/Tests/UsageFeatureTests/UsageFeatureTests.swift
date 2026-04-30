import XCTest
@testable import UsageFeature

final class UsageFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = UsageFeatureModule.self
    }
}
