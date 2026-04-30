import XCTest
@testable import TopUpFeature

final class TopUpFeatureTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = TopUpFeatureModule.self
    }
}
