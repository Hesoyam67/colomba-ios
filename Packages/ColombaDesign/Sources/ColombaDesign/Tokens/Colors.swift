import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension Color {
    /// Colomba semantic color namespace.
    static let colomba = ColombaColors()
}

public struct ColombaColors {
    public let primary = Color.colombaDynamic(light: 0xB5651D, dark: 0xD08A4A)
    public let accent = Color.colombaDynamic(light: 0x0F1115, dark: 0xFAFAF7)
    public let bg = ColombaBackgroundColors()
    public let text = ColombaTextColors()
    public let border = ColombaBorderColors()
    public let success = Color.colombaDynamic(light: 0x2F8F5E, dark: 0x56B884)
    public let warning = Color.colombaDynamic(light: 0xC8881C, dark: 0xE5A547)
    public let error = Color.colombaDynamic(light: 0xB23A2E, dark: 0xE15D4F)

    public init() {}
}

public struct ColombaBackgroundColors {
    public let base = Color.colombaDynamic(light: 0xFAFAF7, dark: 0x0F1115)
    public let card = Color.colombaDynamic(light: 0xFFFFFF, dark: 0x17181C)
    public let raised = Color.colombaDynamic(light: 0xF4F2EC, dark: 0x1F2025)
    public let modal = Color.colombaDynamic(light: 0xFFFFFF, dark: 0x22232A)

    public init() {}
}

public struct ColombaTextColors {
    public let primary = Color.colombaDynamic(light: 0x0F1115, dark: 0xFAFAF7)
    public let secondary = Color.colombaDynamic(light: 0x5A5C63, dark: 0xA8AAB2)
    public let tertiary = Color.colombaDynamic(light: 0x8C8E96, dark: 0x6E7079)

    public init() {}
}

public struct ColombaBorderColors {
    public let hairline = Color.colombaDynamic(light: 0xE6E4DE, dark: 0x2A2A2D)

    public init() {}
}

fileprivate extension Color {
    static func colombaDynamic(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            UIColor(colombaHex: traits.userInterfaceStyle == .dark ? dark : light)
        })
        #elseif canImport(AppKit)
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(colombaHex: isDark ? dark : light)
        })
        #else
        Color.colombaHex(light)
        #endif
    }

    static func colombaHex(_ hex: UInt32) -> Color {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(colombaHex hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
#elseif canImport(AppKit)
private extension NSColor {
    convenience init(colombaHex hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    }
}
#endif
