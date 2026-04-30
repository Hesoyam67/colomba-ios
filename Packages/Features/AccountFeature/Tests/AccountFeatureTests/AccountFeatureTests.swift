import XCTest
@testable import AccountFeature

final class AccountFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = AccountFeatureModule.self
    }
}
