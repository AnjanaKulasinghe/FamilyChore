import SwiftUI

struct ThemeFonts {
    // IMPORTANT: Replace "YourFontName-Regular" and "YourFontName-Bold" 
    // with the actual PostScript names of the fonts you added to the project 
    // and registered in Info.plist.
    static let funFontName = "ButterflyKids-Regular"
    static let regularName = "AmaticSC-Regular"
    static let boldName = "AmaticSC-Bold"

    // Define standard text styles using the custom font
    static let funLargeTitle = Font.custom(funFontName, size: 45) // Larger size for the fun font
    static let largeTitle = Font.custom(boldName, size: 26) // Keep Amatic Bold for other large titles if needed
    static let title1 = Font.custom(boldName, size: 31)
    static let title2 = Font.custom(boldName, size: 29)
    static let title3 = Font.custom(boldName, size: 26)
    static let headline = Font.custom(boldName, size: 22) // Often used for list rows, buttons
    static let body = Font.custom(regularName, size: 22) // Standard body text
    static let callout = Font.custom(regularName, size: 21)
    static let subheadline = Font.custom(regularName, size: 20)
    static let footnote = Font.custom(regularName, size: 18)
    static let caption1 = Font.custom(regularName, size: 17)
    static let caption2 = Font.custom(regularName, size: 16)

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
