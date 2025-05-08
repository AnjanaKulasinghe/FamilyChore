import SwiftUI

struct FunkyButtonStyle: ButtonStyle {
    var backgroundColor: Color = Color.theme.buttonPrimaryBackground // Restored backgroundColor
    var textColor: Color = Color.theme.buttonPrimaryText
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 3
    var pressedScale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Font.theme.headline) // Use themed headline font
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor) // Reverted to using backgroundColor
            .foregroundColor(textColor)
            .cornerRadius(cornerRadius) // Reverted from clipShape
            .shadow(color: Color.black.opacity(0.2), radius: shadowRadius, x: 0, y: shadowRadius / 2)
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Optional: Extension for easier application
extension Button {
    func funky(backgroundColor: Color = Color.theme.buttonPrimaryBackground, // Restored backgroundColor parameter
               textColor: Color = Color.theme.buttonPrimaryText,
               cornerRadius: CGFloat = 12,
               shadowRadius: CGFloat = 3,
               pressedScale: CGFloat = 0.97) -> some View {
        self.buttonStyle(FunkyButtonStyle(backgroundColor: backgroundColor, // Restored backgroundColor parameter
                                          textColor: textColor,
                                          cornerRadius: cornerRadius,
                                          shadowRadius: shadowRadius,
                                          pressedScale: pressedScale))
    }
}