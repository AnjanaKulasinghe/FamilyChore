import Foundation
import Combine
import FirebaseFirestore // For Firestore types

/// ViewModel for managing the list of tasks within a family.
class ManageTasksViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of tasks associated with the parent's family.
    @Published var tasks: [ChildTask] = []

    /// Indicates if data is currently being loaded or an operation is in progress.
    @Published var isLoading = false

    /// Stores any error that occurred.
    @Published var error: Error?

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    /// Listener registration for tasks updates (optional, for real-time updates).
    private var tasksListener: ListenerRegistration?

    // MARK: - Initialization

    init() {
        // Listener can be set up when the view appears if real-time updates are needed
    }

    deinit {
        // Remove listener when the ViewModel is deallocated
        removeListener()
    }

    // MARK: - Data Fetching & Real-time Listener

    /// Fetches all tasks for the specified family.
    /// - Parameter familyId: The ID of the parent's family.
    @MainActor // Ensure UI updates happen on the main thread
    func fetchTasks(forFamily familyId: String) async {
        isLoading = true
        error = nil
        do {
            self.tasks = try await firebaseService.fetchTasks(forFamily: familyId)
            print("Fetched \(self.tasks.count) tasks for family \(familyId)")
        } catch {
            self.error = error
            print("Error fetching tasks: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Sets up a real-time listener for tasks in the specified family (Optional).
    /// - Parameter familyId: The ID of the parent's family.
    func setupListener(forFamily familyId: String) {
        removeListener() // Remove existing listener first

        // ASSUMPTION: Tasks have a 'familyId' field for this query.
        // If not, the query needs adjustment (e.g., query by createdByParentId or fetch all and filter).
        tasksListener = firebaseService.db.collection("tasks")
            .whereField("familyId", isEqualTo: familyId) // ASSUMING tasks have familyId
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for tasks updates: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let snapshot = querySnapshot else { return }

                self.tasks = snapshot.documents.compactMap { document in
                    try? document.data(as: ChildTask.self)
                }
                print("Real-time update: Fetched \(self.tasks.count) tasks for family \(familyId)")
            }
    }

    /// Removes the active Firestore listener.
    func removeListener() {
        tasksListener?.remove()
        tasksListener = nil
        print("Tasks listener removed.")
    }


    // MARK: - Actions

    /// Deletes a task from Firestore.
    /// - Parameter task: The Task object to delete.
    @MainActor // Ensure UI updates happen on the main thread
    func deleteTask(_ task: ChildTask) async {
        guard let taskId = task.id else {
            self.error = NSError(domain: "ManageTasksViewModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Task ID missing for deletion."])
            return
        }

        isLoading = true
        error = nil
        do {
            try await firebaseService.deleteTask(taskId: taskId)
            print("Task deleted successfully: \(taskId)")
            // Optionally remove from local array immediately for faster UI update,
            // or rely on the listener (if used) to update the array.
            // tasks.removeAll { $0.id == taskId }
        } catch {
            self.error = error
            print("Error deleting task \(taskId): \(error.localizedDescription)")
        }
        isLoading = false
    }
}