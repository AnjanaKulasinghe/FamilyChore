import SwiftUI

/// The main dashboard view for Parent users.
struct ParentDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To access current user/profile
    @StateObject var viewModel = ParentDashboardViewModel() // ViewModel for dashboard data
    @StateObject var manageChildrenViewModel = ManageChildrenViewModel() // ViewModel for managing children
    @State private var showingAddChildView = false // State for presenting AddChildView modally

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
                            Section(header: Text("Children").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) {
                                if manageChildrenViewModel.children.isEmpty {
                                    Text("No children added yet.")
                                        .font(Font.theme.body)
                                        .foregroundColor(Color.theme.textSecondary)
                                } else {
                                    ForEach(manageChildrenViewModel.children) { child in
                                        NavigationLink {
                                            EditChildView(childProfile: child)
                                                .environmentObject(manageChildrenViewModel)
                                        } label: {
                                            HStack(spacing: 15) {
                                                if let imageUrlString = child.profilePictureUrl, let imageUrl = URL(string: imageUrlString) {
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
                                                            Image(systemName: "person.circle.fill")
                                                                .resizable().scaledToFit()
                                                                .frame(width: 40, height: 40)
                                                                .foregroundColor(Color.theme.textSecondary)
                                                        @unknown default:
                                                            EmptyView().frame(width: 40, height: 40)
                                                        }
                                                    }
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
                                    .onDelete(perform: deleteChild)
                                }
                                // Button to present AddChildView modally
                                Button {
                                    showingAddChildView = true
                                } label: {
                                    Label("Add New Child", systemImage: "plus.circle.fill")
                                        .font(Font.theme.headline)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(Color.theme.accentApp)
                                .listRowBackground(Color.theme.accentApp.opacity(0.1))
                            }
                            .listRowSeparator(.hidden)

                            Section(header: Text("Tasks Needing Approval").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) {
                                if viewModel.tasksNeedingApproval.isEmpty {
                                    Text("No tasks currently need approval.")
                                        .font(Font.theme.body)
                                        .foregroundColor(Color.theme.textSecondary)
                                } else {
                                    ForEach(viewModel.tasksNeedingApproval) { task in
                                        NavigationLink {
                                            TaskApprovalView(task: task)
                                        } label: {
                                            Text(task.title)
                                                .font(Font.theme.subheadline)
                                                .foregroundColor(Color.theme.textPrimary)
                                        }
                                    }
                                }
                            }
                            .listRowSeparator(.hidden)

                            Section(header: Text("Manage Tasks & Rewards").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) {
                                NavigationLink(destination: ManageTasksView()) {
                                    Text("Manage Tasks")
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                .font(Font.theme.body)
                                NavigationLink(destination: ManageRewardsView()) {
                                    Text("Manage Rewards")
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                .font(Font.theme.body)
                            }
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(.insetGrouped) // Or .plain
                        .scrollContentBackground(.hidden) // Make List background transparent (iOS 16+)
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
                        await viewModel.fetchData(forFamily: familyId)
                        manageChildrenViewModel.setupListener(forFamily: familyId)
                    }
                } else {
                    viewModel.error = NSError(domain: "ParentDashboardError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Parent profile missing family ID."])
                }
            }
            .onDisappear {
                manageChildrenViewModel.removeListener()
            }
            .sheet(isPresented: $showingAddChildView) {
                // Present AddChildView modally
                NavigationView {
                    AddChildView()
                        .environmentObject(authViewModel)
                        .environmentObject(manageChildrenViewModel)
                }
            }
        } // End of NavigationView
        .navigationViewStyle(.stack)
    } // End of body

    /// Deletes children at the specified offsets.
    private func deleteChild(at offsets: IndexSet) {
        let childrenToDelete = offsets.map { manageChildrenViewModel.children[$0] }
        for child in childrenToDelete {
            Task {
                await manageChildrenViewModel.removeChild(child)
            }
        }
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
