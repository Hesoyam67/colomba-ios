@testable import ColombaCustomer
import XCTest

final class PlansSnapshotTests: XCTestCase {
    func testRequiredSnapshotScenariosAreDeclared() {
        let scenarios = PlansSnapshotScenario.required

        XCTAssertEqual(scenarios.count, 6)
        XCTAssertTrue(scenarios.contains(.init(screen: "plans-list", scheme: "light", dynamicType: "medium")))
        XCTAssertTrue(scenarios.contains(.init(screen: "plans-list", scheme: "dark", dynamicType: "xxxLarge")))
        XCTAssertTrue(scenarios.contains(.init(screen: "plans-detail", scheme: "light", dynamicType: "medium")))
        XCTAssertTrue(scenarios.contains(.init(screen: "plans-detail", scheme: "dark", dynamicType: "xxxLarge")))
    }
}

struct PlansSnapshotScenario: Hashable {
    let screen: String
    let scheme: String
    let dynamicType: String

    static let required: Set<Self> = [
        .init(screen: "plans-list", scheme: "light", dynamicType: "medium"),
        .init(screen: "plans-list", scheme: "light", dynamicType: "xxxLarge"),
        .init(screen: "plans-list", scheme: "dark", dynamicType: "medium"),
        .init(screen: "plans-list", scheme: "dark", dynamicType: "xxxLarge"),
        .init(screen: "plans-detail", scheme: "light", dynamicType: "medium"),
        .init(screen: "plans-detail", scheme: "dark", dynamicType: "xxxLarge")
    ]
}
