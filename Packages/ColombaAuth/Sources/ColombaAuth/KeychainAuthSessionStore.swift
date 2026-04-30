import Foundation
import Security

public final class KeychainAuthSessionStore: AuthSessionStore {
    private let service: String
    private let account: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        service: String = "ch.colomba.customer.auth",
        account: String = "session"
    ) {
        self.service = service
        self.account = account
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> AuthSession? {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw AuthFailure.storageFailed("Keychain load failed with status \(status).")
        }
        guard let data = item as? Data else {
            throw AuthFailure.storageFailed("Keychain returned an unreadable session payload.")
        }
        return try decoder.decode(AuthSession.self, from: data)
    }

    public func save(_ session: AuthSession) throws {
        let data = try encoder.encode(session)
        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            try update(data)
            return
        }
        guard status == errSecSuccess else {
            throw AuthFailure.storageFailed("Keychain save failed with status \(status).")
        }
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthFailure.storageFailed("Keychain clear failed with status \(status).")
        }
    }

    private func update(_ data: Data) throws {
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            throw AuthFailure.storageFailed("Keychain update failed with status \(status).")
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
