import ColombaNetworking
import Foundation

struct PortalSessionService: Sendable {
    enum PortalSessionError: Error, Equatable, Sendable {
        case invalidScheme
        case expired

        var userMessage: String {
            switch self {
            case .invalidScheme:
                "The billing portal link is invalid. Please try again."
            case .expired:
                "The billing portal link expired. Please request a new one."
            }
        }
    }

    private let billingClient: BillingClient
    private let returnURL: URL
    private let now: @Sendable () -> Date

    init(
        billingClient: BillingClient = FixtureBillingClient(),
        returnURL: URL = URL(string: "colomba://billing/return") ?? URL(fileURLWithPath: "/billing/return"),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.billingClient = billingClient
        self.returnURL = returnURL
        self.now = now
    }

    func createPortalURL() async throws -> URL {
        let session = try await billingClient.createPortalSession(returnUrl: returnURL)
        guard session.url.scheme == "https" else {
            throw PortalSessionError.invalidScheme
        }
        guard session.expiresAt > now() else {
            throw PortalSessionError.expired
        }
        return session.url
    }
}
