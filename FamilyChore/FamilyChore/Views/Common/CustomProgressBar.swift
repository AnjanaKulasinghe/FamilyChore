import SwiftUI

struct CustomProgressBar: View {
    @Binding var progress: Double // Value between 0.0 and 1.0
    var height: CGFloat = 12 // Height of the progress bar
    var backgroundColor: Color = Color.gray.opacity(0.3)
    var foregroundColor: Color = Color.theme.accentApp // Use accent color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background of the progress bar
                RoundedRectangle(cornerRadius: height / 2)
                    .frame(width: geometry.size.width, height: height)
                    .foregroundColor(backgroundColor)

                // Foreground (filled portion)
                RoundedRectangle(cornerRadius: height / 2)
                    .frame(width: min(CGFloat(self.progress) * geometry.size.width, geometry.size.width), height: height)
                    .foregroundColor(foregroundColor)
                    .animation(.linear(duration: 0.1), value: progress) // Smooth animation for progress changes
            }
            .cornerRadius(height / 2) // Ensure the ZStack itself is clipped if needed
        }
        .frame(height: height) // Set the overall height for the GeometryReader
    }
}

struct CustomProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CustomProgressBar(progress: .constant(0.25))
                .padding()
            CustomProgressBar(progress: .constant(0.75))
                .padding()
        }
    }
}