@testable import AccountFeature
import XCTest

final class AccountFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = AccountFeatureModule.self
    }
}
