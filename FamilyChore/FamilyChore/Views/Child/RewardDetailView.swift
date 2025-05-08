import SwiftUI

/// A view to display details of a reward.
struct RewardDetailView: View {
    let reward: Reward // Assuming Reward model is accessible

    var body: some View {
        VStack(alignment: .leading, spacing: 15) { // Added alignment and spacing
            // Removed redundant title, rely on navigationTitle
            // Text("Reward Details")
            //     .font(Font.theme.funLargeTitle) // Use fun font
            //     .foregroundColor(Color.theme.textPrimary)
            //     .padding()

            // Display Reward Image if available
            if let imageUrlString = reward.imageUrl, let imageUrl = URL(string: imageUrlString) {
                 AsyncImage(url: imageUrl) { phase in
                     switch phase {
                     case .success(let image):
                         image.resizable()
                              .aspectRatio(contentMode: .fit)
                              .cornerRadius(10)
                              .shadow(radius: 5)
                     case .failure:
                         Image(systemName: "gift.fill") // Placeholder
                             .resizable()
                             .scaledToFit()
                             .foregroundColor(.gray)
                             .frame(height: 150)
                     case .empty:
                         ProgressView()
                             .frame(height: 150)
                     @unknown default:
                         EmptyView()
                             .frame(height: 150)
                     }
                 }
                 .frame(maxWidth: .infinity, alignment: .center) // Center image
                 .padding(.bottom)
             }


            Text(reward.title)
                .font(Font.theme.title1) // Use theme font
                .foregroundColor(Color.theme.textPrimary)
            
            Text("Points Cost: \(reward.requiredPoints)")
                .font(Font.theme.headline) // Use theme font
                .foregroundColor(Color.theme.textSecondary)
            
            // Display other reward details as needed
            // Example:
            // Text("Assigned to: ...")
            // Text("Created by: ...")

            Spacer()
        }
        .padding() // Add padding around the VStack content
        .appBackground() // Apply themed background
        .navigationTitle(reward.title) // Title is already set
    }
}
