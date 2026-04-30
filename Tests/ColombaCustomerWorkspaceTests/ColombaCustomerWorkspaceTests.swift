@testable import ColombaCustomerWorkspace
import XCTest

final class ColombaCustomerWorkspaceTests: XCTestCase {
    func testAggregateModuleIsPublic() {
        _ = ColombaCustomerWorkspaceModule.self
    }
}
