import Foundation

public struct CachedReceipt: Codable, Equatable, Sendable, Identifiable {
    public let productID: String
    public let transactionID: String
    public let originalTransactionID: String
    public let jws: String
    public let expirationDate: Date?
    public let verifiedAt: Date

    public var id: String { productID }

    public init(
        productID: String,
        transactionID: String,
        originalTransactionID: String,
        jws: String,
        expirationDate: Date?,
        verifiedAt: Date
    ) {
        self.productID = productID
        self.transactionID = transactionID
        self.originalTransactionID = originalTransactionID
        self.jws = jws
        self.expirationDate = expirationDate
        self.verifiedAt = verifiedAt
    }
}

public struct ReceiptCacheSnapshot: Codable, Equatable, Sendable {
    public let receipts: [CachedReceipt]

    public init(receipts: [CachedReceipt]) {
        self.receipts = receipts
    }
}

public actor ReceiptCache {
    public enum CacheState: Equatable, Sendable {
        case entitled(CachedReceipt)
        case needsReverify(CachedReceipt?)
    }

    private let fileURL: URL
    private let ttl: TimeInterval
    private let maxBytes: Int
    private let now: @Sendable () -> Date
    private var receiptsByProductID: [String: CachedReceipt] = [:]

    public init(
        fileURL: URL? = nil,
        ttl: TimeInterval = 86_400,
        maxBytes: Int = 256 * 1_024,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appending(path: "Colomba/receipts.json") ?? FileManager.default.temporaryDirectory
            .appending(path: "Colomba/receipts.json")
        self.ttl = ttl
        self.maxBytes = maxBytes
        self.now = now
    }

    public func load() async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            receiptsByProductID = [:]
            return
        }
        let data = try Data(contentsOf: fileURL)
        let snapshot = try JSONDecoder.receipts.decode(ReceiptCacheSnapshot.self, from: data)
        receiptsByProductID = Dictionary(uniqueKeysWithValues: snapshot.receipts.map { ($0.productID, $0) })
    }

    public func save(_ receipt: CachedReceipt) async throws {
        receiptsByProductID[receipt.productID] = receipt
        try persist()
    }

    public func entitlementState(productID: String) async -> CacheState {
        guard let receipt = receiptsByProductID[productID] else {
            return .needsReverify(nil)
        }
        guard now().timeIntervalSince(receipt.verifiedAt) <= ttl else {
            return .needsReverify(receipt)
        }
        if let expirationDate = receipt.expirationDate, expirationDate <= now() {
            return .needsReverify(receipt)
        }
        return .entitled(receipt)
    }

    public func allReceipts() async -> [CachedReceipt] {
        receiptsByProductID.values.sorted { $0.verifiedAt > $1.verifiedAt }
    }

    public func clear() async throws {
        receiptsByProductID = [:]
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func persist() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var receipts = receiptsByProductID.values.sorted { $0.verifiedAt > $1.verifiedAt }
        var data = try JSONEncoder.receipts.encode(ReceiptCacheSnapshot(receipts: receipts))
        while data.count > maxBytes, receipts.count > 1 {
            receipts.removeLast()
            data = try JSONEncoder.receipts.encode(ReceiptCacheSnapshot(receipts: receipts))
        }
        receiptsByProductID = Dictionary(uniqueKeysWithValues: receipts.map { ($0.productID, $0) })
        let tempURL = fileURL.appendingPathExtension("tmp")
        try data.write(to: tempURL, options: .atomic)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: fileURL)
        }
    }
}

private extension JSONEncoder {
    static var receipts: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var receipts: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
