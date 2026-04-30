import Foundation
import SwiftUI

public enum ColombaMotion {
    public enum Duration {
        public static let micro: TimeInterval = 0.120
        public static let short: TimeInterval = 0.200
        public static let medium: TimeInterval = 0.320
        public static let long: TimeInterval = 0.480
        public static let skeleton: TimeInterval = 1.200
    }

    public static func standard(duration: TimeInterval = Duration.short) -> Animation {
        .timingCurve(0.32, 0.72, 0.0, 1.0, duration: duration)
    }

    public static func emphasized(duration: TimeInterval = Duration.medium) -> Animation {
        .timingCurve(0.2, 0.0, 0.0, 1.0, duration: duration)
    }

    public static func exit(duration: TimeInterval = Duration.short) -> Animation {
        .timingCurve(0.4, 0.0, 1.0, 1.0, duration: duration)
    }

    public static let micro = standard(duration: Duration.micro)
    public static let short = standard(duration: Duration.short)
    public static let medium = standard(duration: Duration.medium)
    public static let long = standard(duration: Duration.long)
    public static let skeleton = standard(duration: Duration.skeleton).repeatForever(autoreverses: false)

    public static func respectingReduceMotion(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0) : animation
    }
}
