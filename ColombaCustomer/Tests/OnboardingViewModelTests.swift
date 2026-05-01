@testable import ColombaCustomer
import XCTest

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func test_initialState_isWelcome() {
        let viewModel = OnboardingViewModel(persistence: makePersistence())

        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertFalse(viewModel.isComplete)
    }

    func test_advance_followsLinearSequence() {
        let viewModel = OnboardingViewModel(persistence: makePersistence())

        viewModel.advance()
        XCTAssertEqual(viewModel.currentStep, .languagePicker)

        viewModel.advance()
        XCTAssertEqual(viewModel.currentStep, .notificationsOptIn)
    }

    func test_advance_pastLastStep_isNoOp() {
        let viewModel = OnboardingViewModel(persistence: makePersistence())

        viewModel.advance()
        viewModel.advance()
        viewModel.advance()

        XCTAssertEqual(viewModel.currentStep, .notificationsOptIn)
    }

    func test_back_fromFirstStep_isNoOp() {
        let viewModel = OnboardingViewModel(persistence: makePersistence())

        viewModel.back()

        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    func test_selectLanguage_persists() {
        let defaults = makeDefaults()
        let viewModel = OnboardingViewModel(persistence: makePersistence(defaults: defaults))

        viewModel.selectLanguage(.frCH)

        XCTAssertEqual(defaults.string(forKey: "colomba.onboarding.selectedLanguage"), "fr-CH")
        XCTAssertEqual(defaults.stringArray(forKey: "AppleLanguages"), ["fr-CH"])
    }

    func test_recordNotificationsDecision_persists() {
        let defaults = makeDefaults()
        let viewModel = OnboardingViewModel(persistence: makePersistence(defaults: defaults))

        viewModel.advance()
        viewModel.advance()
        viewModel.recordNotificationsDecision(authorized: true)

        XCTAssertTrue(defaults.bool(forKey: "colomba.onboarding.notificationsDecisionMade"))
        XCTAssertTrue(viewModel.isComplete)
    }

    func test_reset_returnsToWelcome() {
        let viewModel = OnboardingViewModel(persistence: makePersistence())

        viewModel.advance()
        viewModel.selectLanguage(.itCH)
        viewModel.recordNotificationsDecision(authorized: false)
        viewModel.reset()

        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertNil(viewModel.selectedLanguage)
        XCTAssertFalse(viewModel.notificationsDecisionMade)
    }

    func test_currentStep_restoredOnRelaunch() {
        let defaults = makeDefaults()
        let firstLaunch = OnboardingViewModel(persistence: makePersistence(defaults: defaults))

        firstLaunch.advance()
        firstLaunch.advance()
        let secondLaunch = OnboardingViewModel(persistence: makePersistence(defaults: defaults))

        XCTAssertEqual(secondLaunch.currentStep, .notificationsOptIn)
    }

    func test_isComplete_falseUntilNotificationsDecisionMade() {
        let viewModel = OnboardingViewModel(persistence: makePersistence())

        viewModel.advance()
        viewModel.advance()

        XCTAssertEqual(viewModel.currentStep, .notificationsOptIn)
        XCTAssertFalse(viewModel.isComplete)
    }

    func test_selectLanguage_persistsAcrossInit() {
        let defaults = makeDefaults()
        let firstLaunch = OnboardingViewModel(persistence: makePersistence(defaults: defaults))

        firstLaunch.selectLanguage(.en)
        let secondLaunch = OnboardingViewModel(persistence: makePersistence(defaults: defaults))

        XCTAssertEqual(secondLaunch.selectedLanguage, .en)
    }

    private func makePersistence(defaults: UserDefaults? = nil) -> UserDefaultsOnboardingPersistence {
        UserDefaultsOnboardingPersistence(defaults: defaults ?? makeDefaults())
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "colomba.onboarding.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to create isolated UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
