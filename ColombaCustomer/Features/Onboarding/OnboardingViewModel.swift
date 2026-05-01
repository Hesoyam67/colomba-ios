import Combine
import Foundation

/// Compile-only Phase 4 onboarding state holder.
///
/// The real implementation is expected to be supplied by Coder's container
/// packet. This stub only exposes enough state for a placeholder container to
/// compile and preview safely.
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var selectedStep: OnboardingStep
    @Published private(set) var completedSteps: Set<OnboardingStep>

    let steps: [OnboardingStep]

    init(
        selectedStep: OnboardingStep = .welcome,
        completedSteps: Set<OnboardingStep> = []
    ) {
        self.selectedStep = selectedStep
        self.completedSteps = completedSteps
        self.steps = OnboardingStep.allCases.sorted { $0.sortOrder < $1.sortOrder }
    }

    func markCurrentStepComplete() {
        completedSteps.insert(selectedStep)
    }

    func moveToNextStep() {
        markCurrentStepComplete()

        guard let currentIndex = steps.firstIndex(of: selectedStep) else {
            selectedStep = .welcome
            return
        }

        let nextIndex = steps.index(after: currentIndex)
        guard steps.indices.contains(nextIndex) else {
            // swiftlint:disable:next todo
            // TODO PHASE4: Route to the authenticated app shell when complete.
            return
        }

        selectedStep = steps[nextIndex]
    }

    // swiftlint:disable:next todo
    // TODO PHASE4: Inject real services for locale selection, notification
    // permission handling, persistence, and completion analytics.
}
