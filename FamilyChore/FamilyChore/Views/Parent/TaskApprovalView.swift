import SwiftUI
import FirebaseFirestore // Import Firestore for Timestamp if needed in preview

/// A view for parents to review and approve or decline a submitted task.
struct TaskApprovalView: View {
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    @StateObject var viewModel: TaskApprovalViewModel // ViewModel initialized with the task

    @State private var showingOperationSuccessAlert = false
    @State private var operationSuccessMessage = ""
    @State private var showingFullScreenImage = false // State to control full screen image presentation

    // Initialize with the task that needs approval
    init(task: ChildTask) {
        _viewModel = StateObject(wrappedValue: TaskApprovalViewModel(task: task))
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Task Details...")
                    .font(Font.theme.body) // Apply font
            } else if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
                    .font(Font.theme.footnote) // Apply font
                    .foregroundColor(.red)
            } else if let task = viewModel.task {
                // Display Task Details
                Text(task.title)
                    .font(Font.theme.funLargeTitle) // Use fun font
                    .foregroundColor(Color.theme.textPrimary)
                    .padding()

                    Text(task.description)
                        .font(Font.theme.body) // Use theme font
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)

                Text("Points: \(task.points)")
                    .font(Font.theme.headline) // Use theme font
                    .foregroundColor(Color.theme.textPrimary)
                    .padding(.top)

                if let childName = viewModel.child?.name {
                    Text("Submitted by: \(childName)")
                        .font(Font.theme.subheadline) // Use theme font
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.bottom)
                }

                // TODO: Display photo proof if available (requires Storage integration in Phase 6)
                if let proofImageUrl = task.proofImageUrl, let url = URL(string: proofImageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200) // Limit size in the list
                                .cornerRadius(8)
                                .onTapGesture {
                                    showingFullScreenImage = true // Show full screen on tap
                                }
                        } else if phase.error != nil {
                            Text("Error loading image")
                                .font(Font.theme.footnote) // Apply font
                                .foregroundColor(.red)
                        } else {
                            ProgressView() // Show loading indicator
                                .font(Font.theme.body) // Apply font
                        }
                    }
                    .padding()
                    .sheet(isPresented: $showingFullScreenImage) {
                        // Present full screen image view
                        FullScreenImageView(imageUrl: proofImageUrl)
                    }
                } else {
                    Text("No photo proof provided.")
                        .font(Font.theme.body) // Apply font
                        .foregroundColor(.gray)
                        .padding()
                }

                Spacer()

                HStack {
                    Button("Decline") {
                        Task {
                            await viewModel.declineTask()
                            if viewModel.operationSuccessful {
                                operationSuccessMessage = "Task declined successfully!"
                                showingOperationSuccessAlert = true
                            }
                        }
                    }
                    .buttonStyle(FunkyButtonStyle(backgroundColor: .red)) // Apply style with red background
                    // Removed manual styling

                    Button("Approve") {
                        Task {
                            await viewModel.approveTask()
                            if viewModel.operationSuccessful {
                                operationSuccessMessage = "Task approved successfully!"
                                showingOperationSuccessAlert = true
                            }
                        }
                    }
                    .buttonStyle(FunkyButtonStyle()) // Apply default style
                    // Removed manual styling
                }
                .padding(.horizontal)

            } else {
                Text("Task not found.")
                    .font(Font.theme.body) // Apply font
                    .foregroundColor(.gray)
            }
        }
        .appBackground() // Apply themed background
        .navigationTitle("Review Task")
        .alert(isPresented: $showingOperationSuccessAlert) {
            Alert(title: Text("Success"), message: Text(operationSuccessMessage), dismissButton: .default(Text("OK")) {
                presentationMode.wrappedValue.dismiss() // Dismiss the view on success
            })
        }
    }
}
