import SwiftUI

/// The main dashboard view for Parent users.
struct ParentDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To access current user/profile
    @StateObject var viewModel = ParentDashboardViewModel() // ViewModel now handles parents, children, tasks
    @State private var showingAddChildView = false // State for presenting AddChildView modally
    @State private var showingAddCoParentView = false // State for presenting AddCoParentView modally

    var body: some View {
        NavigationView {
            ZStack { // ZStack allows layering background behind content
                // The actual background (color or image) is applied via .appBackground() modifier below

                VStack { // Main content container
                    if viewModel.isLoading {
                        ProgressView("Loading Dashboard...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .font(Font.theme.body)
                            .padding()
                    } else if let error = viewModel.error {
                        Text("Error: \(error.localizedDescription)")
                            .font(Font.theme.footnote)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        // Display Parent Dashboard content
                        List {
                            // --- Family Management Section ---
                            Section(header: FamilySectionHeader()) {
                                // Parents List
                                SubSectionHeader(title: "Parents")
                                if viewModel.parents.isEmpty {
                                    Text("Loading parents...") // Or just you if no co-parent added
                                        .font(Font.theme.body)
                                        .foregroundColor(Color.theme.textSecondary)
                                } else {
                                    ForEach(viewModel.parents) { parent in
                                        ParentRow(parent: parent)
                                    }
                                    // Allow removing other parents? Maybe not from here.
                                }
                                // Add Co-Parent Button
                                Button { showingAddCoParentView = true } label: {
                                    Label("Add Co-Parent", systemImage: "person.badge.plus")
                                        .font(Font.theme.headline)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(Color.theme.accentApp)
                                .listRowBackground(Color.theme.accentApp.opacity(0.1))

                                // Children List
                                SubSectionHeader(title: "Children")
                                if viewModel.children.isEmpty {
                                    Text("No children added yet.")
                                        .font(Font.theme.body)
                                        .foregroundColor(Color.theme.textSecondary)
                                } else {
                                    ForEach(viewModel.children) { child in
                                        // Navigate to the new ChildDetailView
                                        NavigationLink {
                                            // Pass the child's ID to the detail view
                                            if let childId = child.id {
                                                ChildDetailView(childId: childId)
                                            } else {
                                                // Handle case where child ID is missing (shouldn't happen ideally)
                                                Text("Error: Child ID missing")
                                            }
                                        } label: {
                                            ChildRow(child: child) // Keep using the extracted row view
                                        }
                                    }
                                    .onDelete(perform: deleteChild) // Use ParentDashboardViewModel's delete
                                }
                                // Add Child Button
                                Button { showingAddChildView = true } label: {
                                    Label("Add New Child", systemImage: "plus.circle.fill")
                                        .font(Font.theme.headline)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(Color.theme.accentApp)
                                .listRowBackground(Color.theme.accentApp.opacity(0.1))
                            }
                            .listRowSeparator(.hidden) // Apply to the whole section

// --- Pending Reward Claims Section ---
                            Section(header: Text("Pending Reward Claims").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) {
                                if viewModel.pendingRewardClaims.isEmpty {
                                    Text("No rewards currently claimed.")
                                        .font(Font.theme.body)
                                        .foregroundColor(Color.theme.textSecondary)
                                } else {
                                    ForEach(viewModel.pendingRewardClaims) { claim in
                                        NavigationLink {
                                            RewardClaimApprovalView(rewardClaim: claim)
                                        } label: {
                                            // Extracted Row View (or keep inline VStack)
                                            RewardClaimRow(claim: claim)
                                        }
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)
                            // --- Tasks Needing Approval Section ---
                            Section(header: Text("Tasks Needing Approval").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) {
                                if viewModel.tasksNeedingApproval.isEmpty {
                                    Text("No tasks currently need approval.")
                                        .font(Font.theme.body)
                                        .foregroundColor(Color.theme.textSecondary)
                                } else {
                                    ForEach(viewModel.tasksNeedingApproval) { task in
                                        NavigationLink {
                                            TaskApprovalView(task: task)
                                                .environmentObject(viewModel) // Pass dashboard VM if needed
                                        } label: {
                                            Text(task.title)
                                                .font(Font.theme.subheadline)
                                                .foregroundColor(Color.theme.textPrimary)
                                        }
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)

                            // --- Manage Tasks & Rewards Section ---
                            Section(header: Text("Manage Tasks & Rewards").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) {
                                NavigationLink(destination: ManageTasksView()) { // Assumes ManageTasksView uses its own VM or gets familyId
                                    Text("Manage Tasks")
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                .font(Font.theme.body)
                                NavigationLink(destination: ManageRewardsView()) { // Assumes ManageRewardsView uses its own VM or gets familyId
                                    Text("Manage Rewards")
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                .font(Font.theme.body)
                            }
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear) // Fallback/alternative for List background
                        .font(Font.theme.body) // Default font for list content
                    }
                } // End of main content VStack
            } // End of ZStack
            .appBackground() // Apply themed background to the ZStack
            .navigationTitle("Parent Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Greeting Text
                    if let profile = authViewModel.userProfile {
                        Text("Hi \(profile.name ?? "User")")
                            .font(Font.theme.body)
                            .foregroundColor(Color.theme.textSecondary)
                    }

                    // Profile Picture Navigation Link
                    if let profile = authViewModel.userProfile {
                        NavigationLink {
                            // Navigate to ParentProfileView, passing the profile
                            ParentProfileView(viewModel: ProfileViewModel(childProfile: profile))
                                .environmentObject(authViewModel) // Pass AuthViewModel if needed by ParentProfileView
                        } label: {
                            if let imageUrlString = profile.profilePictureUrl, let imageUrl = URL(string: imageUrlString) {
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
            .onAppear {
                // Fetch data when the view appears
                if let familyId = authViewModel.userProfile?.familyId {
                    Task {
                        // Fetch data using ParentDashboardViewModel
                        await viewModel.fetchData(forFamily: familyId)
                        // Setup listeners using ParentDashboardViewModel
                        viewModel.setupListeners(forFamily: familyId)
                    }
                } else {
                    // Use ParentDashboardViewModel's error property
                    viewModel.error = NSError(domain: "ParentDashboardError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Parent profile missing family ID."])
                }
            }
            .onDisappear {
                // Remove listeners using ParentDashboardViewModel
                viewModel.removeListeners()
            }
            .sheet(isPresented: $showingAddChildView) {
                // Present AddChildView modally
                NavigationView {
                    // AddChildView might need ParentDashboardViewModel if it interacts with family data directly
                    AddChildView()
                        .environmentObject(authViewModel)
                        .environmentObject(viewModel) // Pass ParentDashboardViewModel
                }
            }
             .sheet(isPresented: $showingAddCoParentView) {
                 // Present AddCoParentView modally
                 NavigationView {
                     AddCoParentView()
                         .environmentObject(authViewModel)
                         // AddCoParentView uses its own ViewModel
                 }
             }
        } // End of NavigationView
        .navigationViewStyle(.stack)
    } // End of body

    /// Deletes children at the specified offsets using ParentDashboardViewModel.
    private func deleteChild(at offsets: IndexSet) {
        let childrenToDelete = offsets.map { viewModel.children[$0] }
        for child in childrenToDelete {
            Task {
                // Need a removeChild function in ParentDashboardViewModel or FirebaseService
                // For now, assuming FirebaseService.removeChildAccount exists
                if let childId = child.id, let familyId = child.familyId {
                    do {
                        try await FirebaseService.shared.removeChildAccount(childId: childId, fromFamily: familyId)
                        print("Successfully initiated removal for child \(childId)")
                        // Listener should update the list
                    } catch {
                        print("Error initiating child removal: \(error.localizedDescription)")
                        // Optionally set viewModel.error here
                    }
                }
            }
        }
    }
}

// MARK: - Subviews for Rows and Headers (Extracted for clarity)

struct FamilySectionHeader: View {
    var body: some View {
        HStack {
            Image(systemName: "house.fill")
            Text("Family Management")
        }
        .font(Font.theme.title3) // Use a slightly larger font for main section
        .foregroundColor(Color.theme.textPrimary)
        .textCase(nil) // Prevent automatic uppercasing
        .padding(.bottom, 5)
    }
}

struct SubSectionHeader: View {
    let title: String
    var body: some View {
         Text(title)
            .font(Font.theme.headline)
            .foregroundColor(Color.theme.textSecondary)
            .padding(.top, 10) // Add space above subsection headers
    }
}


struct ParentRow: View {
    let parent: UserProfile

    var body: some View {
        HStack(spacing: 15) {
            if let imageUrlString = parent.profilePictureUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(width: 40, height: 40)
                    case .success(let image): image.resizable().aspectRatio(contentMode: .fill).frame(width: 40, height: 40).clipShape(Circle())
                    case .failure: Image(systemName: "person.crop.circle.badge.exclamationmark.fill").resizable().scaledToFit().frame(width: 40, height: 40).foregroundColor(.red)
                    @unknown default: EmptyView().frame(width: 40, height: 40)
                    }
                }
                .id("parent-\(parent.id ?? UUID().uuidString)-\(imageUrlString)") // More specific ID
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable().scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.theme.textSecondary)
            }
            Text(parent.name ?? parent.email) // Show name or email
                .font(Font.theme.headline)
                .foregroundColor(Color.theme.textPrimary)
        }
        .padding(.vertical, 8)
    }
}

struct ChildRow: View {
    let child: UserProfile

    var body: some View {
         HStack(spacing: 15) {
             if let imageUrlString = child.profilePictureUrl, let imageUrl = URL(string: imageUrlString) {
                 AsyncImage(url: imageUrl) { phase in
                     switch phase {
                     case .empty: ProgressView().frame(width: 40, height: 40)
                     case .success(let image): image.resizable().aspectRatio(contentMode: .fill).frame(width: 40, height: 40).clipShape(Circle())
                     case .failure: Image(systemName: "person.crop.circle.badge.exclamationmark.fill").resizable().scaledToFit().frame(width: 40, height: 40).foregroundColor(.red)
                     @unknown default: EmptyView().frame(width: 40, height: 40)
                     }
                 }
                 .id("child-\(child.id ?? UUID().uuidString)-\(imageUrlString)") // More specific ID
             } else {
                 Image(systemName: "person.circle.fill")
                     .resizable().scaledToFit()
                     .frame(width: 40, height: 40)
                     .foregroundColor(Color.theme.textSecondary)
             }
             Text(child.name ?? "Unnamed Child")
                 .font(Font.theme.headline)
                 .foregroundColor(Color.theme.textPrimary)
         }
         .padding(.vertical, 8)
    }
}

//struct ParentDashboardView_Previews: PreviewProvider {
//    static var previews: some View {
//        ParentDashboardView()
//            .environmentObject(AuthViewModel.mock) // Use a mock for preview
//            .environmentObject(ManageChildrenViewModel.mock) // Use a mock for preview
//    }
//}
//
//// Add mock extensions if they don't exist for previewing
//extension AuthViewModel {
//    static var mock: AuthViewModel {
//        let vm = AuthViewModel()
//        vm.userProfile = UserProfile(id: "parent1", email: "parent@test.com", role: .parent, familyId: "fam1", name: "Test Parent")
//        vm.currentUser = MockFirebaseUser(uid: "parent1")
//        // Simulate loading finished state for preview
//        vm.isLoading = false 
//        return vm
//    }
//}
//
//extension ManageChildrenViewModel {
//     static var mock: ManageChildrenViewModel {
//         let vm = ManageChildrenViewModel()
//         vm.children = [
//            UserProfile(id: "child1", email: "c1@test.com", role: .child, familyId: "fam1", name: "Alice", profilePictureUrl: nil),
//            UserProfile(id: "child2", email: "c2@test.com", role: .child, familyId: "fam1", name: "Bob", profilePictureUrl: nil)
//         ]
//         // Simulate loading finished state for preview
//         vm.isLoading = false 
//         return vm
//     }
// }
//
//// Dummy Firebase User for preview - ensure this is defined if not already
//struct MockFirebaseUser {
//    let uid: String
//}
//
//// Ensure ParentDashboardViewModel has mock data or state for preview if needed
//extension ParentDashboardViewModel {
//    // Add mock data or states if necessary for previews
//}

struct RewardClaimRow: View {
    let claim: RewardClaim

    var body: some View {
        VStack(alignment: .leading) {
            Text("Reward: \(claim.rewardTitle)")
                .font(Font.theme.headline)
            Text("Child: \(claim.childName ?? "Unknown")")
                .font(Font.theme.subheadline)
            Text("Status: \(claim.status.displayName)")
                .font(Font.theme.caption1)
                .foregroundColor(statusColor(claim.status)) // Use helper for color
            Text("Claimed: \(claim.claimedAt.dateValue(), style: .date)")
                .font(Font.theme.caption1)
                .foregroundColor(Color.theme.textSecondary)
            // Optionally show reminder/promised date
             if claim.status == .reminded, let remindedAt = claim.lastRemindedAt {
                 Text("Last Reminder: \(remindedAt.dateValue(), style: .date)")
                     .font(Font.theme.caption1)
                     .foregroundColor(.orange)
             }
             if claim.status == .promised, let promisedDate = claim.promisedDate {
                  Text("Promised Date: \(promisedDate.dateValue(), style: .date)")
                      .font(Font.theme.caption1)
                      .foregroundColor(.blue)
              }
        }
        .padding(.vertical, 4)
    }

    // Helper function for status color (can be shared if needed)
    private func statusColor(_ status: ClaimStatus) -> Color {
        switch status {
        case .pending: return Color.theme.textSecondary
        case .reminded: return .orange
        case .promised: return .blue
        case .granted: return .green
        }
    }
}
