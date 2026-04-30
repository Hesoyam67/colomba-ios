import SwiftUI
import XCTest
@testable import ColombaDesign

final class ColombaDesignTests: XCTestCase {
    func testSpacingScaleMatchesLockedTokens() {
        XCTAssertEqual(ColombaSpacing.space0, 0)
        XCTAssertEqual(ColombaSpacing.space5, 20)
        XCTAssertEqual(ColombaSpacing.space10, 72)
        XCTAssertEqual(ColombaSpacing.Screen.margin, ColombaSpacing.space5)
    }

    func testRadiiScaleMatchesLockedTokens() {
        XCTAssertEqual(ColombaRadii.xs, 4)
        XCTAssertEqual(ColombaRadii.md, 12)
        XCTAssertEqual(ColombaRadii.xl, 24)
        XCTAssertEqual(ColombaRadii.Component.card, ColombaRadii.md)
    }

    func testMotionDurationsMatchLockedTokens() {
        XCTAssertEqual(ColombaMotion.Duration.micro, 0.120, accuracy: 0.0001)
        XCTAssertEqual(ColombaMotion.Duration.short, 0.200, accuracy: 0.0001)
        XCTAssertEqual(ColombaMotion.Duration.skeleton, 1.200, accuracy: 0.0001)
    }

    func testSemanticColorAndTypographyAPIsExist() {
        _ = Color.colomba.primary
        _ = Color.colomba.bg.base
        _ = Color.colomba.text.secondary
        _ = Color.colomba.border.hairline
        _ = Font.colomba.display
        _ = Font.colomba.billingFigure
        _ = Font.colombaNumeric(size: 17)
    }
}
