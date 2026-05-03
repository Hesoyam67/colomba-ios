import ColombaCore
import SwiftUI

@main
struct ColombaCustomerApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @AppStorage(
        "colomba.onboarding.selectedLanguage"
    )
    private var selectedLanguageRaw = AppLanguage.deCH.rawValue
    @AppStorage(ColombaAppearance.storageKey)
    private var selectedAppearanceRaw = ColombaAppearance.system.rawValue

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
            .preferredColorScheme(ColombaAppearance(rawValue: selectedAppearanceRaw)?.colorScheme)
            .onOpenURL { url in
                #if canImport(GoogleSignIn)
                _ = GoogleSignInOAuthClient.handle(url: url)
                #endif
            }
        }
    }
}

enum ColombaAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "colomba.appearance.colorScheme"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
