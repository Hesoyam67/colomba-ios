import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Equatable, Sendable {
    case deCH = "de-CH"
    case frCH = "fr-CH"
    case itCH = "it-CH"
    case en = "en"

    public var displayName: String {
        switch self {
        case .deCH:
            "Schweizerdeutsch"
        case .frCH:
            "Français"
        case .itCH:
            "Italiano"
        case .en:
            "English"
        }
    }

    public var bundleIdentifier: String {
        rawValue
    }
}
