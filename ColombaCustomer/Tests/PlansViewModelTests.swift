@testable import ColombaCustomer
import ColombaNetworking
import XCTest

final class PlansViewModelTests: XCTestCase {
    @MainActor
    func testLoadPlansPublishesCatalog() async {
        let viewModel = PlansViewModel(repository: StubPlansRepository())

        await viewModel.load()

        XCTAssertEqual(viewModel.plans.map(\.tier), [.starter, .growth, .pro])
        XCTAssertEqual(viewModel.includedMinutesText(for: viewModel.plans[1]), "10'000 minutes included")
    }
}

private struct StubPlansRepository: PlansRepositoryProtocol {
    func loadPlans() async throws -> PlanList {
        .fixtureCatalog
    }
}
