@testable import ColombaNetworking
import XCTest

final class PlansClientTests: XCTestCase {
    func testPlansEndpointContract() {
        XCTAssertEqual(PlansAPI.listPlans, APIEndpoint(method: .get, path: "/plans"))
    }

    func testListPlansReturnsFixtureCatalog() async throws {
        let catalog = try await FixturePlansClient().listPlans()

        XCTAssertEqual(catalog.currency, "CHF")
        XCTAssertEqual(catalog.plans.map(\.tier), [.starter, .growth, .pro])
        XCTAssertEqual(catalog.topUps.first?.tier, .topUp)
    }

    func testFixturePersonasDecodeAndRoundTrip() throws {
        let json = """
        [
          {
            "id":"persona_small_beiz", "label":"Small Beiz", "locale":"de", "currency":"CHF",
            "businessType":"restaurant", "staffCount":5, "planHint":"starter"
          },
          {
            "id":"persona_mid_bistro", "label":"Mid Bistro", "locale":"fr", "currency":"CHF",
            "businessType":"restaurant", "staffCount":18, "planHint":"growth"
          },
          {
            "id":"persona_hair_salon_chain", "label":"Hair Salon Chain", "locale":"it", "currency":"CHF",
            "businessType":"beauty_chain", "staffCount":42, "planHint":"pro"
          }
        ]
        """
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let personas = try decoder.decode([FixturePersona].self, from: Data(json.utf8))
        let roundTrip = try decoder.decode([FixturePersona].self, from: encoder.encode(personas))

        XCTAssertEqual(
            roundTrip.map(\.id),
            ["persona_small_beiz", "persona_mid_bistro", "persona_hair_salon_chain"]
        )
        XCTAssertEqual(roundTrip.map(\.planHint), [.starter, .growth, .pro])
    }
}
