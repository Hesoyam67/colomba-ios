@testable import ColombaCustomer
import XCTest

final class TwilioSMSVerifyClientTests: XCTestCase {
    func testResolvedBaseURLUsesDedicatedSMSInfoKey() throws {
        let bundle = try makeBundle(info: [
            TwilioSMSVerifyClient.baseURLInfoKey: "https://sms.colomba-swiss.ch/webhook"
        ])

        XCTAssertEqual(
            TwilioSMSVerifyClient.resolvedBaseURL(bundle: bundle),
            URL(string: "https://sms.colomba-swiss.ch/webhook")
        )
    }

    func testResolvedBaseURLFallsBackToReservationWebhookKey() throws {
        let bundle = try makeBundle(info: [
            HTTPReservationClient.baseURLInfoKey: "https://api.colomba-swiss.ch/webhook"
        ])

        XCTAssertEqual(
            TwilioSMSVerifyClient.resolvedBaseURL(bundle: bundle),
            URL(string: "https://api.colomba-swiss.ch/webhook")
        )
    }

    func testResolvedBaseURLFallsBackToPlaceholderWhenUnset() throws {
        let bundle = try makeBundle(info: [:])

        XCTAssertEqual(
            TwilioSMSVerifyClient.resolvedBaseURL(bundle: bundle),
            TwilioSMSVerifyClient.defaultBaseURL
        )
    }

    private func makeBundle(info: [String: String]) throws -> Bundle {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "TwilioSMSVerifyClientTests-\(UUID().uuidString).bundle", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let plistURL = root.appending(path: "Info.plist")
        let data = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try data.write(to: plistURL)

        guard let bundle = Bundle(url: root) else {
            XCTFail("Expected bundle at \(root.path)")
            throw NSError(domain: "TwilioSMSVerifyClientTests", code: 1)
        }
        return bundle
    }
}
