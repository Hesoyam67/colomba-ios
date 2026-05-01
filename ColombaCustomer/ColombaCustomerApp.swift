import ColombaCore
import SwiftUI

@main
struct ColombaCustomerApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    init() {
        ColdStart.markProcessStarted()
    }

    var body: some Scene {
        WindowGroup {
            if onboardingViewModel.isComplete {
                RootView()
            } else {
                OnboardingContainerView(viewModel: onboardingViewModel)
            }
        }
    }
}
