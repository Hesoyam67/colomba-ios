import SwiftUI

public extension Font {
    /// Colomba typography namespace.
    static let colomba = ColombaTypography()
}

public struct ColombaTypography {
    public let display = Font.system(size: 34, weight: .bold, design: .default)
    public let titleLg = Font.system(size: 28, weight: .bold, design: .default)
    public let titleMd = Font.system(size: 22, weight: .semibold, design: .default)
    public let bodyLg = Font.system(size: 17, weight: .regular, design: .default)
    public let bodyMd = Font.system(size: 15, weight: .regular, design: .default)
    public let caption = Font.system(size: 13, weight: .medium, design: .default)
    public let micro = Font.system(size: 11, weight: .semibold, design: .default)

    public init() {}

    /// Numeric override for usage and billing figures: SF Mono with tabular digits.
    public func numeric(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced).monospacedDigit()
    }

    /// Default billing figure style.
    public var billingFigure: Font {
        numeric(size: 22, weight: .semibold)
    }
}

public extension Font {
    /// Numeric helper for one-off billing and usage figures.
    static func colombaNumeric(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.colomba.numeric(size: size, weight: weight)
    }
}
