import SwiftUI

/// A view to display an image in full screen.
struct FullScreenImageView: View {
    @Environment(\.presentationMode) var presentationMode
    let imageUrl: String

    var body: some View {
        NavigationView {
            ZStack { // Use ZStack to layer background
                VStack {
                    if let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFit()
                            } else if phase.error != nil {
                                Text("Error loading image")
                                    .font(Font.theme.footnote) // Apply font
                                    .foregroundColor(.red)
                            } else {
                                ProgressView()
                                    .font(Font.theme.body) // Apply font
                        }
                    }
                } else {
                    Text("Invalid image URL")
                        .font(Font.theme.footnote) // Apply font
                        .foregroundColor(.red)
                }
            }
            } // End ZStack
            .appBackground() // Apply themed background
            .navigationTitle("Photo Proof")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { // Use cancellationAction for dismissal
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(Font.theme.body) // Apply font
                    .foregroundColor(Color.theme.accentApp) // Apply color
                }
            }
        }
    }
}

struct FullScreenImageView_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenImageView(imageUrl: "https://example.com/proof.jpg") // Provide a mock URL
    }
}