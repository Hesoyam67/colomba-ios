import Foundation

/// Shared app navigation namespace.
enum AppRouter {
    enum Destination: Hashable {}

    enum DeepLink: Equatable {
        case reservations
        case reservation(id: String)

        init?(url: URL) {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
            let pathParts = components.path
                .split(separator: "/")
                .map(String.init)
            let host = components.host

            if components.scheme == "colomba" {
                self.init(host: host, pathParts: pathParts)
                return
            }

            guard components.scheme == "https",
                  host == "colomba-swiss.ch",
                  pathParts.first == "app" else {
                return nil
            }
            self.init(host: pathParts.dropFirst().first, pathParts: Array(pathParts.dropFirst(2)))
        }

        var url: URL {
            switch self {
            case .reservations:
                return Self.url(path: "reservations")
            case let .reservation(id):
                return Self.url(path: "reservations/\(id)")
            }
        }

        private init?(host: String?, pathParts: [String]) {
            guard host == "reservations" else { return nil }
            if let id = pathParts.first, id.isEmpty == false {
                self = .reservation(id: id)
            } else {
                self = .reservations
            }
        }

        private static func url(path: String) -> URL {
            guard let url = URL(string: "colomba://\(path)") else {
                preconditionFailure("Invalid Colomba deep-link path: \(path)")
            }
            return url
        }
    }
}
