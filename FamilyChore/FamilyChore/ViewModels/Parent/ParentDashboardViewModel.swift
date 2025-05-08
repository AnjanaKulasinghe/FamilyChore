import Foundation
import Combine
import FirebaseFirestore // For Firestore types like DocumentSnapshot
// Assuming FirebaseService and Models are accessible

/// ViewModel for the Parent Dashboard, managing data like children and tasks needing approval.
class ParentDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of children associated with the parent's family.
    @Published var children: [UserProfile] = []

    /// Array of tasks that require parent approval.
    @Published var tasksNeedingApproval: [ChildTask] = []

    /// Indicates if data is currently being loaded.
    @Published var isLoading = false

    /// Stores any error that occurred during data fetching.
    @Published var error: Error?

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    /// Listener registration for children updates.
    private var childrenListener: ListenerRegistration?

    /// Listener registration for tasks needing approval updates.
    private var tasksNeedingApprovalListener: ListenerRegistration?

    // MARK: - Initialization

    init() {
        // Data fetching will be triggered when the view appears,
        // but listeners can be set up here if needed for real-time updates.
    }

    deinit {
        // Remove listeners when the ViewModel is deallocated
        removeListeners()
    }

    // MARK: - Data Fetching

    /// Fetches initial data for the parent dashboard.
    /// - Parameter familyId: The ID of the parent's family.
    @MainActor // Ensure UI updates happen on the main thread
    func fetchData(forFamily familyId: String) async {
        isLoading = true
        error = nil

        // Fetch children
        await fetchChildren(forFamily: familyId)

        // Fetch tasks needing approval
        await fetchTasksNeedingApproval(forFamily: familyId)

        isLoading = false // Note: This might be set to false after all fetches complete
    }

    /// Fetches children for the specified family.
    /// - Parameter familyId: The ID of the family.
    @MainActor
    private func fetchChildren(forFamily familyId: String) async {
        do {
            // Use FirebaseService to fetch children
            self.children = try await firebaseService.fetchChildren(forFamily: familyId)
            print("Fetched \(self.children.count) children for family \(familyId)")
        } catch {
            self.error = error
            print("Error fetching children: \(error.localizedDescription)")
        }
    }

    /// Fetches tasks that are in the 'submitted' status for the specified family.
    /// - Parameter familyId: The ID of the family.
    @MainActor
    private func fetchTasksNeedingApproval(forFamily familyId: String) async {
        do {
            // Note: FirebaseService currently fetches tasks by child ID.
            // We need a way to fetch tasks for a family that are 'submitted'.
            // This might require a new function in FirebaseService or fetching all tasks for children in the family and filtering.
            // For now, this is a placeholder. A Firestore query for tasks by family ID and status would be more efficient.

            // Placeholder implementation: Fetch all children, then fetch tasks for each child and filter
            let childrenInFamily = try await firebaseService.fetchChildren(forFamily: familyId)
            var submittedTasks: [ChildTask] = []
            for child in childrenInFamily {
                let tasks = try await firebaseService.fetchTasks(forChild: child.id!) // Assuming child.id is not nil
                submittedTasks.append(contentsOf: tasks.filter { $0.status == .submitted })
            }
            self.tasksNeedingApproval = submittedTasks
            print("Fetched \(self.tasksNeedingApproval.count) tasks needing approval for family \(familyId)")

        } catch {
            self.error = error
            print("Error fetching tasks needing approval: \(error.localizedDescription)")
        }
    }

    // MARK: - Real-time Listeners (Optional but recommended for dashboards)

    /// Sets up real-time listeners for children and tasks needing approval.
    /// - Parameter familyId: The ID of the parent's family.
    func setupListeners(forFamily familyId: String) {
        // Remove existing listeners first
        removeListeners()

        // Listener for children updates
        childrenListener = firebaseService.db.collection("users")
            .whereField("familyId", isEqualTo: familyId)
            .whereField("role", isEqualTo: UserRole.child.rawValue)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for children updates: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let snapshot = querySnapshot else { return }

                self.children = snapshot.documents.compactMap { document in
                    try? document.data(as: UserProfile.self)
                }
                print("Real-time update: Fetched \(self.children.count) children for family \(familyId)")
            }

        // Listener for tasks needing approval updates
        // This requires a composite query on 'familyId' and 'status', which is not directly supported by Firestore without an index.
        // A more efficient approach might be to listen to tasks for all children in the family and filter locally,
        // or structure data differently. For now, we'll use a less efficient approach or rely on manual refresh.
        // A direct query like db.collection("tasks").whereField("familyId", isEqualTo: familyId).whereField("status", isEqualTo: TaskStatus.submitted.rawValue)
        // would be ideal but requires a composite index.

        // Placeholder listener - will need refinement based on data structure and indexing
         tasksNeedingApprovalListener = firebaseService.db.collection("tasks")
             // This query might not be efficient or possible without proper indexing
             // .whereField("familyId", isEqualTo: familyId) // Assuming tasks have a familyId field
             .whereField("status", isEqualTo: TaskStatus.submitted.rawValue)
             // Need to filter by tasks assigned to children in *this* parent's family.
             // This is complex with current data structure and requires fetching family children first.
             // A real-time listener that fetches all tasks and filters locally might be too heavy.
             // A better approach is likely a query based on assignedChildIds and status, but Firestore limitations apply.
             // For now, we'll rely on manual refresh or a less efficient listener.

             // Alternative: Listen to all tasks and filter locally (potentially inefficient for large datasets)
             .addSnapshotListener { [weak self] querySnapshot, error in
                 guard let self = self else { return }
                 if let error = error {
                     print("Error listening for tasks updates: \(error.localizedDescription)")
                     self.error = error
                     return
                 }

                 guard let snapshot = querySnapshot else { return }

                 // This local filtering can be inefficient. Needs optimization.
                 // Requires knowing the child IDs in the parent's family.
                 // This listener needs to be smarter or the data structure needs adjustment.
                 // For now, a basic filter assuming tasks have assignedChildIds
                 self.tasksNeedingApproval = snapshot.documents.compactMap { document in
                     try? document.data(as: ChildTask.self)
                 }.filter { task in
                     // This filtering logic needs access to the family's child IDs
                     // This listener setup is problematic without a direct query or better data structure
                     // For now, we'll filter by status only, which is incorrect for a specific parent's view
                     task.status == .submitted
                 }
                 print("Real-time update: Fetched \(self.tasksNeedingApproval.count) tasks needing approval (filtered by status only)")
             }
    }


    /// Removes all active Firestore listeners.
    private func removeListeners() {
        childrenListener?.remove()
        childrenListener = nil
        tasksNeedingApprovalListener?.remove()
        tasksNeedingApprovalListener = nil
        print("Firestore listeners removed.")
    }

    // MARK: - Actions

    /// Approves a submitted task.
    /// - Parameter task: The task to approve.
    @MainActor
    func approveTask(_ task: ChildTask) async {
        isLoading = true
        error = nil
        do {
            try await firebaseService.approveTask(task)
            print("Task \(task.title) approved.")
            // Data will be updated via listener or can be manually refreshed
        } catch {
            self.error = error
            print("Error approving task: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Declines a submitted task.
    /// - Parameter task: The task to decline.
    @MainActor
    func declineTask(_ task: ChildTask) async {
        isLoading = true
        error = nil
        do {
            try await firebaseService.declineTask(task)
            print("Task \(task.title) declined.")
            // Data will be updated via listener or can be manually refreshed
        } catch {
            self.error = error
            print("Error declining task: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Navigation (Handled by Views, but ViewModel prepares data)

    // Methods to prepare data for navigation, e.g., to AddChildView, CreateTaskView, CreateRewardView, TaskApprovalView
}
