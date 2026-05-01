@testable import ColombaCustomer
import XCTest

@MainActor
final class PhoneVerifyViewModelTests: XCTestCase {
    func test_e164Normalization_cases() throws {
        let cases = [
            ("079 123 45 67", "+41791234567"),
            ("+41 79 123 45 67", "+41791234567"),
            ("0041791234567", "+41791234567"),
            ("791234567", "+41791234567")
        ]
        for (input, expected) in cases {
            let model = PhoneVerifyViewModel(service: MockSMSVerifyService(), locale: .deCH)
            model.updatePhoneNumber(input)
            XCTAssertEqual(try model.normalizedPhoneNumber(), expected)
        }
    }

    func test_e164Normalization_invalidPhone() {
        let model = PhoneVerifyViewModel(service: MockSMSVerifyService(), locale: .deCH)
        model.updatePhoneNumber("abc")
        XCTAssertThrowsError(try model.normalizedPhoneNumber())
    }

    func test_resendCooldown_decrementsToZeroOver60Seconds() async {
        let model = PhoneVerifyViewModel(
            service: MockSMSVerifyService(),
            locale: .deCH
        )
        model.updatePhoneNumber("0791234567")
        await model.sendCode()
        XCTAssertEqual(model.resendCooldownSeconds, 60)
    }

    func test_resend_blockedWhileCooldownActive() async {
        let service = MockSMSVerifyService()
        let model = PhoneVerifyViewModel(service: service, locale: .deCH)
        model.updatePhoneNumber("0791234567")
        await model.sendCode()
        await model.resend()
        XCTAssertEqual(service.sendCount, 1)
    }

    func test_attemptsRemaining_decrementsOnWrongCode() async {
        let model = PhoneVerifyViewModel(
            service: MockSMSVerifyService(verifyError: SMSVerifyError.wrongCode),
            locale: .deCH
        )
        model.updatePhoneNumber("0791234567")
        await model.sendCode()
        model.updateOTP("123456")
        await model.verifyCode()
        XCTAssertEqual(model.attemptsRemaining, 4)
    }

    func test_attemptsRemaining_zero_transitionsToFailed() async {
        let model = PhoneVerifyViewModel(
            service: MockSMSVerifyService(verifyError: SMSVerifyError.wrongCode),
            locale: .deCH
        )
        model.updatePhoneNumber("0791234567")
        await model.sendCode()
        for _ in 0..<5 {
            model.updateOTP("123456")
            await model.verifyCode()
        }
        XCTAssertEqual(model.attemptsRemaining, 0)
        XCTAssertEqual(model.phase, .failed(reason: "Too many attempts"))
    }

    func test_challengeExpiry_surfacesExpiredState() async {
        let expired = SMSChallenge(challengeId: "expired", expiresAt: Date(timeIntervalSince1970: 1))
        let model = PhoneVerifyViewModel(service: MockSMSVerifyService(challenge: expired), locale: .deCH) {
            Date(timeIntervalSince1970: 2)
        }
        model.updatePhoneNumber("0791234567")
        await model.sendCode()
        model.updateOTP("123456")
        await model.verifyCode()
        XCTAssertEqual(model.phase, .failed(reason: "Code expired, tap Resend"))
    }

    func test_verifySuccess_persistsRefreshTokenToKeychain() async throws {
        let keychain = MockKeychain()
        let client = MockSMSVerifyClient()
        let service = SMSVerifyService(client: client, keychain: keychain)
        _ = try await service.sendCode(phoneE164: "+41791234567", locale: .deCH)
        _ = try await service.verifyCode(challengeId: "challenge", code: "123456")
        XCTAssertEqual(try keychain.string(forKey: SMSVerifyService.refreshTokenKey), "refresh-token")
    }
}

private final class MockSMSVerifyService: SMSVerifyServiceProtocol, @unchecked Sendable {
    private(set) var sendCount = 0
    private let challenge: SMSChallenge
    private let verifyError: Error?

    init(
        challenge: SMSChallenge = SMSChallenge(challengeId: "challenge", expiresAt: Date().addingTimeInterval(300)),
        verifyError: Error? = nil
    ) {
        self.challenge = challenge
        self.verifyError = verifyError
    }

    func sendCode(phoneE164: String, locale: AppLanguage) async throws -> SMSChallenge {
        sendCount += 1
        return challenge
    }

    func verifyCode(challengeId: String, code: String) async throws -> SMSVerifyResult {
        if let verifyError { throw verifyError }
        return SMSVerifyResult(verified: true, refreshToken: "refresh-token")
    }
}

private struct MockSMSVerifyClient: SMSVerifyClientProtocol {
    func sendCode(phoneE164: String, locale: AppLanguage) async throws -> SMSChallenge {
        SMSChallenge(challengeId: "challenge", expiresAt: Date().addingTimeInterval(300))
    }

    func verifyCode(challengeId: String, code: String) async throws -> SMSVerifyResult {
        SMSVerifyResult(verified: true, refreshToken: "refresh-token")
    }
}

private final class MockKeychain: KeychainStoring, @unchecked Sendable {
    private var values: [String: String] = [:]

    func setString(_ value: String, forKey key: String) throws { values[key] = value }
    func string(forKey key: String) throws -> String? { values[key] }
    func removeValue(forKey key: String) throws { values.removeValue(forKey: key) }
}
