import CoreGraphics

public enum ColombaSpacing {
    public static let space0: CGFloat = 0
    public static let space1: CGFloat = 4
    public static let space2: CGFloat = 8
    public static let space3: CGFloat = 12
    public static let space4: CGFloat = 16
    public static let space5: CGFloat = 20
    public static let space6: CGFloat = 24
    public static let space7: CGFloat = 32
    public static let space8: CGFloat = 40
    public static let space9: CGFloat = 56
    public static let space10: CGFloat = 72

    public enum Card {
        public static let padding = ColombaSpacing.space4
    }

    public enum Screen {
        public static let margin = ColombaSpacing.space5
    }

    public enum Section {
        public static let gap = ColombaSpacing.space6
    }

    public enum ListRow {
        public static let gap = ColombaSpacing.space3
    }
}
