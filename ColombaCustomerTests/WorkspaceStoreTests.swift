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
