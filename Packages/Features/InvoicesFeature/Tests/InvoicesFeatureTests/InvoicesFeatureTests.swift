import XCTest
@testable import InvoicesFeature

final class InvoicesFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = InvoicesFeatureModule.self
    }
}
