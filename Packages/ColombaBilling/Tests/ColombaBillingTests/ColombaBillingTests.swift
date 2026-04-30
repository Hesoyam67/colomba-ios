@testable import ColombaBilling
import XCTest

final class ColombaBillingTests: XCTestCase {
    func testSentinelIsPublic() {
        _ = ColombaBillingModule.self
    }
}
