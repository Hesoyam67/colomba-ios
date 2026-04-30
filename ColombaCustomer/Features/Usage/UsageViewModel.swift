import ColombaNetworking
import Foundation

@MainActor
final class UsageViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(UsageSnapshot, source: Source)
        case failed(String)
    }

    enum Source: Equatable {
        case cache
        case network
    }

    @Published private(set) var state: State = .idle

    private let client: UsageClient
    private let cache: UsageCache

    init(client: UsageClient = FixtureUsageClient(), cache: UsageCache = UsageCache()) {
        self.client = client
        self.cache = cache
    }

    var snapshot: UsageSnapshot? {
        guard case let .loaded(snapshot, _) = state else {
            return nil
        }
        return snapshot
    }

    func load(preferCache: Bool = true) async {
        if preferCache, let cached = await cache.load() {
            state = .loaded(cached, source: .cache)
            return
        }
        state = .loading
        do {
            let snapshot = try await client.getUsage(period: .currentMonth)
            try await cache.store(snapshot)
            state = .loaded(snapshot, source: .network)
        } catch {
            state = .failed("Usage is unavailable. Please try again.")
        }
    }

    func refresh() async {
        await load(preferCache: false)
    }

    func progress(for snapshot: UsageSnapshot) -> Double {
        guard snapshot.includedEvents > 0 else {
            return 0
        }
        return min(Double(snapshot.usedEvents) / Double(snapshot.includedEvents), 1)
    }

    func usageText(for snapshot: UsageSnapshot) -> String {
        "\(snapshot.usedEvents.formatted()) of \(snapshot.includedEvents.formatted()) events used"
    }

    func accessibilityText(for snapshot: UsageSnapshot) -> String {
        "\(snapshot.usedEvents.formatted()) of \(snapshot.includedEvents.formatted()) events used this month"
    }
}
