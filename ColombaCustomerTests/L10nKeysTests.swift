import XCTest

final class L10nKeysTests: XCTestCase {
    func test_allLocalesHaveSameKeySet() throws {
        let englishKeys = try localizableStrings(for: "en").keys
        for locale in ["de-CH", "fr-CH", "it-CH"] {
            let localeKeys = try localizableStrings(for: locale).keys
            XCTAssertEqual(Set(localeKeys), Set(englishKeys), "Mismatched keys for \(locale)")
        }
    }

    func test_referencedKeysExistInEnglish() throws {
        let englishKeys = Set(try localizableStrings(for: "en").keys)
        let referencedKeys = Set([
        "auth.checking_apple",
        "auth.code_placeholder",
        "auth.code_sent_to_format",
        "auth.colomba_brand",
        "auth.email_magic_link",
        "auth.email_placeholder",
        "auth.or",
        "auth.refresh_session",
        "auth.reserve_table",
        "auth.send_signin_link",
        "auth.sending_link",
        "auth.session_copy",
        "auth.sign_out",
        "auth.signed_in",
        "auth.signin_copy",
        "auth.verify_code",
        "auth.verifying_code",
        "auth.view_plans",
        "auth.view_usage",
        "auth.welcome_name_format",
        "auth.welcome_title",
        "billing.manage_subscription",
        "billing.portal_hint",
        "billing.portal_unavailable",
        "heidi.card.check_availability",
        "heidi.confirmation.book.title",
        "heidi.confirmation.details_format",
        "heidi.confirmation.view_booking",
        "heidi.error.network",
        "heidi.input.placeholder",
        "heidi.input.send",
        "heidi.input.voice",
        "heidi.nav_title",
        "heidi.reset",
        "heidi.thinking",
        "heidi.welcome",
        "tabs.heidi",
        "onboarding.notifications.cta",
        "onboarding.welcome.title",
        "paywall.buy_accessibility_format",
        "paywall.loading_products",
        "paywall.price_format",
        "paywall.purchase_hint",
        "paywall.purchased_format",
        "paywall.purchasing_format",
        "paywall.restore_purchases",
        "paywall.upgrade_title",
        "phone_verify.attempts_format",
        "phone_verify.body",
        "phone_verify.change_number",
        "phone_verify.country_code",
        "phone_verify.paused_title",
        "phone_verify.phone_placeholder",
        "phone_verify.resend_code",
        "phone_verify.resend_in_format",
        "phone_verify.send_code",
        "phone_verify.title",
        "phone_verify.verified_body",
        "phone_verify.verified_title",
        "phone_verify.verify_code",
        "phone_verify.verifying_progress",
        "plans.choose_accessibility_format",
        "plans.choose_format",
        "plans.minutes_accessibility_format",
        "plans.minutes_format",
        "plans.included",
        "plans.included_minutes_format",
        "plans.loading",
        "plans.nav_title",
        "plans.open_details_format",
        "plans.price_accessibility_format",
        "plans.price_format",
        "plans.unavailable",
        "plans.upgrade_hint",
        "plans.selected_badge",
        "plans.selected_format",
        "plans.selected_title",
        "plans.feature.reservation_capture",
        "plans.feature.basic_analytics",
        "plans.feature.ai_support_chat",
        "plans.feature.usage_alerts",
        "plans.feature.team_inbox",
        "plans.feature.multi_location",
        "plans.feature.priority_support",
        "plans.feature.advanced_reporting",
        "plans.feature.minute_top_up",
        "reservation.add_to_calendar",
        "reservation.available_times",
        "reservation.book_copy",
        "reservation.list.book.cta",
        "reservation.calendar_added",
        "reservation.calendar_denied",
        "reservation.calendar_notes_format",
        "reservation.calendar_title_format",
        "reservation.calendar_unavailable",
        "reservation.checking_availability",
        "reservation.choose_time",
        "reservation.confirm",
        "reservation.confirmed",
        "reservation.counter_format",
        "reservation.date",
        "reservation.done",
        "reservation.empty_desc",
        "reservation.empty_title",
        "reservation.error_title",
        "reservation.failed_default",
        "reservation.full_name",
        "reservation.guests_format",
        "reservation.loading_restaurants",
        "reservation.nav_title",
        "reservation.nav_title_format",
        "reservation.no_available_times",
        "reservation.ok",
        "reservation.optional_hint",
        "reservation.party",
        "reservation.party_of_format",
        "reservation.reserve",
        "reservation.special_requests",
        "reservation.time",
        "reservation.when",
        "usage.accessibility_format",
        "usage.loading",
        "usage.nav_title",
        "usage.overage_format",
        "usage.source_cache",
        "usage.source_server",
        "usage.summary_format",
        "usage.text_format",
        "usage.this_month",
        "usage.unavailable",
        "settings.plan_billing",
        "settings.manage_plan",
        "settings.reservations",
        "settings.usage_minutes",
        "settings.usage_minutes_note",
        "usage.updated_from_format",
        ])
        XCTAssertTrue(referencedKeys.isSubset(of: englishKeys))
    }

    func test_noEmptyValues_inEnglish() throws {
        let englishStrings = try localizableStrings(for: "en")
        let emptyKeys = englishStrings.filter { $0.value.isEmpty }.map(\.key)
        XCTAssertTrue(emptyKeys.isEmpty, "Empty English localization values: \(emptyKeys)")
    }

    private func localizableStrings(for locale: String) throws -> [String: String] {
        let fileURL = repoRoot
            .appending(path: "ColombaCustomer/Resources")
            .appending(path: "\(locale).lproj")
            .appending(path: "Localizable.strings")
        let data = try Data(contentsOf: fileURL)
        let propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let strings = propertyList as? [String: String] else {
            XCTFail("Could not parse Localizable.strings for \(locale)")
            return [:]
        }
        return strings
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
