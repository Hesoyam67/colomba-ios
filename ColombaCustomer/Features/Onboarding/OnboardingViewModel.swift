import Combine
import Foundation

public protocol OnboardingPersistence {
    func loadCurrentStep() -> OnboardingStep?
    func saveCurrentStep(_ step: OnboardingStep)
    func loadSelectedLanguage() -> AppLanguage?
    func saveSelectedLanguage(_ language: AppLanguage)
    func loadNotificationsDecisionMade() -> Bool
    func saveNotificationsDecision(authorized: Bool)
    func clear()
}

public struct UserDefaultsOnboardingPersistence: OnboardingPersistence {
    private enum Key {
        static let currentStep = "colomba.onboarding.currentStep"
        static let selectedLanguage = "colomba.onboarding.selectedLanguage"
        static let notificationsDecisionMade = "colomba.onboarding.notificationsDecisionMade"
        static let notificationsAuthorized = "colomba.onboarding.notificationsAuthorized"
        static let appleLanguages = "AppleLanguages"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadCurrentStep() -> OnboardingStep? {
        defaults.string(forKey: Key.currentStep).flatMap(OnboardingStep.init(rawValue:))
    }

    public func saveCurrentStep(_ step: OnboardingStep) {
        defaults.set(step.rawValue, forKey: Key.currentStep)
    }

    public func loadSelectedLanguage() -> AppLanguage? {
        defaults.string(forKey: Key.selectedLanguage).flatMap(AppLanguage.init(rawValue:))
    }

    public func saveSelectedLanguage(_ language: AppLanguage) {
        defaults.set(language.rawValue, forKey: Key.selectedLanguage)
        defaults.set([language.bundleIdentifier], forKey: Key.appleLanguages)
    }

    public func loadNotificationsDecisionMade() -> Bool {
        defaults.bool(forKey: Key.notificationsDecisionMade)
    }

    public func saveNotificationsDecision(authorized: Bool) {
        defaults.set(true, forKey: Key.notificationsDecisionMade)
        defaults.set(authorized, forKey: Key.notificationsAuthorized)
    }

    public func clear() {
        defaults.removeObject(forKey: Key.currentStep)
        defaults.removeObject(forKey: Key.selectedLanguage)
        defaults.removeObject(forKey: Key.notificationsDecisionMade)
        defaults.removeObject(forKey: Key.notificationsAuthorized)
        defaults.removeObject(forKey: Key.appleLanguages)
    }
}

public final class OnboardingViewModel: ObservableObject {
    @Published public private(set) var currentStep: OnboardingStep
    @Published public private(set) var selectedLanguage: AppLanguage?
    @Published public private(set) var notificationsDecisionMade: Bool

    private let persistence: OnboardingPersistence

    public var isComplete: Bool {
        currentStep == .notificationsOptIn && notificationsDecisionMade
    }

    public init(persistence: OnboardingPersistence = UserDefaultsOnboardingPersistence()) {
        self.persistence = persistence
        self.currentStep = persistence.loadCurrentStep() ?? .welcome
        self.selectedLanguage = persistence.loadSelectedLanguage()
        self.notificationsDecisionMade = persistence.loadNotificationsDecisionMade()
    }

    public func advance() {
        guard let next = currentStep.next else {
            persistence.saveCurrentStep(currentStep)
            return
        }

        currentStep = next
        persistence.saveCurrentStep(next)
    }

    public func back() {
        guard let previous = currentStep.previous else {
            persistence.saveCurrentStep(currentStep)
            return
        }

        currentStep = previous
        persistence.saveCurrentStep(previous)
    }

    public func selectLanguage(_ lang: AppLanguage) {
        selectedLanguage = lang
        persistence.saveSelectedLanguage(lang)
    }

    public func recordNotificationsDecision(authorized: Bool) {
        notificationsDecisionMade = true
        persistence.saveNotificationsDecision(authorized: authorized)
        persistence.saveCurrentStep(currentStep)
    }

    public func reset() {
        persistence.clear()
        currentStep = .welcome
        selectedLanguage = nil
        notificationsDecisionMade = false
    }
}
