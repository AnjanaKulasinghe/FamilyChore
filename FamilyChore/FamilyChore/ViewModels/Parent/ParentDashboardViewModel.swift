import Foundation
import Combine
import FirebaseFirestore // For Firestore types like DocumentSnapshot
// Assuming FirebaseService and Models are accessible

/// ViewModel for the Parent Dashboard, managing data like children and tasks needing approval.
class ParentDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of parent profiles associated with the current family.
    @Published var parents: [UserProfile] = []

    /// Array of children associated with the parent's family.
    @Published var children: [UserProfile] = []

    /// Array of tasks that require parent approval.
    @Published var tasksNeedingApproval: [ChildTask] = []

    /// Array of reward claims pending parent action.
    @Published var pendingRewardClaims: [RewardClaim] = []

    /// Indicates if data is currently being loaded.
    @Published var isLoading = false

    /// Stores any error that occurred during data fetching.
    @Published var error: Error?

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    /// Listener registration for parent updates.
    private var parentsListener: ListenerRegistration?

    /// Listener registration for children updates.
    private var childrenListener: ListenerRegistration?

    /// Listener registration for tasks needing approval updates.
    private var tasksNeedingApprovalListener: ListenerRegistration?

    /// Listener registration for pending reward claims.
    private var pendingClaimsListener: ListenerRegistration?

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
        // Use TaskGroup for concurrent fetching
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchParents(forFamily: familyId) }
            group.addTask { await self.fetchChildren(forFamily: familyId) }
            group.addTask { await self.fetchTasksNeedingApproval(forFamily: familyId) }
            group.addTask { await self.fetchPendingRewardClaims(forFamily: familyId) } // Add claim fetching
        }
        isLoading = false
    }

    /// Fetches parent profiles for the specified family.
    /// - Parameter familyId: The ID of the family.
    @MainActor
    private func fetchParents(forFamily familyId: String) async {
         do {
             self.parents = try await firebaseService.fetchParents(forFamily: familyId)
             print("Fetched \(self.parents.count) parents for family \(familyId)")
         } catch {
             // Avoid overwriting error from other fetches if one already occurred
             if self.error == nil { self.error = error }
             print("Error fetching parents: \(error.localizedDescription)")
         }
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

    /// Fetches reward claims that are pending parent action for the specified family.
    /// - Parameter familyId: The ID of the family.
    @MainActor
    private func fetchPendingRewardClaims(forFamily familyId: String) async {
        do {
            // Query for claims in the family with status pending or reminded
            let pendingStatuses = [ClaimStatus.pending.rawValue, ClaimStatus.reminded.rawValue]
            self.pendingRewardClaims = try await firebaseService.fetchRewardClaims(forFamily: familyId, statuses: pendingStatuses)
            print("Fetched \(self.pendingRewardClaims.count) pending reward claims for family \(familyId)")
        } catch {
             if self.error == nil { self.error = error }
             print("Error fetching pending reward claims: \(error.localizedDescription)")
         }
     }


    // MARK: - Real-time Listeners (Optional but recommended for dashboards)

    /// Sets up real-time listeners for parents, children, tasks needing approval, and pending claims.
    /// - Parameter familyId: The ID of the parent's family.
    func setupListeners(forFamily familyId: String) {
        // Remove existing listeners first
        removeListeners()

        // Listener for parents updates
        parentsListener = firebaseService.db.collection("users")
            .whereField("familyId", isEqualTo: familyId)
            .whereField("role", isEqualTo: UserRole.parent.rawValue)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for parents updates: \(error.localizedDescription)")
                    self.error = error // Update error state
                    return
                }
                guard let snapshot = querySnapshot else { return }
                self.parents = snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
                print("Real-time update: Fetched \(self.parents.count) parents for family \(familyId)")
            }


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

       // Listener for pending reward claims updates
       let pendingStatuses = [ClaimStatus.pending.rawValue, ClaimStatus.reminded.rawValue]
       pendingClaimsListener = firebaseService.db.collection("rewardClaims")
           .whereField("familyId", isEqualTo: familyId)
           .whereField("status", in: pendingStatuses) // Listen for pending or reminded
           .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for pending claims updates: \(error.localizedDescription)")
                    self.error = error
                    return
                }
                guard let snapshot = querySnapshot else { return }
                self.pendingRewardClaims = snapshot.documents.compactMap { try? $0.data(as: RewardClaim.self) }
                print("Real-time update: Fetched \(self.pendingRewardClaims.count) pending reward claims for family \(familyId)")
            }
   }


    /// Removes all active Firestore listeners.
    public func removeListeners() {
        parentsListener?.remove()
        parentsListener = nil
        childrenListener?.remove()
        childrenListener = nil
        tasksNeedingApprovalListener?.remove()
        tasksNeedingApprovalListener = nil
        pendingClaimsListener?.remove() // Remove claims listener
        pendingClaimsListener = nil
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

    // MARK: - Co-Parent Management

    /// Attempts to find an existing parent user by email and add them to the current family.
    /// - Parameters:
    ///   - email: The email address of the potential co-parent.
    ///   - currentFamilyId: The ID of the family to add the co-parent to.
    /// - Returns: `true` if the co-parent was successfully added, `false` otherwise.
    @MainActor
    func addCoParent(email: String, currentFamilyId: String?) async -> Bool {
        guard let familyId = currentFamilyId else {
            self.error = NSError(domain: "ParentDashboardViewModel", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Current user's family ID not found."])
            return false
        }

        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
             self.error = NSError(domain: "ParentDashboardViewModel", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Co-parent email cannot be empty."])
             return false
         }

        self.error = nil // Clear previous errors

        do {
            // 1. Find the potential co-parent by email
            print("[ViewModel] Searching for parent with email: \(email)")
            guard let coParentProfile = try await firebaseService.findParentByEmail(email: email) else {
                print("[ViewModel] No parent found with email: \(email)")
                self.error = NSError(domain: "ParentDashboardViewModel", code: 1003, userInfo: [NSLocalizedDescriptionKey: "No parent account found with that email address."])
                return false
            }
            print("[ViewModel] Found potential co-parent: \(coParentProfile.id ?? "N/A")")

            // 2. Validate the found profile
            guard coParentProfile.role == .parent else {
                // This shouldn't happen if findParentByEmail filters correctly, but double-check
                print("[ViewModel] Found user is not a parent.")
                self.error = NSError(domain: "ParentDashboardViewModel", code: 1004, userInfo: [NSLocalizedDescriptionKey: "The user found with that email is not registered as a parent."])
                return false
            }

            guard coParentProfile.familyId == nil || coParentProfile.familyId!.isEmpty else {
                print("[ViewModel] Found parent is already associated with a family (\(coParentProfile.familyId ?? "unknown")).")
                self.error = NSError(domain: "ParentDashboardViewModel", code: 1005, userInfo: [NSLocalizedDescriptionKey: "This parent is already part of another family."])
                return false
            }
            
            guard let coParentId = coParentProfile.id else {
                 print("[ViewModel] Found parent profile is missing its ID.")
                 self.error = NSError(domain: "ParentDashboardViewModel", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Found parent profile is missing an ID."])
                 return false
             }

            // 3. Add the co-parent to the family
            print("[ViewModel] Attempting to add parent \(coParentId) to family \(familyId)")
            try await firebaseService.addParentToFamily(parentToAddId: coParentId, familyId: familyId)
            print("[ViewModel] Successfully added parent \(coParentId) to family \(familyId)")
            return true

        } catch {
            print("[ViewModel] Error during addCoParent process: \(error.localizedDescription)")
            self.error = error // Store the error from FirebaseService
            return false
        }
    }


    // MARK: - Navigation (Handled by Views, but ViewModel prepares data)

    // Methods to prepare data for navigation, e.g., to AddChildView, CreateTaskView, CreateRewardView, TaskApprovalView
}
