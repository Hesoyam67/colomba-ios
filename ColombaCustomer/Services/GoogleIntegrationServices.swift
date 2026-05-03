import ColombaAuth
import Foundation
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(UIKit)
import UIKit
#endif

public struct GoogleOAuthToken: Equatable, Sendable {
    public let accessToken: String
    public let idToken: String?
    public let email: String?
    public let fullName: String?
    public let scopes: Set<String>

    public init(
        accessToken: String,
        idToken: String? = nil,
        email: String? = nil,
        fullName: String? = nil,
        scopes: Set<String>
    ) {
        self.accessToken = accessToken
        self.idToken = idToken
        self.email = email
        self.fullName = fullName
        self.scopes = scopes
    }
}

public protocol GoogleOAuthAuthorizing: Sendable {
    func authorize(scopes: Set<String>) async throws -> GoogleOAuthToken
}

public enum GoogleIntegrationError: Error, Equatable, Sendable {
    case missingClientID
    case missingPresentingViewController
    case unsupportedAuthProvider(AuthProvider)
    case missingAppleCalendarAdapter
}

public final class MockGoogleOAuthClient: GoogleOAuthAuthorizing, @unchecked Sendable {
    public private(set) var requestedScopes: [Set<String>] = []
    private let tokenValue: String

    public init(tokenValue: String = "mock-google-access-token") {
        self.tokenValue = tokenValue
    }

    public func authorize(scopes: Set<String>) async throws -> GoogleOAuthToken {
        requestedScopes.append(scopes)
        return GoogleOAuthToken(accessToken: tokenValue, scopes: scopes)
    }
}

public struct GoogleSignInConfiguration: Equatable, Sendable {
    public let clientID: String?

    public init(clientID: String?) {
        self.clientID = clientID
    }

    public static func from(bundle: Bundle = .main) -> Self {
        Self(
            clientID: Self.resolveClientID(
                bundleIdentifier: bundle.bundleIdentifier,
                infoDictionary: bundle.infoDictionary ?? [:]
            )
        )
    }

    public static func resolveClientID(
        bundleIdentifier: String?,
        infoDictionary: [String: Any]
    ) -> String? {
        let productionClientID = infoDictionary["ColombaGoogleOAuthProductionClientID"] as? String
        let localDevClientID = infoDictionary["ColombaGoogleOAuthLocalDevClientID"] as? String

        if bundleIdentifier == "com.hesoyam.colomba.dev", let localDevClientID, localDevClientID.isEmpty == false {
            return localDevClientID
        }

        if let productionClientID, productionClientID.isEmpty == false {
            return productionClientID
        }

        return localDevClientID?.isEmpty == false ? localDevClientID : nil
    }
}

#if canImport(GoogleSignIn) && canImport(UIKit)
@MainActor
public final class GoogleSignInOAuthClient: GoogleOAuthAuthorizing {
    private let configuration: GoogleSignInConfiguration
    private let presentingViewControllerProvider: @MainActor @Sendable () -> UIViewController?

    public convenience init(configuration: GoogleSignInConfiguration) {
        self.init(
            configuration: configuration,
            presentingViewControllerProvider: { UIApplication.shared.colombaTopViewController }
        )
    }

    public init(
        configuration: GoogleSignInConfiguration,
        presentingViewControllerProvider: @escaping @MainActor @Sendable () -> UIViewController?
    ) {
        self.configuration = configuration
        self.presentingViewControllerProvider = presentingViewControllerProvider
    }

    public func authorize(scopes: Set<String>) async throws -> GoogleOAuthToken {
        guard let clientID = configuration.clientID, clientID.isEmpty == false else {
            throw GoogleIntegrationError.missingClientID
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let presentingViewController = presentingViewControllerProvider() else {
            throw GoogleIntegrationError.missingPresentingViewController
        }

        let signInResult = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController,
            hint: nil,
            additionalScopes: Array(scopes).sorted()
        )

        return GoogleOAuthToken(
            accessToken: signInResult.user.accessToken.tokenString,
            idToken: signInResult.user.idToken?.tokenString,
            email: signInResult.user.profile?.email,
            fullName: signInResult.user.profile?.name,
            scopes: Set(signInResult.user.grantedScopes ?? []).union(scopes)
        )
    }

    public static func handle(url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

private extension UIApplication {
    var colombaTopViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController?
            .colombaTopMostViewController
    }
}

private extension UIViewController {
    var colombaTopMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.colombaTopMostViewController
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.colombaTopMostViewController ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.colombaTopMostViewController ?? tabBarController
        }
        return self
    }
}
#endif

public struct CalendarEventDraft: Equatable, Sendable {
    public let title: String
    public let startsAt: Date
    public let endsAt: Date
    public let notes: String?

    public init(title: String, startsAt: Date, endsAt: Date, notes: String? = nil) {
        self.title = title
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.notes = notes
    }
}

