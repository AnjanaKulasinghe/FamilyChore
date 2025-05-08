import SwiftUI

struct ThemeColors {
    // Define color names that correspond to your Assets.xcassets
    // Example: In Assets.xcassets, create a new Color Set named "PrimaryAppColor"
    static let primaryApp = Color("PrimaryAppColor")
    static let secondaryApp = Color("SecondaryAppColor")
    static let accentApp = Color("AccentAppColor")
    static let background = Color("BackgroundColor") // For general backgrounds
    static let textPrimary = Color("TextColorPrimary")
    static let textSecondary = Color("TextColorSecondary")

    // You can add more specific colors as needed
    static let buttonPrimaryBackground = Color("ButtonPrimaryBackgroundColor")
    static let buttonPrimaryText = Color("ButtonPrimaryTextColor")
}

// Extension to make it easier to use these theme colors
extension Color {
    static let theme = ThemeColors.self
}