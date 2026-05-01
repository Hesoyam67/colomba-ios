import Foundation
import PhoneNumberKit

@MainActor
public final class PhoneVerifyViewModel: ObservableObject {
    public enum Phase: Equatable {
        case entering
        case confirming
        case verifying
        case verified
        case failed(reason: String)
    }

    @Published public private(set) var phase: Phase
    @Published public private(set) var phoneNumber: String
    @Published public private(set) var otp: String
    @Published public private(set) var resendCooldownSeconds: Int
    @Published public private(set) var attemptsRemaining: Int

    private let service: SMSVerifyServiceProtocol
    private let locale: AppLanguage
    private let phoneNumberKit: PhoneNumberKit
    private let now: @Sendable () -> Date
    private var challenge: SMSChallenge?
    private var cooldownTask: Task<Void, Never>?

    public init(
        service: SMSVerifyServiceProtocol,
        locale: AppLanguage,
        phoneNumberKit: PhoneNumberKit = PhoneNumberKit(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.service = service
        self.locale = locale
        self.phoneNumberKit = phoneNumberKit
        self.now = now
        self.phase = .entering
        self.phoneNumber = ""
        self.otp = ""
        self.resendCooldownSeconds = 0
        self.attemptsRemaining = 5
    }

    deinit {
        cooldownTask?.cancel()
    }

    public var isPhoneValid: Bool {
        (try? normalizedPhoneNumber()) != nil
    }

    public var canVerify: Bool {
        otp.count == 6 && attemptsRemaining > 0
    }

    public func updatePhoneNumber(_ value: String) {
        phoneNumber = sanitizedPhoneInput(value)
    }

    public func updateOTP(_ value: String) {
        otp = String(value.filter(\.isNumber).prefix(6))
    }

    public func normalizedPhoneNumber() throws -> String {
        let raw = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate: String
        if raw.hasPrefix("00") {
            candidate = "+" + raw.dropFirst(2)
        } else if raw.hasPrefix("+") {
            candidate = raw
        } else if raw.hasPrefix("0") {
            candidate = "+41" + raw.dropFirst()
        } else {
            candidate = "+41" + raw
        }
        do {
            let parsed = try phoneNumberKit.parse(candidate, withRegion: "CH", ignoreType: true)
            return phoneNumberKit.format(parsed, toType: .e164)
        } catch {
            throw SMSVerifyError.invalidPhone
        }
    }

    public func sendCode() async {
        do {
            let normalized = try normalizedPhoneNumber()
            challenge = try await service.sendCode(phoneE164: normalized, locale: locale)
            attemptsRemaining = 5
            otp = ""
            phase = .confirming
            startCooldown(seconds: 60)
        } catch {
            phase = .failed(reason: message(for: error))
        }
    }

    public func verifyCode() async {
        guard let challenge else {
            phase = .failed(reason: "Missing verification challenge")
            return
        }
        if now() >= challenge.expiresAt {
            phase = .failed(reason: "Code expired, tap Resend")
            return
        }
        phase = .verifying
        do {
            let result = try await service.verifyCode(challengeId: challenge.challengeId, code: otp)
            phase = result.verified ? .verified : .failed(reason: "Verification failed")
        } catch SMSVerifyError.wrongCode {
            attemptsRemaining = max(0, attemptsRemaining - 1)
            phase = attemptsRemaining == 0 ? .failed(reason: "Too many attempts") : .confirming
        } catch SMSVerifyError.challengeExpired {
            phase = .failed(reason: "Code expired, tap Resend")
        } catch {
            phase = .failed(reason: message(for: error))
        }
    }

    public func resend() async {
        guard resendCooldownSeconds == 0 else { return }
        await sendCode()
    }

    public func changeNumber() {
        cooldownTask?.cancel()
        phase = .entering
        otp = ""
        resendCooldownSeconds = 0
        attemptsRemaining = 5
        challenge = nil
    }

    public func reset() {
        cooldownTask?.cancel()
        phase = .entering
        phoneNumber = ""
        otp = ""
        resendCooldownSeconds = 0
        attemptsRemaining = 5
        challenge = nil
    }

    private func sanitizedPhoneInput(_ value: String) -> String {
        value.filter { $0.isNumber || $0 == "+" || $0.isWhitespace }
    }

    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()
        resendCooldownSeconds = seconds
        cooldownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if self.resendCooldownSeconds <= 0 { return }
                self.resendCooldownSeconds -= 1
            }
        }
    }

    private func message(for error: Error) -> String {
        switch error {
        case SMSVerifyError.invalidPhone:
            "Enter a valid Swiss phone number"
        case SMSVerifyError.rateLimited(let retryAfter):
            "Too many requests. Try again in \(Int(retryAfter)) seconds."
        case SMSVerifyError.challengeExpired:
            "Code expired, tap Resend"
        case SMSVerifyError.wrongCode:
            "Wrong code"
        default:
            "SMS verification is temporarily unavailable"
        }
    }
}
