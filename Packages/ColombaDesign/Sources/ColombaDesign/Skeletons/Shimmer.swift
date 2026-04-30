import SwiftUI

public struct ColombaShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1.0

    private let active: Bool

    public init(active: Bool = true) {
        self.active = active
    }

    public func body(content: Content) -> some View {
        if active, !reduceMotion {
            content
                .overlay {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        LinearGradient(
                            colors: [
                                .white.opacity(0.0),
                                .white.opacity(0.28),
                                .white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .rotationEffect(.degrees(18))
                        .offset(x: phase * max(width, 1))
                    }
                    .allowsHitTesting(false)
                }
                .mask(content)
                .onAppear {
                    phase = -1.0
                    withAnimation(ColombaMotion.skeleton) {
                        phase = 1.0
                    }
                }
        } else {
            content
                .animation(ColombaMotion.respectingReduceMotion(.linear(duration: 0), reduceMotion: reduceMotion), value: active)
        }
    }
}

public extension View {
    /// Applies the Colomba skeleton shimmer cycle.
    func colombaShimmer(active: Bool = true) -> some View {
        modifier(ColombaShimmerModifier(active: active))
    }
}
