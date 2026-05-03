import ColombaCore
import SwiftUI

@main
struct ColombaCustomerApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @AppStorage(
        "colomba.onboarding.selectedLanguage"
    )
    private var selectedLanguageRaw = AppLanguage.deCH.rawValue

    init() {
        ColdStart.markProcessStarted()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingViewModel.isComplete {
                    RootView()
                } else {
                    OnboardingContainerView(viewModel: onboardingViewModel)
                }
            }
            .environment(\.locale, Locale(identifier: selectedLanguageRaw))
        }
    }
}
