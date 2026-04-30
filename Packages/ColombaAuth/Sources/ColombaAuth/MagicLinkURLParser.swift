import Foundation

public struct MagicLinkCredential: Equatable, Sendable {
    public let challengeId: String
    public let code: String

    public init(challengeId: String, code: String) {
        self.challengeId = challengeId
        self.code = code
    }
}

public enum MagicLinkURLParser {
    public static func parse(_ url: URL) -> MagicLinkCredential? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "colomba",
              components.host == "auth",
              components.path == "/magic" else {
            return nil
        }
        let challengeId = queryValue(named: "challengeId", in: components)
            ?? queryValue(named: "challenge_id", in: components)
        let code = queryValue(named: "code", in: components)
        guard let challengeId,
              let code,
              !challengeId.isEmpty,
              !code.isEmpty else {
            return nil
        }
        return MagicLinkCredential(challengeId: challengeId, code: code)
    }

    private static func queryValue(named name: String, in components: URLComponents) -> String? {
        components.queryItems?.first { item in
            item.name == name
        }?.value
    }
}
