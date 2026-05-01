@testable import ColombaCustomer
import XCTest

final class SMSVerifyServiceTests: XCTestCase {
    func test_sendCode_persistsChallengeIdToKeychain() async throws {
        let keychain = MockKeychain()
        let service = SMSVerifyService(client: MockClient(), keychain: keychain)
        _ = try await service.sendCode(phoneE164: "+41791234567", locale: .deCH)
        XCTAssertEqual(try keychain.string(forKey: SMSVerifyService.challengeKey), "challenge")
    }

    func test_verifyCode_clearsChallengeIdOnSuccess() async throws {
        let keychain = MockKeychain()
        try keychain.setString("challenge", forKey: SMSVerifyService.challengeKey)
        let service = SMSVerifyService(client: MockClient(), keychain: keychain)
        _ = try await service.verifyCode(challengeId: "challenge", code: "123456")
        XCTAssertNil(try keychain.string(forKey: SMSVerifyService.challengeKey))
    }

    func test_verifyCode_keepsChallengeIdOnWrongCode() async throws {
        let keychain = MockKeychain()
        try keychain.setString("challenge", forKey: SMSVerifyService.challengeKey)
        let service = SMSVerifyService(client: MockClient(error: SMSVerifyError.wrongCode), keychain: keychain)
        do {
            _ = try await service.verifyCode(challengeId: "challenge", code: "000000")
            XCTFail("Expected wrong-code error")
        } catch SMSVerifyError.wrongCode {
            XCTAssertEqual(try keychain.string(forKey: SMSVerifyService.challengeKey), "challenge")
        }
    }
}

private struct MockClient: SMSVerifyClientProtocol {
    let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func sendCode(phoneE164: String, locale: AppLanguage) async throws -> SMSChallenge {
        SMSChallenge(challengeId: "challenge", expiresAt: Date().addingTimeInterval(300))
    }

    func verifyCode(challengeId: String, code: String) async throws -> SMSVerifyResult {
        if let error { throw error }
        return SMSVerifyResult(verified: true, refreshToken: "refresh-token")
    }
}

private final class MockKeychain: KeychainStoring, @unchecked Sendable {
    private var values: [String: String] = [:]

    func setString(_ value: String, forKey key: String) throws { values[key] = value }
    func string(forKey key: String) throws -> String? { values[key] }
    func removeValue(forKey key: String) throws { values.removeValue(forKey: key) }
}
