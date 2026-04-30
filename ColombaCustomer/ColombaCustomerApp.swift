import ColombaCore
import SwiftUI

@main
struct ColombaCustomerApp: App {
    init() {
        ColdStart.markProcessStarted()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
