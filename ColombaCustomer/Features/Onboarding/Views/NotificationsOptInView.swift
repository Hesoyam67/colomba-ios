import ColombaDesign
import SwiftUI
import UserNotifications

public struct NotificationsOptInView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        let copy = OnboardingCopy.copy(for: viewModel.selectedLanguage)

        VStack(spacing: 24) {
            Spacer(minLength: 20)

            Image(systemName: "bell.badge")
                .font(.custom("Inter", size: 52, relativeTo: .largeTitle))
                .foregroundStyle(Color.colomba.primary)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(copy.notificationsTitle)
                    .font(.custom("Fraunces", size: 34, relativeTo: .largeTitle).weight(.bold))
                    .foregroundStyle(Color.colomba.text.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboarding.notificationsOptIn.title")

                Text(copy.notificationsBody)
                    .font(.custom("Inter", size: 17, relativeTo: .body))
                    .foregroundStyle(Color.colomba.text.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboarding.notificationsOptIn.body")
            }

            Spacer(minLength: 12)

            VStack(spacing: 12) {
                Button {
                    Task {
                        let authorized = await requestAuthorization()
                        viewModel.recordNotificationsDecision(authorized: authorized)
                        viewModel.advance()
                    }
                } label: {
                    Text(copy.notificationsAllow)
                        .font(.custom("Inter", size: 17, relativeTo: .body).weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("onboarding.notificationsOptIn.allow")
                .accessibilityLabel(copy.notificationsAllow)
                .accessibilityHint("Requests notification permission and finishes onboarding")

                Button {
                    viewModel.recordNotificationsDecision(authorized: false)
                    viewModel.advance()
                } label: {
                    Text(copy.notificationsSkip)
                        .font(.custom("Inter", size: 16, relativeTo: .body).weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("onboarding.notificationsOptIn.skip")
                .accessibilityLabel(copy.notificationsSkip)
                .accessibilityHint("Skips notifications and finishes onboarding")

                Button {
                    viewModel.back()
                } label: {
                    Text(copy.notificationsBack)
                        .font(.custom("Inter", size: 15, relativeTo: .body).weight(.semibold))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("onboarding.notificationsOptIn.back")
                .accessibilityLabel(copy.notificationsBack)
                .accessibilityHint("Returns to language selection")
            }
        }
        .padding(32)
        .frame(maxWidth: 560, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.colomba.bg.base)
    }

    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}
