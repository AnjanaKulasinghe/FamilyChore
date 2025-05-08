import Foundation
import Combine
import FirebaseFirestore // For Firestore types
// Assuming FirebaseService and Models are accessible

/// ViewModel for the Child Dashboard, managing data like assigned tasks and reward progress.
class ChildDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of tasks assigned to the current child.
    @Published var assignedTasks: [ChildTask] = []

    /// Array of rewards assigned to the current child.
    @Published var assignedRewards: [Reward] = []

    /// The current child's profile, including points.
    @Published var childProfile: UserProfile?

    /// Indicates if data is currently being loaded.
    @Published var isLoading = false

    /// Stores any error that occurred during data fetching.
    @Published var error: Error?

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    /// Listener registration for assigned tasks updates.
    private var assignedTasksListener: ListenerRegistration?

    /// Listener registration for assigned rewards updates.
    private var assignedRewardsListener: ListenerRegistration?

    /// Listener registration for child profile updates.
    private var childProfileListener: ListenerRegistration?


    // MARK: - Initialization

    init() {
        // Listeners will be set up when the view appears
    }

    deinit {
        // Remove listeners when the ViewModel is deallocated
        removeListeners()
    }

    // MARK: - Data Fetching & Real-time Listeners

    /// Sets up real-time listeners for the child's data.
    /// - Parameter childId: The ID of the current child user.
    func setupListeners(forChild childId: String) {
        // Remove existing listeners first
        removeListeners()

        // Listener for child profile updates
        childProfileListener = firebaseService.db.collection("users").document(childId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for child profile updates: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let document = documentSnapshot, document.exists else {
                    print("Error: Child profile document does not exist for ID: \(childId)")
                    // Handle case where profile is deleted
                    self.childProfile = nil
                    return
                }

                self.childProfile = try? document.data(as: UserProfile.self)
                print("Real-time update: Fetched child profile for ID: \(childId)")
            }


        // Listener for assigned tasks updates
        assignedTasksListener = firebaseService.db.collection("tasks")
            .whereField("assignedChildIds", arrayContains: childId)
            .whereField("status", isNotEqualTo: TaskStatus.approved.rawValue) // Exclude approved tasks
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for assigned tasks updates: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let snapshot = querySnapshot else { return }

                self.assignedTasks = snapshot.documents.compactMap { document in
                    try? document.data(as: ChildTask.self)
                }
                print("Real-time update: Fetched \(self.assignedTasks.count) assigned tasks for child \(childId)")
            }

        // Listener for assigned rewards updates
        assignedRewardsListener = firebaseService.db.collection("rewards")
            .whereField("assignedChildIds", arrayContains: childId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for assigned rewards updates: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let snapshot = querySnapshot else { return }

                self.assignedRewards = snapshot.documents.compactMap { document in
                    try? document.data(as: Reward.self)
                }
                print("Real-time update: Fetched \(self.assignedRewards.count) assigned rewards for child \(childId)")
            }
    }

    /// Removes all active Firestore listeners.
    public func removeListeners() {
        childProfileListener?.remove()
        childProfileListener = nil
        assignedTasksListener?.remove()
        assignedTasksListener = nil
        assignedRewardsListener?.remove()
        assignedRewardsListener = nil
        print("Firestore listeners removed.")
    }

    // MARK: - Actions

    // TODO: Implement actions related to child dashboard, e.g., marking task as done (leads to submission view)
    // func markTaskAsDone(...) // This will likely trigger navigation to TaskSubmissionView
}
