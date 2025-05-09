import SwiftUI

struct ThemeFonts {
    // IMPORTANT: Replace "YourFontName-Regular" and "YourFontName-Bold" 
    // with the actual PostScript names of the fonts you added to the project 
    // and registered in Info.plist.
    static let funFontName = "ButterflyKids-Regular"
    static let regularName = "Exo2-Italic-VariableFont_wght"
    static let boldName = "Exo2-VariableFont_wght"

    // Define standard text styles using the custom font
    static let funLargeTitle = Font.custom(funFontName, size: 40) // Larger size for the fun font
    static let largeTitle = Font.custom(boldName, size: 21) // Keep Amatic Bold for other large titles if needed
    static let title1 = Font.custom(boldName, size: 26)
    static let title2 = Font.custom(boldName, size: 24)
    static let title3 = Font.custom(boldName, size: 21)
    static let headline = Font.custom(boldName, size: 17) // Often used for list rows, buttons
    static let body = Font.custom(regularName, size: 17) // Standard body text
    static let callout = Font.custom(regularName, size: 16)
    static let subheadline = Font.custom(regularName, size: 15)
    static let footnote = Font.custom(regularName, size: 13)
    static let caption1 = Font.custom(regularName, size: 12)
    static let caption2 = Font.custom(regularName, size: 11)

    // Helper for specific sizes if needed
    static func regular(size: CGFloat) -> Font {
        Font.custom(regularName, size: size)
    }

    static func bold(size: CGFloat) -> Font {
        Font.custom(boldName, size: size)
    }
}

// Extension for easier application
extension Font {
    static let theme = ThemeFonts.self
}
