import CoreGraphics

public enum ColombaRadii {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24

    public enum Component {
        public static let card = ColombaRadii.md
        public static let sheet = ColombaRadii.lg
        public static let button = ColombaRadii.sm
        public static let modal = ColombaRadii.xl
        public static let chip = ColombaRadii.xs
    }
}
