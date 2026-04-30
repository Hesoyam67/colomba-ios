import Foundation
import os

/// Measures process-start to first root-view appearance for the iOS app.
public enum ColdStart {
    private static let logger = Logger(subsystem: "ch.colomba.customer", category: "performance.cold-start")
    private static let processStart = ContinuousClock.now

    /// Force the start marker as early as possible from the app entry point.
    public static func markProcessStarted() {
        _ = processStart
    }

    /// Call once from `RootView.onAppear`.
    @discardableResult
    public static func markRootViewAppeared() -> Duration {
        let elapsed = processStart.duration(to: .now)
        let milliseconds = elapsed.components.seconds * 1_000
            + elapsed.components.attoseconds / 1_000_000_000_000_000
        logger.notice("COLOMBA_COLD_START_MS=\(milliseconds, privacy: .public)")
        return elapsed
    }
}
