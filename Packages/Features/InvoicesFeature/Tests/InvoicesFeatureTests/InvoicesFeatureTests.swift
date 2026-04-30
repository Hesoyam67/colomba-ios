@testable import InvoicesFeature
import XCTest

final class InvoicesFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = InvoicesFeatureModule.self
    }
}
