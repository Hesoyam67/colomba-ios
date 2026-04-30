import XCTest
@testable import ColombaCustomerWorkspace

final class ColombaCustomerWorkspaceTests: XCTestCase {
    func testAggregateModuleIsPublic() {
        _ = ColombaCustomerWorkspaceModule.self
    }
}
