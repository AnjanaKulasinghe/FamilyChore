import SwiftUI

/// Displays detailed information about a specific child, including tasks and rewards.
struct ChildDetailView: View {
    @StateObject var viewModel: ChildDetailViewModel
    @State private var showingEditChildView = false
    // State variables for DisclosureGroups:
    @State private var completedTasksExpanded = false // Keep this one
    @State private var pendingClaimsExpanded = true // Start expanded?
    @State private var promisedClaimsExpanded = false
    @State private var grantedClaimsExpanded = false
    // Removed earnedRewardsExpanded as it's replaced by specific claim states

    // Initializer accepting the child's UserProfile ID
    init(childId: String) {
        _viewModel = StateObject(wrappedValue: ChildDetailViewModel(childId: childId))
    }

    // Removed duplicate state variable declarations from here
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isLoading {
                    ProgressView("Loading Child Details...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if let profile = viewModel.childProfile {
                    // --- Profile Header ---
                    ProfileHeader(profile: profile) {
                        showingEditChildView = true // Action to trigger edit sheet/navigation
                    }
                    .padding(.horizontal)

                    // --- Active Tasks ---
                    TasksSection(title: "Active Tasks", tasks: viewModel.pendingTasks)
                        .padding(.horizontal)

                    // --- Unclaimed Rewards Progress ---
                    RewardsProgressSection(
                        title: "Rewards Progress (Unclaimed)",
                        rewards: viewModel.unclaimedRewards, // Use unclaimed
                        viewModel: viewModel
                    )
                    .padding(.horizontal)

                    // --- Claimed Rewards (Collapsible Sections) ---
                    // Pending/Reminded Claims
                    DisclosureGroup("Pending Claims (\(viewModel.pendingClaims.count))", isExpanded: $pendingClaimsExpanded) {
                         // Use placeholder until ClaimedRewardsList is restored
                         Text("Placeholder for Pending Claims")
                    }
                    .padding(.horizontal)
                    .font(Font.theme.headline)
                    .accentColor(Color.theme.textSecondary)

                    // Promised Claims
                    DisclosureGroup("Promised Rewards (\(viewModel.promisedClaims.count))", isExpanded: $promisedClaimsExpanded) {
                         // Use placeholder until ClaimedRewardsList is restored
                         Text("Placeholder for Promised Claims")
                    }
                    .padding(.horizontal)
                    .font(Font.theme.headline)
                    .accentColor(Color.theme.textSecondary)

                    // Granted Claims
                    DisclosureGroup("Granted Rewards (\(viewModel.grantedClaims.count))", isExpanded: $grantedClaimsExpanded) {
                         // Use placeholder until ClaimedRewardsList is restored
                         Text("Placeholder for Granted Claims")
                    }
                    .padding(.horizontal)
                    .font(Font.theme.headline)
                    .accentColor(Color.theme.textSecondary)


                    // --- Completed Tasks (Collapsible) ---
                    DisclosureGroup("Completed Tasks (\(viewModel.completedTasks.count))", isExpanded: $completedTasksExpanded) {
                        TasksSection(title: nil, tasks: viewModel.completedTasks)
                    }
                    .padding(.horizontal)
                    .font(Font.theme.headline)
                    .accentColor(Color.theme.textSecondary)


                } else {
                    Text("Child profile not found.")
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.childProfile?.name ?? "Child Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { // Use .task for async operations tied to view lifecycle
            await viewModel.fetchData()
        }
        .sheet(isPresented: $showingEditChildView) {
            // Present EditChildView modally
            if let profile = viewModel.childProfile {
                 NavigationView {
                     // EditChildView might need adaptation if it expects ManageChildrenViewModel
                     EditChildView(childProfile: profile)
                         // Pass necessary environment objects if EditChildView needs them
                         // .environmentObject(someOtherViewModelIfNeeded)
                 }
            }
        }
        .appBackground() // Apply background consistently
    }
}

// MARK: - Subviews for ChildDetailView

// State variables moved above body

private struct ProfileHeader: View {
    let profile: UserProfile
    var onEdit: () -> Void // Closure to handle edit action

