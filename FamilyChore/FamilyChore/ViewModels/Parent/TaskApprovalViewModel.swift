import Foundation
import Combine
import FirebaseFirestore // For Firestore types
// Assuming FirebaseService and Models are accessible

/// ViewModel for handling the approval or decline of a submitted task by a parent.
class TaskApprovalViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The task being reviewed.
    @Published var task: ChildTask?

    /// The child who submitted the task.
    @Published var child: UserProfile?

    /// Indicates if data is currently being loaded or an operation is in progress.
    @Published var isLoading = false

    /// Stores any error that occurred.
    @Published var error: Error?

    /// Indicates if the approval/decline operation was successful.
    @Published var operationSuccessful = false

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    // MARK: - Initialization

    /// Initializes the ViewModel with the task to be reviewed.
    /// - Parameter task: The Task object submitted by the child.
    init(task: ChildTask) {
        self.task = task
        // print("[TaskApprovalVM] Initializing with task ID: \(task.id ?? "nil"), Title: \(task.title)") // Removed diagnostic
        // print("[TaskApprovalVM] Assigned Child IDs: \(task.assignedChildIds)") // Removed diagnostic
        
        // Fetch profile for the first assigned child (assuming valid data now)
        if let childId = task.assignedChildIds.first, !childId.isEmpty {
            // print("[TaskApprovalVM] Fetching profile for child ID: \(childId)") // Removed diagnostic
            Task { [weak self] in
                await self?.fetchChildProfile(childId: childId)
            }
        } else {
            // Handle case where assignedChildIds is empty (shouldn't happen for submitted task)
            print("[TaskApprovalVM] Error: No child ID found in assignedChildIds for submitted task \(task.id ?? "nil").")
            DispatchQueue.main.async {
                 self.error = NSError(domain: "TaskApprovalViewModelError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Cannot identify child who submitted the task."])
            }
        }
    }

    // MARK: - Data Fetching

    /// Fetches the profile of the child who submitted the task.
    /// - Parameter childId: The ID of the child.
    @MainActor
    private func fetchChildProfile(childId: String) async {
        isLoading = true
        error = nil
        // Removed Task wrapper as function is already @MainActor and called within a Task
        do {
            self.child = try await firebaseService.fetchUserProfile(userId: childId)
            // print("Fetched child profile for task approval: \(childId)") // Removed diagnostic
        } catch {
            self.error = error
            print("Error fetching child profile for task approval (\(childId)): \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Actions

    /// Approves the current task.
    @MainActor // Ensure UI updates happen on the main thread
    func approveTask() async {
        guard let taskToApprove = task else {
            self.error = NSError(domain: "TaskApprovalViewModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No task loaded to approve."])
            return
        }

        isLoading = true
        error = nil
        operationSuccessful = false
        do {
            try await firebaseService.approveTask(taskToApprove)
            print("Task \(taskToApprove.title) approved.")
            operationSuccessful = true
            // The task status will be updated in Firestore, which might be reflected via a listener
            // or require a manual refresh in the ParentDashboardViewModel.
        } catch {
            self.error = error
            print("Error approving task: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Declines the current task.
    @MainActor // Ensure UI updates happen on the main thread
    func declineTask() async {
        guard let taskToDecline = task else {
            self.error = NSError(domain: "TaskApprovalViewModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "No task loaded to decline."])
            return
        }

        isLoading = true
        error = nil
        operationSuccessful = false
        do {
            try await firebaseService.declineTask(taskToDecline)
            print("Task \(taskToDecline.title) declined.")
            operationSuccessful = true
            // The task status will be updated in Firestore, which might be reflected via a listener
            // or require a manual refresh in the ParentDashboardViewModel.
        } catch {
            self.error = error
            print("Error declining task: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
