import SwiftUI

struct AppBackgroundModifier: ViewModifier {
    // In the future, you could add parameters here to switch between
    // solid color, main_background_pattern, or other background types.
    
    func body(content: Content) -> some View {
        ZStack {
            // Uncomment the color background
            Color.theme.background
                .ignoresSafeArea()
            
            // Comment out the image background
            /*
            Image("main_background_pattern")
                .resizable()
                .aspectRatio(contentMode: .fill) // Or .tile if you implement tiling
                .ignoresSafeArea()
            */
            
            content
        }
    }
} // Added missing closing brace

extension View {
    func appBackground() -> some View {
        self.modifier(AppBackgroundModifier())
    }
}