public struct CalendarSyncResult: Equatable, Sendable {
    public let provider: AuthProvider
    public let externalID: String

    public init(provider: AuthProvider, externalID: String) {
        self.provider = provider
        self.externalID = externalID
    }
}

public protocol CalendarSyncing: Sendable {
    func sync(event: CalendarEventDraft, for user: User) async throws -> CalendarSyncResult
}

public protocol GoogleCalendarClient: Sendable {
    func upsertEvent(_ event: CalendarEventDraft, user: User, token: GoogleOAuthToken) async throws -> String
}

public struct MockGoogleCalendarRequest: Equatable, Sendable {
    public let event: CalendarEventDraft
    public let user: User
    public let token: GoogleOAuthToken
}

public final class MockGoogleCalendarClient: GoogleCalendarClient, @unchecked Sendable {
    public private(set) var requests: [MockGoogleCalendarRequest] = []
    private let externalID: String

    public init(externalID: String = "google-calendar-event-mock") {
        self.externalID = externalID
    }

    public func upsertEvent(_ event: CalendarEventDraft, user: User, token: GoogleOAuthToken) async throws -> String {
        requests.append(MockGoogleCalendarRequest(event: event, user: user, token: token))
        return externalID
    }
}

public final class GoogleCalendarService: CalendarSyncing, @unchecked Sendable {
    public static let requiredScopes: Set<String> = ["https://www.googleapis.com/auth/calendar.events"]

    private let oauth: GoogleOAuthAuthorizing
    private let client: GoogleCalendarClient

    public init(oauth: GoogleOAuthAuthorizing, client: GoogleCalendarClient = MockGoogleCalendarClient()) {
        self.oauth = oauth
        self.client = client
    }

    public func sync(event: CalendarEventDraft, for user: User) async throws -> CalendarSyncResult {
        let token = try await oauth.authorize(scopes: Self.requiredScopes)
        let id = try await client.upsertEvent(event, user: user, token: token)
        return CalendarSyncResult(provider: .google, externalID: id)
    }
}

public final class CalendarSyncDispatcher: CalendarSyncing, @unchecked Sendable {
    private let google: CalendarSyncing
    private let apple: CalendarSyncing?

    public init(google: CalendarSyncing, apple: CalendarSyncing? = nil) {
        self.google = google
        self.apple = apple
    }

    public func sync(event: CalendarEventDraft, for user: User) async throws -> CalendarSyncResult {
        switch user.authProvider {
        case .google:
            return try await google.sync(event: event, for: user)
        case .apple:
            guard let apple else { throw GoogleIntegrationError.missingAppleCalendarAdapter }
            return try await apple.sync(event: event, for: user)
        case .magicLink:
            throw GoogleIntegrationError.unsupportedAuthProvider(.magicLink)
        }
    }
}

public struct SheetRowDraft: Equatable, Sendable {
    public let spreadsheetID: String
    public let range: String
    public let values: [String]

    public init(spreadsheetID: String, range: String, values: [String]) {
        self.spreadsheetID = spreadsheetID
        self.range = range
        self.values = values
    }
}

public struct SheetAppendResult: Equatable, Sendable {
    public let updatedRange: String
    public let updatedRows: Int

    public init(updatedRange: String, updatedRows: Int) {
        self.updatedRange = updatedRange
        self.updatedRows = updatedRows
    }
}

public protocol GoogleSheetsClient: Sendable {
    func appendRow(_ row: SheetRowDraft, token: GoogleOAuthToken) async throws -> SheetAppendResult
}

public struct MockGoogleSheetsRequest: Equatable, Sendable {
    public let row: SheetRowDraft
    public let token: GoogleOAuthToken
}

public final class MockGoogleSheetsClient: GoogleSheetsClient, @unchecked Sendable {
    public private(set) var requests: [MockGoogleSheetsRequest] = []
    private let result: SheetAppendResult

    public init(result: SheetAppendResult = SheetAppendResult(updatedRange: "Sheet1!A1:C1", updatedRows: 1)) {
        self.result = result
    }

    public func appendRow(_ row: SheetRowDraft, token: GoogleOAuthToken) async throws -> SheetAppendResult {
        requests.append(MockGoogleSheetsRequest(row: row, token: token))
        return result
    }
}

public final class GoogleSheetsService: @unchecked Sendable {
    public static let requiredScopes: Set<String> = ["https://www.googleapis.com/auth/spreadsheets"]

    private let oauth: GoogleOAuthAuthorizing
    private let client: GoogleSheetsClient

    public init(oauth: GoogleOAuthAuthorizing, client: GoogleSheetsClient = MockGoogleSheetsClient()) {
        self.oauth = oauth
        self.client = client
    }

    public func append(row: SheetRowDraft) async throws -> SheetAppendResult {
        let token = try await oauth.authorize(scopes: Self.requiredScopes)
        return try await client.appendRow(row, token: token)
    }
}
