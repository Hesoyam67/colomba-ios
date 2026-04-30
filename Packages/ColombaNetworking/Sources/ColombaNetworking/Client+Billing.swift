import Foundation

public enum BillingAPI {
    public static let createPortalSession = APIEndpoint(method: .post, path: "/billing/portal")
}

public protocol BillingClient: Sendable {
    func createPortalSession(returnUrl: URL) async throws -> BillingPortalSession
}

public struct FixtureBillingClient: BillingClient {
    public let session: BillingPortalSession

    public init(session: BillingPortalSession? = nil) {
        self.session = session ?? BillingPortalSession(
            url: URL(fileURLWithPath: "/mock/stripe/customer-portal-session"),
            expiresAt: Date(timeIntervalSince1970: 1_777_523_600)
        )
    }

    public func createPortalSession(returnUrl: URL) async throws -> BillingPortalSession {
        session
    }
}
