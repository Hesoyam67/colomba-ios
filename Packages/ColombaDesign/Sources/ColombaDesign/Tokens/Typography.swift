import SwiftUI

public extension Font {
    /// Colomba typography namespace.
    static let colomba = ColombaTypography()
}

public struct ColombaTypography {
    public let display = Font.largeTitle.weight(.bold)
    public let titleLg = Font.title.weight(.bold)
    public let titleMd = Font.title2.weight(.semibold)
    public let bodyLg = Font.body
    public let bodyMd = Font.callout
    public let caption = Font.caption.weight(.medium)
    public let micro = Font.caption2.weight(.semibold)

    public init() {}

    /// Numeric override for usage and billing figures: dynamic type, SF Mono, tabular digits.
    public func numeric(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(dynamicNumericStyle(for: size), design: .monospaced, weight: weight).monospacedDigit()
    }

    /// Default billing figure style.
    public var billingFigure: Font {
        Font.system(.title2, design: .monospaced, weight: .semibold).monospacedDigit()
    }

    private func dynamicNumericStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 28...:
            .title
        case 22..<28:
            .title2
        case 17..<22:
            .body
        case 13..<17:
            .callout
        default:
            .caption
        }
    }
}

public extension Font {
    /// Numeric helper for one-off billing and usage figures.
    static func colombaNumeric(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.colomba.numeric(size: size, weight: weight)
    }
}
