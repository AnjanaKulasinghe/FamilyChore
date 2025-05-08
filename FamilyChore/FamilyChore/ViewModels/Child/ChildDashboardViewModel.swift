import Foundation
import Combine
import FirebaseFirestore // For Firestore types
// Assuming FirebaseService and Models are accessible

/// ViewModel for the Child Dashboard, managing data like assigned tasks and reward progress.
class ChildDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of tasks assigned to the current child.
    @Published var assignedTasks: [ChildTask] = []

    /// Array of ALL rewards assigned to the current child.
    @Published var assignedRewards: [Reward] = [] // Added back

    /// Array of reward claims made by the current child.
    @Published var rewardClaims: [RewardClaim] = []

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
    private var assignedRewardsListener: ListenerRegistration? // Added back

    /// Listener registration for reward claims updates.
    private var rewardClaimsListener: ListenerRegistration?

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

       // Listener for reward claims updates for this child
       rewardClaimsListener = firebaseService.db.collection("rewardClaims")
           .whereField("childId", isEqualTo: childId)
           // Optionally order by status or date
           // .order(by: "claimedAt", descending: true)
           .addSnapshotListener { [weak self] querySnapshot, error in
               guard let self = self else { return }
               if let error = error {
                   print("Error listening for reward claims updates: \(error.localizedDescription)")
                   // Don't necessarily overwrite task/profile errors
                   if self.error == nil { self.error = error }
                   return
               }
               guard let snapshot = querySnapshot else { return }

               self.rewardClaims = snapshot.documents.compactMap { document in
                   try? document.data(as: RewardClaim.self)
               }
               print("Real-time update: Fetched \(self.rewardClaims.count) reward claims for child \(childId)")
           }

       // Listener for assigned rewards updates (needed for unclaimed list)
       assignedRewardsListener = firebaseService.db.collection("rewards")
           .whereField("assignedChildIds", arrayContains: childId)
           .addSnapshotListener { [weak self] querySnapshot, error in
               guard let self = self else { return }
               if let error = error {
                   print("Error listening for assigned rewards updates: \(error.localizedDescription)")
                   if self.error == nil { self.error = error }
                   return
               }
               guard let snapshot = querySnapshot else { return }
               self.assignedRewards = snapshot.documents.compactMap { try? $0.data(as: Reward.self) }
               print("Real-time update: Fetched \(self.assignedRewards.count) assigned rewards for child \(childId)")
           }
  }

    /// Removes all active Firestore listeners.
    public func removeListeners() {
        childProfileListener?.remove()
        childProfileListener = nil
        assignedTasksListener?.remove()
        assignedTasksListener = nil
        assignedRewardsListener?.remove() // Remove rewards listener
        assignedRewardsListener = nil
        rewardClaimsListener?.remove() // Remove claims listener
        rewardClaimsListener = nil
        print("Firestore listeners removed.")
    }

    // MARK: - Computed Properties for UI

    /// Filters assigned rewards to show only those not yet claimed.
    var unclaimedRewards: [Reward] {
        let claimedRewardIds = Set(rewardClaims.map { $0.rewardId })
        return assignedRewards.filter { reward in
            guard let rewardId = reward.id else { return false }
            return !claimedRewardIds.contains(rewardId)
        }
    }

    // MARK: - Actions

    // TODO: Implement actions related to child dashboard, e.g., marking task as done (leads to submission view)
    // func markTaskAsDone(...) // This will likely trigger navigation to TaskSubmissionView

    // MARK: - Reward Progress Calculation
    // Overload for Reward (used for unclaimed)
    func progress(for reward: Reward) -> Double {
         guard let currentPoints = childProfile?.points, currentPoints > 0, reward.requiredPoints > 0 else {
             return 0.0
         }
         return min(Double(currentPoints) / Double(reward.requiredPoints), 1.0)
     }

    // Overload for RewardClaim (used for claimed)
    func progress(for claim: RewardClaim) -> Double {
        // Progress for a claimed reward is conceptually 100% or based on status?
        // Let's assume we still might show progress based on original cost vs points *at time of claim*
        // Or maybe just return 1.0 if claimed? For now, use cost from claim.
        guard let currentPoints = childProfile?.points, currentPoints >= 0, claim.rewardCost > 0 else {
             // If points are 0 or negative after claim, show 0 progress? Or 1.0 because it's claimed?
             // Let's show 1.0 for claimed items.
             return 1.0 // Treat claimed items as 100% complete in terms of progress bar
         }
         // This calculation doesn't make sense if points were deducted. Return 1.0.
         // return min(Double(currentPoints) / Double(claim.rewardCost), 1.0)
         return 1.0
    }

    /// Attempts to claim a specific reward for the current child.
    /// - Parameter reward: The Reward object to claim.
    @MainActor
    func claimReward(_ reward: Reward) async {
        guard let currentChildProfile = childProfile, let familyId = currentChildProfile.familyId else {
            error = NSError(domain: "ChildDashboardVM", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Child profile or family ID not available."])
            return
        }

        // Double-check points just before claiming
        guard currentChildProfile.points >= reward.requiredPoints else {
             error = NSError(domain: "ChildDashboardVM", code: 1002, userInfo: [NSLocalizedDescriptionKey: "You do not have enough points to claim this reward."])
             return
         }

        isLoading = true
        error = nil // Clear previous errors

        do {
            try await firebaseService.claimReward(reward: reward, child: currentChildProfile, familyId: familyId)
            // Success! Points are deducted and claim created in Firestore.
            // The profile listener should update the points automatically.
            // We might want a temporary success message or UI feedback here.
            print("Successfully initiated claim for reward: \(reward.title)")

        } catch {
            print("Error claiming reward: \(error.localizedDescription)")
            self.error = error // Display the error from the service
        }

        isLoading = false
    }

    /// Sends a reminder for a claimed reward.
    /// - Parameter claim: The RewardClaim to send a reminder for.
    @MainActor
    func sendReminder(for claim: RewardClaim) async {
        guard let claimId = claim.id else {
            error = NSError(domain: "ChildDashboardVM", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Claim ID missing, cannot send reminder."])
            return
        }

        // Optional: Add logic here to prevent spamming reminders (e.g., check lastRemindedAt)
        // let timeSinceLastReminder = Date().timeIntervalSince(claim.lastRemindedAt?.dateValue() ?? .distantPast)
        // guard timeSinceLastReminder > (60 * 60 * 24) else { // e.g., allow only once per day
        //     error = NSError(domain: "ChildDashboardVM", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Reminder already sent recently."])
        //     return
        // }

        isLoading = true // Indicate activity
        error = nil

        do {
            try await firebaseService.updateRewardClaimReminder(claimId: claimId)
            // Optionally update local state immediately or rely on listener
            // if let index = pendingRewardClaims.firstIndex(where: { $0.id == claimId }) {
            //     pendingRewardClaims[index].status = .reminded
            //     pendingRewardClaims[index].lastRemindedAt = Timestamp(date: Date())
            // }
            print("Successfully sent reminder for claim: \(claimId)")
            // Maybe set a temporary success message?
        } catch {
            print("Error sending reminder for claim \(claimId): \(error.localizedDescription)")
            self.error = error
        }

        isLoading = false
    }
}
