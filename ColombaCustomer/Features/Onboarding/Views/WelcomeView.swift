import ColombaDesign
import SwiftUI

public struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        let copy = OnboardingCopy.copy(for: viewModel.selectedLanguage)

        VStack(spacing: 28) {
            Spacer(minLength: 24)

            Text("Colomba")
                .font(.custom("Fraunces", size: 44, relativeTo: .largeTitle).weight(.bold))
                .foregroundStyle(Color.colomba.primary)
                .accessibilityLabel("Colomba")

            VStack(spacing: 12) {
                Text(copy.welcomeTitle)
                    .font(.custom("Fraunces", size: 38, relativeTo: .largeTitle).weight(.bold))
                    .foregroundStyle(Color.colomba.text.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboarding.welcome.title")

                Text(copy.welcomeBody)
                    .font(.custom("Inter", size: 18, relativeTo: .body))
                    .foregroundStyle(Color.colomba.text.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboarding.welcome.body")
            }

            Spacer(minLength: 16)

            Button {
                viewModel.advance()
            } label: {
                Text(copy.welcomeCTA)
                    .font(.custom("Inter", size: 17, relativeTo: .body).weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding.welcome.getStarted")
            .accessibilityLabel(copy.welcomeCTA)
            .accessibilityHint("Moves to language selection")
        }
        .padding(32)
        .frame(maxWidth: 560, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colomba.bg.base)
    }
}
