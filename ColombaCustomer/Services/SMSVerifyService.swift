import Foundation
import Security

public protocol KeychainStoring: Sendable {
    func setString(_ value: String, forKey key: String) throws
    func string(forKey key: String) throws -> String?
    func removeValue(forKey key: String) throws
}

public struct DefaultKeychain: KeychainStoring, Sendable {
    public init() {}

    public func setString(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        var query = baseQuery(for: key)
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.status(status) }
    }

    public func string(forKey key: String) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw KeychainError.status(status) }
        return String(data: data, encoding: .utf8)
    }

    public func removeValue(forKey key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.status(status) }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "ch.colomba.customer.smsverify",
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
    }
}

public enum KeychainError: Error, Sendable, Equatable {
    case status(OSStatus)
}

public final class SMSVerifyService: SMSVerifyServiceProtocol, @unchecked Sendable {
    public static let challengeKey = "colomba.smsverify.challengeId"
    public static let refreshTokenKey = "colomba.smsverify.refreshToken"

    private let client: SMSVerifyClientProtocol
    private let keychain: KeychainStoring

    public init(
        client: SMSVerifyClientProtocol = TwilioSMSVerifyClient(),
        keychain: KeychainStoring = DefaultKeychain()
    ) {
        self.client = client
        self.keychain = keychain
    }

    public func sendCode(phoneE164: String, locale: AppLanguage) async throws -> SMSChallenge {
        let challenge = try await client.sendCode(phoneE164: phoneE164, locale: locale)
        try keychain.setString(challenge.challengeId, forKey: Self.challengeKey)
        return challenge
    }

    public func verifyCode(challengeId: String, code: String) async throws -> SMSVerifyResult {
        let result = try await client.verifyCode(challengeId: challengeId, code: code)
        if result.verified, let token = result.refreshToken {
            try keychain.setString(token, forKey: Self.refreshTokenKey)
            try keychain.removeValue(forKey: Self.challengeKey)
        }
        return result
    }

    public func storedChallengeId() throws -> String? {
        try keychain.string(forKey: Self.challengeKey)
    }
}