    var body: some View {
        HStack(spacing: 15) {
            // Profile Picture
            if let imageUrlString = profile.profilePictureUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(width: 60, height: 60)
                    case .success(let image): image.resizable().aspectRatio(contentMode: .fill).frame(width: 60, height: 60).clipShape(Circle())
                    case .failure: Image(systemName: "person.circle.fill").resizable().scaledToFit().frame(width: 60, height: 60).foregroundColor(.gray)
                    @unknown default: EmptyView().frame(width: 60, height: 60)
                    }
                }
                .id("detail-\(profile.id ?? "")-\(imageUrlString)") // ID for refresh
            } else {
                Image(systemName: "person.circle.fill").resizable().scaledToFit().frame(width: 60, height: 60).foregroundColor(.gray)
            }

            // Name and Points
            VStack(alignment: .leading) {
                Text(profile.name ?? "Unnamed Child").font(Font.theme.title2)
                // Removed unnecessary nil-coalescing operator as profile.points is non-optional Int64
                Text("Points: \(profile.points)").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)
            }

            Spacer()

            // Edit Button
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(Color.theme.accentApp)
            }
        }
    }
}

private struct TasksSection: View {
    let title: String?
    let tasks: [ChildTask]

    var body: some View {
        VStack(alignment: .leading) {
            if let title = title {
                Text(title).font(Font.theme.title3).padding(.bottom, 5)
            }
            if tasks.isEmpty {
                Text(title == nil ? "None" : "No tasks in this category.")
                    .font(Font.theme.body)
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(.vertical, 5)
            } else {
                ForEach(tasks) { task in
                    TaskRow(task: task) // Use a dedicated TaskRow view
                        .padding(.vertical, 3)
                }
            }
        }
        .padding()
        .background(Color.theme.background.opacity(0.5)) // Slight background contrast
        .cornerRadius(10)
    }
}

// Simple Task Row (Customize as needed)
private struct TaskRow: View {
    let task: ChildTask
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title).font(Font.theme.headline)
                // Check if the non-optional description is empty
                if !task.description.isEmpty {
                    Text(task.description).font(Font.theme.footnote).foregroundColor(.gray)
                }
            }
            Spacer()
            Text("\(task.points) pts").font(Font.theme.body).foregroundColor(Color.theme.accentApp)
            // Add status icon if needed
            statusIcon(for: task.status)
                .foregroundColor(statusColor(for: task.status))

        }
    }

     private func statusIcon(for status: TaskStatus) -> Image {
         switch status {
         case .pending: return Image(systemName: "circle") // Or clock
         case .submitted: return Image(systemName: "hourglass") // Or paperplane
         case .approved: return Image(systemName: "checkmark.circle.fill")
         case .declined: return Image(systemName: "xmark.circle.fill")
         }
     }

     private func statusColor(for status: TaskStatus) -> Color {
         switch status {
         case .pending: return Color.theme.textSecondary
         case .submitted: return Color.orange
         case .approved: return Color.green
         case .declined: return Color.red
         }
     }
}


private struct RewardsProgressSection: View {
    let title: String
    let rewards: [Reward]
    @ObservedObject var viewModel: ChildDetailViewModel // To access child points and progress func

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(Font.theme.title3).padding(.bottom, 5)
            if rewards.isEmpty {
                Text("No rewards assigned.")
                    .font(Font.theme.body)
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(.vertical, 5)
            } else {
                // Get current points once for the section
                let currentPoints = viewModel.childProfile?.points ?? 0
//                ForEach(rewards) { reward in
//                    RewardProgressRow(
//                        claim: <#RewardClaim?#>, reward: reward,
//                        progress: viewModel.progress(for: reward),
//                        currentPoints: currentPoints // Pass current points
//                    )
//                    .padding(.vertical, 3)
//                }
            }
        }
        .padding()
        .background(Color.theme.background.opacity(0.5))
        .cornerRadius(10)
    }
}

// Simple Reward Row with Progress
// New Subview for displaying lists of claimed rewards
/* Temporarily commented out entire struct definition
private struct ClaimedRewardsList: View {
    let claims: [RewardClaim]

    var body: some View {
        VStack(alignment: .leading) {
            if claims.isEmpty {
                Text("None")
                    .font(Font.theme.body)
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(.vertical, 5)
            } else {
                // Temporarily replace ForEach to test compilation
                Text("Found \(claims.count) claim(s)")
            }
        }
        .padding([.leading, .bottom, .top]) // Indent list within DisclosureGroup
    }
}
*/
// Removed duplicate definition of RewardProgressRow
