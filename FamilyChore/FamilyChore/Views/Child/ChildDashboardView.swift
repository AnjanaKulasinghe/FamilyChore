import SwiftUI

/// The main dashboard view for Child users.
struct ChildDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To access current child's profile
    @StateObject var viewModel = ChildDashboardViewModel() // ViewModel for dashboard data

    var body: some View {
        NavigationView {
            ZStack { // Add ZStack for background
                VStack {
                    if viewModel.isLoading {
                        ProgressView("Loading Dashboard...")
                            .font(Font.theme.body) // Apply font
                    } else if let error = viewModel.error {
                        Text("Error: \(error.localizedDescription)")
                            .font(Font.theme.footnote) // Apply font
                            .foregroundColor(.red)
                } else {
                    // Display Child Dashboard content
                    List {
                        Section(header: Text("My Tasks").font(Font.theme.title2).foregroundColor(Color.theme.textSecondary)) { // Style header
                            if viewModel.assignedTasks.isEmpty {
                                Text("No tasks assigned yet.")
                                    .font(Font.theme.body)
                                    .foregroundColor(Color.theme.textSecondary)
                            } else {
                                ForEach(viewModel.assignedTasks) { task in
                                    NavigationLink {
                                        TaskDetailView(task: task)
                                    } label: {
                                        // Consider adding task image here too
                                        Text(task.title)
                                            .font(Font.theme.headline) // Use headline for list items
                                            .foregroundColor(Color.theme.textPrimary)
                                    }
                                }
                            }
                        }
                        .listRowSeparator(.hidden)

                        Section(header: Text("My Rewards").font(Font.theme.title2).foregroundColor(Color.theme.textSecondary)) { // Style header
                            if viewModel.assignedRewards.isEmpty {
                                Text("No rewards assigned yet.")
                                    .font(Font.theme.body)
                                    .foregroundColor(Color.theme.textSecondary)
                            } else {
                                // Iterate over claims now
                                ForEach(viewModel.rewardClaims) { claim in
                                    // We need the original Reward data too for title/cost if claim doesn't store it
                                    // This requires fetching Rewards separately or embedding essential Reward data in RewardClaim
                                    // Assuming RewardClaim has rewardTitle and rewardCost for now.
                                    RewardProgressRow(
                                        claim: claim, // Pass the claim object
                                        reward: Reward(id: claim.rewardId, title: claim.rewardTitle, requiredPoints: claim.rewardCost, assignedChildIds: [claim.childId], createdByParentId: "", familyId: claim.familyId), // Reconstruct a minimal Reward for the row
                                        progress: viewModel.progress(for: claim), // Use progress func that takes a claim
                                        currentPoints: viewModel.childProfile?.points ?? 0,
                                        onClaim: nil, // Claim button is handled by this row based on status
                                        onRemind: { // Provide the remind action
                                            Task {
                                                await viewModel.sendReminder(for: claim)
                                                // Optionally show confirmation
                                            }
                                        }
                                    )
                                    // Add NavigationLink if needed
                                    // NavigationLink { RewardDetailView(reward: reward) } label: { RewardProgressRow(...) }
                                }
                                // TODO: Need to display rewards that *can* be claimed but haven't been yet.
                                // This requires fetching assignedRewards separately and filtering them.

                                // --- Display Unclaimed Rewards ---
                                ForEach(viewModel.unclaimedRewards) { reward in
                                     RewardProgressRow(
                                         claim: nil, // No claim object for unclaimed rewards
                                         reward: reward,
                                         progress: viewModel.progress(for: reward), // Use progress func for Reward
                                         currentPoints: viewModel.childProfile?.points ?? 0,
                                         onClaim: { // Provide the claim action
                                             Task {
                                                 await viewModel.claimReward(reward)
                                             }
                                         },
                                         onRemind: nil // No reminder for unclaimed rewards
                                     )
                                     // Add NavigationLink if needed
                                     // NavigationLink { RewardDetailView(reward: reward) } label: { RewardProgressRow(...) }
                                 }

                            }
                        }
                        .listRowSeparator(.hidden)

                        Section(header: Text("My Profile").font(Font.theme.title2).foregroundColor(Color.theme.textSecondary)) { // Style header
                            NavigationLink("Edit Profile") {
                                if let childProfile = viewModel.childProfile {
                                    ChildProfileView(viewModel: ProfileViewModel(childProfile: childProfile))
                                } else {
                                    Text("Loading Profile...")
                                        .font(Font.theme.body)
                                }
                            }
                            .font(Font.theme.headline) // Style link text
                            .foregroundColor(Color.theme.accentApp)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden) // Make List background transparent (iOS 16+)
                    .background(Color.clear) // Fallback/alternative for List background
                    .font(Font.theme.body) // Default font for list content
                }
            } // End VStack
            } // End ZStack
            .appBackground() // Apply themed background
            .navigationTitle("Child Dashboard")
            .onAppear {
                // Set up listeners when the view appears
                if let childId = authViewModel.currentUser?.uid {
                    viewModel.setupListeners(forChild: childId)
                } else {
                    // Handle case where child user is not authenticated (shouldn't happen if routed correctly)
                    viewModel.error = NSError(domain: "ChildDashboardViewError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Child user not authenticated."])
                }
            }
            .onDisappear {
                // Remove listeners when the view disappears
                viewModel.removeListeners()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Greeting Text
                    if let childProfile = viewModel.childProfile {
                         Text("Hi \(childProfile.name ?? "User")")
                             .font(Font.theme.body)
                             .foregroundColor(Color.theme.textSecondary)
                    }

                    // Profile Picture Navigation Link
                    if let childProfile = viewModel.childProfile {
                        NavigationLink {
                            // Ensure AuthViewModel is passed if ChildProfileView needs it
                            ChildProfileView(viewModel: ProfileViewModel(childProfile: childProfile))
                                .environmentObject(authViewModel)
                        } label: {
                            if let imageUrlString = childProfile.profilePictureUrl, let imageUrl = URL(string: imageUrlString) {
                                AsyncImage(url: imageUrl) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable()
                                             .aspectRatio(contentMode: .fill)
                                             .frame(width: 30, height: 30)
                                             .clipShape(Circle())
                                    case .failure, .empty:
                                        Image(systemName: "person.circle.fill")
                                            .resizable().scaledToFit()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(Color.theme.textSecondary)
                                    @unknown default:
                                        EmptyView().frame(width: 30, height: 30)
                                    }
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable().scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                        }
                    } else {
                         // Placeholder if profile not loaded
                         Image(systemName: "person.circle.fill")
                             .resizable().scaledToFit()
                             .frame(width: 30, height: 30)
                             .foregroundColor(Color.theme.textSecondary)
                    }
                    // Removed Sign Out Button from here
                } // End ToolbarItemGroup
            }
        }
    }
}

struct ChildDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock data for preview
        ChildDashboardView()
            .environmentObject(AuthViewModel()) // Provide a mock AuthViewModel
    }
}
