import XCTest
@testable import ColombaBilling

final class ColombaBillingTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaBillingModule.self
    }
}
