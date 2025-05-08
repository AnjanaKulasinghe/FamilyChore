import SwiftUI

/// A view for parents to manage (list, add, edit, delete) tasks for the family.
struct ManageTasksView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To get family ID
    @StateObject var viewModel = ManageTasksViewModel()
    @State private var showingCreateTaskView = false // To present CreateTaskView modally or via NavigationLink

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Tasks...")
                    .font(Font.theme.body) // Apply font
            } else if let error = viewModel.error {
                Text("Error loading tasks: \(error.localizedDescription)")
                    .font(Font.theme.footnote) // Apply font
                    .foregroundColor(.red)
            } else {
                List {
                    ForEach(viewModel.tasks) { task in
                        NavigationLink {
                            // Navigate to CreateTaskView for editing, passing the existing task
                            CreateTaskView(viewModel: TaskViewModel(task: task))
                        } label: {
                            HStack {
                                if let imageUrlString = task.imageUrl, let imageUrl = URL(string: imageUrlString) {
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
                                    Image(systemName: "list.bullet.circle.fill") // Placeholder if no image URL
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray)
                                }
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                        .font(Font.theme.headline) // Apply font
                                        .foregroundColor(Color.theme.textPrimary)
                                    Text("Points: \(task.points)")
                                        .font(Font.theme.subheadline) // Apply font
                                        .foregroundColor(Color.theme.textSecondary)
                                    // Add other relevant task info if needed
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteTask) // Restored original onDelete
                }
                .listStyle(.insetGrouped) // Match style of ParentDashboardView
                .font(Font.theme.body) // Default font for list content
                .padding(.top) // Add padding between title and list
                .scrollContentBackground(.hidden) // Make List background transparent (iOS 16+)
                .background(Color.clear) // Fallback/alternative for List background
            }
        }
        .appBackground() // Apply themed background
        .navigationTitle("Manage Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateTaskView = true
                } label: {
                    Label("Add Task", systemImage: "plus")
                        .font(Font.theme.body) // Apply font to label
                }
                .tint(Color.theme.accentApp) // Style toolbar button
            }
        }
        .sheet(isPresented: $showingCreateTaskView, onDismiss: {
            // Re-fetch tasks when the sheet is dismissed to see updates/new items
            if let familyId = authViewModel.userProfile?.familyId {
                Task {
                    await viewModel.fetchTasks(forFamily: familyId)
                }
            }
        }) {
            // Present CreateTaskView modally for adding a new task
            NavigationView { // Embed in NavigationView for title and potential buttons
                // Pass a new, empty TaskViewModel for creating a task
                CreateTaskView(viewModel: TaskViewModel())
            }
            // Pass environment objects if CreateTaskView needs them
             .environmentObject(authViewModel)
        }
        .onAppear {
            // Fetch tasks when the view appears
            if let familyId = authViewModel.userProfile?.familyId {
                Task {
                    await viewModel.fetchTasks(forFamily: familyId)
                }
            } else {
                viewModel.error = NSError(domain: "ManageTasksViewError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Family ID not found."])
            }
        }
    }

    /// Deletes tasks at the specified offsets.
    private func deleteTask(at offsets: IndexSet) {
        offsets.map { viewModel.tasks[$0] }.forEach { task in
            Task {
                await viewModel.deleteTask(task)
            }
        }
        // Note: If not using a listener, manually remove from the local array for immediate UI update:
        // viewModel.tasks.remove(atOffsets: offsets)
    }
}

struct ManageTasksView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ManageTasksView()
                .environmentObject(AuthViewModel()) // Provide mock AuthViewModel
        }
    }
}