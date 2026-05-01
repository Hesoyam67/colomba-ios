import Foundation

/// Compile-only Phase 4 onboarding step model.
///
/// This intentionally stays small until Coder's container packet lands.
/// The cases here define the minimum sequence needed by the scaffolded
/// `OnboardingContainerView` without committing to final copy, routing, or
/// persistence behavior.
enum OnboardingStep: String, CaseIterable, Identifiable, Hashable {
    case welcome
    case language
    case notifications

    var id: String {
        rawValue
    }

    var sortOrder: Int {
        switch self {
        case .welcome:
            0
        case .language:
            1
        case .notifications:
            2
        }
    }

    var accessibilityIdentifier: String {
        "onboarding.step.\(rawValue)"
    }

    // swiftlint:disable:next todo
    // TODO PHASE4: Replace placeholder titles with packet-backed localization
    // and analytics metadata once the onboarding container contract arrives.
    var placeholderTitleKey: String {
        switch self {
        case .welcome:
            "onboarding.welcome.title"
        case .language:
            "onboarding.language.title"
        case .notifications:
            "onboarding.notifications.cta"
        }
    }
}
