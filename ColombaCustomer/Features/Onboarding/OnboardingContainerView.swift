import SwiftUI

/// Compile-only Phase 4 onboarding container placeholder.
///
/// This view deliberately avoids final visuals and business logic. It exists so
/// the feature directory and entry points are ready for Coder's container packet
/// without blocking on the missing implementation details.
struct OnboardingContainerView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel = OnboardingViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        TabView(selection: $viewModel.selectedStep) {
            ForEach(viewModel.steps) { step in
                placeholderPage(for: step)
                    .tag(step)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .accessibilityIdentifier("onboarding.container")
    }

    private func placeholderPage(for step: OnboardingStep) -> some View {
        VStack(spacing: 24) {
            Text(LocalizedStringKey(step.placeholderTitleKey))
                .font(.title)
                .multilineTextAlignment(.center)

            Text("TODO PHASE4")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(LocalizedStringKey("onboarding.notifications.cta")) {
                viewModel.moveToNextStep()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .accessibilityIdentifier(step.accessibilityIdentifier)
    }

    // swiftlint:disable:next todo
    // TODO PHASE4: Replace placeholder pages with the final container wiring,
    // design tokens, transitions, and routing once the packet lands.
}

#Preview {
    OnboardingContainerView()
}
