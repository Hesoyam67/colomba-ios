/// A narrow endpoint contract used by feature packages before the Phase 6 backend hardening pass.
public struct APIEndpoint: Equatable, Sendable {
    public let method: HTTPMethod
    public let path: String

    public init(method: HTTPMethod, path: String) {
        self.method = method
        self.path = path
    }
}
