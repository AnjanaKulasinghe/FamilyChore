import SwiftUI

/// A view for parents to manage (list, add, edit, delete) rewards for the family.
struct ManageRewardsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To get family ID
    @StateObject var viewModel = ManageRewardsViewModel()
    @State private var showingCreateRewardView = false // To present CreateRewardView modally

    // We need RewardViewModel for editing, let's assume it exists and has an appropriate init
    // If not, CreateRewardView might need adjustment or a different ViewModel approach.

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Rewards...")
                    .font(Font.theme.body) // Apply font
            } else if let error = viewModel.error {
                Text("Error loading rewards: \(error.localizedDescription)")
                    .font(Font.theme.footnote) // Apply font
                    .foregroundColor(.red)
            } else {
                List {
                    ForEach(viewModel.rewards) { reward in
                        NavigationLink {
                            // Navigate to CreateRewardView for editing, passing the existing reward
                            CreateRewardView(viewModel: RewardViewModel(reward: reward))
                        } label: {
                            HStack {
                                if let imageUrlString = reward.imageUrl, let imageUrl = URL(string: imageUrlString) {
                                    AsyncImage(url: imageUrl) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 40, height: 40)
                                        case .success(let image):
                                            image.resizable()
                                                 .aspectRatio(contentMode: .fill)
                                                 .frame(width: 40, height: 40)
                                                 .clipShape(Circle())
                                        case .failure:
                                            Image(systemName: "photo.circle.fill") // Placeholder for failure
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 40, height: 40)
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            EmptyView()
                                                .frame(width: 40, height: 40)
                                        }
                                    }
                                } else {
                                    Image(systemName: "gift.circle.fill") // Placeholder if no image URL
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }
                                VStack(alignment: .leading) {
                                    Text(reward.title)
                                        .font(Font.theme.headline) // Apply font
                                        .foregroundColor(Color.theme.textPrimary)
                                    Text("Points: \(reward.requiredPoints)  points")
                                        .font(Font.theme.subheadline) // Apply font
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteReward)
                }
                .listStyle(.insetGrouped) // Match style of other lists
                .font(Font.theme.body) // Default font for list content
                .padding(.top) // Add padding between title and list
                .scrollContentBackground(.hidden) // Make List background transparent (iOS 16+)
                .background(Color.clear) // Fallback/alternative for List background
            }
        }
        .appBackground() // Apply themed background
        .navigationTitle("Manage Rewards")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateRewardView = true
                } label: {
                    Label("Add Reward", systemImage: "plus")
                        .font(Font.theme.body) // Apply font to label
                }
                .tint(Color.theme.accentApp) // Style toolbar button
            }
        }
        .sheet(isPresented: $showingCreateRewardView, onDismiss: {
            // Re-fetch rewards when the sheet is dismissed to see updates/new items
            if let familyId = authViewModel.userProfile?.familyId {
                Task {
                    await viewModel.fetchRewards(forFamily: familyId)
                }
            }
        }) {
            // Present CreateRewardView modally for adding a new reward
            NavigationView { // Embed in NavigationView for title and potential buttons
                // Pass a new, empty RewardViewModel for creating a reward
                CreateRewardView(viewModel: RewardViewModel())
            }
            // Pass environment objects if CreateRewardView needs them
             .environmentObject(authViewModel)
        }
        .onAppear {
            // Fetch rewards when the view appears
            if let familyId = authViewModel.userProfile?.familyId {
                Task {
                    await viewModel.fetchRewards(forFamily: familyId)
                }
            } else {
                viewModel.error = NSError(domain: "ManageRewardsViewError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Family ID not found."])
            }
        }
    }

    /// Deletes rewards at the specified offsets.
    private func deleteReward(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let rewardToDelete = viewModel.rewards[index]
                await viewModel.deleteReward(rewardToDelete)
            }
        }
        // Note: If not using a listener, manually remove from the local array for immediate UI update:
        // viewModel.rewards.remove(atOffsets: offsets)
    }
}

struct ManageRewardsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ManageRewardsView()
                .environmentObject(AuthViewModel()) // Provide mock AuthViewModel
        }
    }
}
