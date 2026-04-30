import ColombaNetworking
import Foundation

actor UsageCache {
    struct Entry: Codable, Equatable, Sendable {
        let snapshot: UsageSnapshot
        let storedAt: Date
        let etag: String?
    }

    private let fileURL: URL
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private var memoryEntry: Entry?

    init(
        fileURL: URL? = nil,
        ttl: TimeInterval = 300,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.fileURL = fileURL ?? FileManager.default.temporaryDirectory.appending(path: "colomba-usage-cache.json")
        self.ttl = ttl
        self.now = now
    }

    func load() async -> UsageSnapshot? {
        if let memoryEntry, isFresh(memoryEntry) {
            return memoryEntry.snapshot
        }
        guard let data = try? Data(contentsOf: fileURL),
              let entry = try? JSONDecoder.colomba.decode(Entry.self, from: data),
              isFresh(entry) else {
            return nil
        }
        memoryEntry = entry
        return entry.snapshot
    }

    func store(_ snapshot: UsageSnapshot, etag: String? = nil) async throws {
        let entry = Entry(snapshot: snapshot, storedAt: now(), etag: etag)
        memoryEntry = entry
        let data = try JSONEncoder.colomba.encode(entry)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let tempURL = fileURL.appendingPathExtension("tmp")
        try data.write(to: tempURL, options: .atomic)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: fileURL)
        }
    }

    func clear() async throws {
        memoryEntry = nil
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func isFresh(_ entry: Entry) -> Bool {
        now().timeIntervalSince(entry.storedAt) <= ttl
    }
}

private extension JSONEncoder {
    static var colomba: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var colomba: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
