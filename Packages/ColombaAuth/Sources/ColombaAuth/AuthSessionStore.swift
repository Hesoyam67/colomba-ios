import Foundation

public protocol AuthSessionStore {
    func load() throws -> AuthSession?
    func save(_ session: AuthSession) throws
    func clear() throws
}

public final class InMemoryAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?

    public init(session: AuthSession? = nil) {
        self.session = session
    }

    public func load() throws -> AuthSession? {
        session
    }

    public func save(_ session: AuthSession) throws {
        self.session = session
    }

    public func clear() throws {
        session = nil
    }
}
