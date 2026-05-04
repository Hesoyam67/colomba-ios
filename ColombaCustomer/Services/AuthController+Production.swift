import ColombaAuth
import Foundation
import UIKit

extension AuthController {
    static func production(
        bundle: Bundle = .main,
        userDefaults: UserDefaults = .standard,
        urlSession: URLSession = .shared
    ) -> AuthController {
        AuthController(
            sessionStore: KeychainAuthSessionStore(),
            service: HTTPAuthService(
                baseURL: HTTPReservationClient.resolvedBaseURL(bundle: bundle),
                urlSession: urlSession
            ),
            device: AppDeviceInfoFactory.make(bundle: bundle, userDefaults: userDefaults)
        )
    }
}

private enum AppDeviceInfoFactory {
    private static let defaultsKey = "colomba.auth.device-id"

    static func make(bundle: Bundle, userDefaults: UserDefaults) -> DeviceInfo {
        let deviceID = resolvedDeviceID(userDefaults: userDefaults)
        let appVersion = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0.0"
        return DeviceInfo(deviceId: deviceID, appVersion: appVersion)
    }

    private static func resolvedDeviceID(userDefaults: UserDefaults) -> String {
        if let existing = userDefaults.string(forKey: defaultsKey), existing.isEmpty == false {
            return existing
        }

        let generated = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        userDefaults.set(generated, forKey: defaultsKey)
        return generated
    }
}
