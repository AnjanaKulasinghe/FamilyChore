import SwiftUI

/// A view displaying the details of a task for a child.
struct TaskDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To access current child's profile if needed
    @StateObject var viewModel: TaskSubmissionViewModel // ViewModel for task submission

    // Initialize with the task to display
    init(task: ChildTask) {
        _viewModel = StateObject(wrappedValue: TaskSubmissionViewModel(task: task))
    }

    var body: some View {
        VStack {
            let task = viewModel.task
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

                // Display task image if available
                if let imageUrlString = task.imageUrl, let imageUrl = URL(string: imageUrlString) {
                     AsyncImage(url: imageUrl) { phase in
                         switch phase {
                         case .success(let image):
                             image.resizable()
                                  .aspectRatio(contentMode: .fit)
                                  .cornerRadius(10)
                                  .shadow(radius: 5)
                                  .padding(.horizontal) // Add padding around image
                         case .failure:
                             Image(systemName: "photo.fill") // Placeholder on failure
                                 .resizable()
                                 .scaledToFit()
                                 .frame(height: 150)
                                 .foregroundColor(.gray)
                         case .empty:
                             ProgressView() // Loading indicator
                                 .frame(height: 150)
                         @unknown default:
                             EmptyView()
                                 .frame(height: 150)
                         }
                     }
                     .padding(.vertical) // Add vertical padding
                 }
                 // No else needed, just won't show anything if no URL

                Spacer()

                // Show "Mark as Done" button only if the task is pending
                if task.status == .pending {
                    NavigationLink("Mark as Done") {
                        // Navigate to the Task Submission View, passing the TaskSubmissionViewModel
                        TaskSubmissionView(viewModel: viewModel)
                    }
                    .buttonStyle(FunkyButtonStyle()) // Apply style
                    .padding(.horizontal)
                    // Removed manual styling
                } else if task.status == .declined {
                    VStack {
                        Text("Naughty naught!")
                            .font(Font.theme.title1) // Use theme font
                            .foregroundColor(.red)
                            .padding()

                        Text("Your task was declined. Please fix it and resubmit.")
                            .font(Font.theme.body) // Use theme font
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        NavigationLink("Resubmit Task") {
                            // Navigate to the Task Submission View, passing the TaskSubmissionViewModel
                            TaskSubmissionView(viewModel: viewModel)
                        }
                        .buttonStyle(FunkyButtonStyle(backgroundColor: .orange)) // Apply style with specific color
                        .padding(.horizontal)
                        // Removed manual styling
                    }
                }
                else {
                    Text("Status: \(task.status.displayName)")
                        .font(Font.theme.headline) // Use theme font
                        .foregroundColor(Color.theme.textSecondary)
                        .padding()
                }
        }
        .appBackground() // Apply themed background
        .navigationTitle("Task Details")
    }
}
