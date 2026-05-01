import SwiftUI

public struct OnboardingContainerView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    public init(viewModel: OnboardingViewModel = OnboardingViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            switch viewModel.currentStep {
            case .welcome:
                WelcomeView(viewModel: viewModel)
                    .transition(transition)
            case .languagePicker:
                LanguagePickerView(viewModel: viewModel)
                    .transition(transition)
            case .notificationsOptIn:
                NotificationsOptInView(viewModel: viewModel)
                    .transition(transition)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.currentStep)
        .accessibilityIdentifier("onboarding.container")
    }

    private var transition: AnyTransition {
        reduceMotion ? .identity : .opacity
    }
}

#Preview {
    OnboardingContainerView()
}
