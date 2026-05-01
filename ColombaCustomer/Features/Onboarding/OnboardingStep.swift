import Foundation

public enum OnboardingStep: String, CaseIterable, Codable, Equatable, Sendable {
    case welcome
    case languagePicker
    case notificationsOptIn

    public var next: Self? {
        switch self {
        case .welcome:
            .languagePicker
        case .languagePicker:
            .notificationsOptIn
        case .notificationsOptIn:
            nil
        }
    }

    public var previous: Self? {
        switch self {
        case .welcome:
            nil
        case .languagePicker:
            .welcome
        case .notificationsOptIn:
            .languagePicker
        }
    }
}
