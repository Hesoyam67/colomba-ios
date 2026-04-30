import ColombaCore
import SwiftUI

@main
struct ColombaCustomerApp: App {
    @State private var environment = AppEnvironment()

    init() {
        ColdStart.markProcessStarted()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
    }
}
