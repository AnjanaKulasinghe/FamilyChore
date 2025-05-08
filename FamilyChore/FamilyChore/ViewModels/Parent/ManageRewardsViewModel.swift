import Foundation
import Combine
import FirebaseFirestore // For Firestore types

/// ViewModel for managing the list of rewards within a family.
class ManageRewardsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of rewards associated with the parent's family.
    @Published var rewards: [Reward] = []

    /// Indicates if data is currently being loaded or an operation is in progress.
    @Published var isLoading = false

    /// Stores any error that occurred.
    @Published var error: Error?

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    /// Listener registration for rewards updates (optional, for real-time updates).
    private var rewardsListener: ListenerRegistration?

    // MARK: - Initialization

    init() {
        // Listener can be set up when the view appears if real-time updates are needed
    }

    deinit {
        // Remove listener when the ViewModel is deallocated
        removeListener()
    }

    // MARK: - Data Fetching & Real-time Listener

    /// Fetches all rewards for the specified family.
    /// - Parameter familyId: The ID of the parent's family.
    @MainActor // Ensure UI updates happen on the main thread
    func fetchRewards(forFamily familyId: String) async {
        isLoading = true
        error = nil
        do {
            self.rewards = try await firebaseService.fetchRewards(forFamily: familyId)
            print("Fetched \(self.rewards.count) rewards for family \(familyId)")
        } catch {
            self.error = error
            print("Error fetching rewards: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Sets up a real-time listener for rewards in the specified family (Optional).
    /// - Parameter familyId: The ID of the parent's family.
    func setupListener(forFamily familyId: String) {
        removeListener() // Remove existing listener first

        rewardsListener = firebaseService.db.collection("rewards")
            .whereField("familyId", isEqualTo: familyId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for rewards updates: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let snapshot = querySnapshot else { return }

                self.rewards = snapshot.documents.compactMap { document in
                    try? document.data(as: Reward.self)
                }
                print("Real-time update: Fetched \(self.rewards.count) rewards for family \(familyId)")
            }
    }

    /// Removes the active Firestore listener.
    func removeListener() {
        rewardsListener?.remove()
        rewardsListener = nil
        print("Rewards listener removed.")
    }


    // MARK: - Actions

    /// Deletes a reward from Firestore.
    /// - Parameter reward: The Reward object to delete.
    @MainActor // Ensure UI updates happen on the main thread
    func deleteReward(_ reward: Reward) async {
        guard let rewardId = reward.id else {
            self.error = NSError(domain: "ManageRewardsViewModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Reward ID missing for deletion."])
            return
        }

        isLoading = true
        error = nil
        do {
            try await firebaseService.deleteReward(rewardId: rewardId)
            print("Reward deleted successfully: \(rewardId)")
            // Optionally remove from local array immediately for faster UI update,
            // or rely on the listener (if used) to update the array.
            // rewards.removeAll { $0.id == rewardId }
        } catch {
            self.error = error
            print("Error deleting reward \(rewardId): \(error.localizedDescription)")
        }
        isLoading = false
    }
}