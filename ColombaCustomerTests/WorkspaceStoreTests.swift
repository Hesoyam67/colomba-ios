@testable import ColombaCustomer
import XCTest

@MainActor
final class WorkspaceStoreTests: XCTestCase {
    func testUpsertPersistsWorkspaceIntoDefaults() {
        let defaults = UserDefaults(suiteName: "workspace-store-\(UUID().uuidString)")!
        let store = WorkspaceStore(defaults: defaults, key: "test.workspaces")
        var workspace = Workspace.draft()
        workspace.name = "Papu Bistro"

        store.upsert(workspace)

        let restored = WorkspaceStore(defaults: defaults, key: "test.workspaces")
        XCTAssertTrue(restored.workspaces.contains { $0.name == "Papu Bistro" })
    }


    func testWorkspaceDecodeKeepsCompatibilityWithSavedPreSheetsJSON() throws {
        let json = """
        [{
          "id":"legacy",
          "name":"Legacy Bistro",
          "location":"Basel",
          "businessKind":"Restaurant workspace",
          "symbolName":"fork.knife.circle.fill",
          "reservations":[],
          "tables":[]
        }]
        """.data(using: .utf8)!

        let workspaces = try JSONDecoder().decode([Workspace].self, from: json)

        XCTAssertEqual(workspaces.first?.googleSheetsSpreadsheetID, "")
        XCTAssertEqual(workspaces.first?.googleSheetsRange, Workspace.defaultGoogleSheetsRange)
    }

    func testWorkspaceSheetRowFactoryBuildsReservationRows() {
        var workspace = Workspace.sampleWorkspaces[0]
        workspace.googleSheetsSpreadsheetID = " sheet-123 "
        workspace.googleSheetsRange = " Bookings!A:F "

        let rows = WorkspaceSheetRowFactory.rows(for: workspace)

        XCTAssertEqual(rows.count, workspace.reservations.count)
        XCTAssertEqual(rows.first?.spreadsheetID, "sheet-123")
        XCTAssertEqual(rows.first?.range, "Bookings!A:F")
        XCTAssertEqual(rows.first?.values.first, "Osteria Milano Basel")
        XCTAssertEqual(rows.first?.values[2], workspace.reservations[0].guestName)
    }

    func testSyncFromCloudReplacesLocalWorkspacesWhenRemoteExists() async {
        var remote = Workspace.draft()
        remote.name = "Cloud Workspace"
        let store = WorkspaceStore(
            defaults: UserDefaults(suiteName: "workspace-sync-\(UUID().uuidString)")!,
            key: "test.workspaces",
            syncClient: StubWorkspaceSyncClient(remoteWorkspaces: [remote])
        )

        await store.syncFromCloud()

        XCTAssertEqual(store.workspaces.map(\.name), ["Cloud Workspace"])
        XCTAssertTrue(store.syncMessage.contains("Cloud sync complete"))
    }
}

private struct StubWorkspaceSyncClient: WorkspaceSyncClientProtocol {
    let remoteWorkspaces: [Workspace]

    func listWorkspaces() async throws -> [Workspace] {
        remoteWorkspaces
    }

    func upsertWorkspace(_ workspace: Workspace) async throws {}
}
