/// Phase 2 auth endpoints. Transport remains mocked until the Phase 6 hardening gate.
public enum AuthAPI {
    public static let appleExchange = APIEndpoint(method: .post, path: "/auth/apple")
    public static let magicLinkRequest = APIEndpoint(method: .post, path: "/auth/magic-link/request")
    public static let magicLinkVerify = APIEndpoint(method: .post, path: "/auth/magic-link/verify")
    public static let sessionRefresh = APIEndpoint(method: .post, path: "/auth/session/refresh")
}
