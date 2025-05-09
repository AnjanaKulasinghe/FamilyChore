import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for the Child Detail view, fetching tasks, rewards, and profile info for a specific child.
@MainActor
class ChildDetailViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var childProfile: UserProfile?
    @Published var assignedTasks: [ChildTask] = []
    @Published var assignedRewards: [Reward] = [] // All assigned
    @Published var rewardClaims: [RewardClaim] = [] // All claims by this child
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Filtered lists for UI
    var pendingTasks: [ChildTask] { assignedTasks.filter { $0.status == .pending || $0.status == .submitted } }
    var completedTasks: [ChildTask] { assignedTasks.filter { $0.status == .approved || $0.status == .declined } }

    // Unclaimed rewards (assigned but no corresponding claim)
    var unclaimedRewards: [Reward] {
        let claimedRewardIds = Set(rewardClaims.map { $0.rewardId })
        return assignedRewards.filter { reward in
            guard let rewardId = reward.id else { return false }
            return !claimedRewardIds.contains(rewardId)
        }
    }
    // Claimed rewards (can be further filtered by status: pending, promised, granted)
    var pendingClaims: [RewardClaim] { rewardClaims.filter { $0.status == .pending || $0.status == .reminded } }
    var promisedClaims: [RewardClaim] { rewardClaims.filter { $0.status == .promised } }
    var grantedClaims: [RewardClaim] { rewardClaims.filter { $0.status == .granted } }

    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    private let childId: String

    // MARK: - Initialization
    init(childId: String) {
        self.childId = childId
        print("ChildDetailViewModel initialized for child ID: \(childId)")
    }

    // MARK: - Data Fetching
    func fetchData() async {
        guard !childId.isEmpty else {
            errorMessage = "Child ID is missing."
            return
        }

        isLoading = true
        errorMessage = nil
        print("ChildDetailViewModel: Starting data fetch for \(childId)")

        // Use TaskGroup for concurrent fetching
        await withTaskGroup(of: Void.self) { group in
            // Fetch Profile
            group.addTask { await self.fetchChildProfile() }
            // Fetch Tasks
            group.addTask { await self.fetchAssignedTasks() }
            // Fetch Assigned Rewards
            group.addTask { await self.fetchAssignedRewards() }
            // Fetch Reward Claims
            group.addTask { await self.fetchRewardClaims() }
        }

        isLoading = false
        print("ChildDetailViewModel: Data fetch completed for \(childId)")
    }

    private func fetchChildProfile() async {
        do {
            self.childProfile = try await firebaseService.fetchUserProfile(userId: childId)
            print("Fetched profile for \(childId): \(self.childProfile?.name ?? "N/A")")
        } catch {
            print("Error fetching child profile (\(childId)): \(error.localizedDescription)")
            if self.errorMessage == nil { self.errorMessage = "Failed to load child profile." }
        }
    }

    private func fetchAssignedTasks() async {
        do {
            self.assignedTasks = try await firebaseService.fetchTasks(forChild: childId)
            print("Fetched \(self.assignedTasks.count) tasks for child \(childId)")
        } catch {
            print("Error fetching tasks for child (\(childId)): \(error.localizedDescription)")
             if self.errorMessage == nil { self.errorMessage = "Failed to load tasks." }
        }
    }

    private func fetchAssignedRewards() async {
        do {
            self.assignedRewards = try await firebaseService.fetchRewards(forChild: childId)
             print("Fetched \(self.assignedRewards.count) rewards for child \(childId)")
        } catch {
            print("Error fetching assigned rewards for child (\(childId)): \(error.localizedDescription)")
             if self.errorMessage == nil { self.errorMessage = "Failed to load assigned rewards." }
        }
    }

    private func fetchRewardClaims() async {
        do {
            // Fetch all claims for this child
            self.rewardClaims = try await firebaseService.fetchRewardClaims(forChild: childId)
             print("Fetched \(self.rewardClaims.count) reward claims for child \(childId)")
        } catch {
            print("Error fetching reward claims for child (\(childId)): \(error.localizedDescription)")
             if self.errorMessage == nil { self.errorMessage = "Failed to load reward claims." }
        }
    }

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
          // Treat claimed items as 100% complete in terms of progress bar
          return 1.0
     }

    // MARK: - Deletion
    /// Deletes a specific reward claim.
    /// - Parameter claim: The RewardClaim object to delete.
    @MainActor
    func deleteClaim(_ claim: RewardClaim) async {
        guard let claimId = claim.id else {
            errorMessage = "Cannot delete claim: Claim ID is missing."
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            try await firebaseService.deleteRewardClaim(claimId: claimId)
            // Remove from local arrays to update UI immediately
            rewardClaims.removeAll { $0.id == claimId }
            // No need to manually update pendingClaims, promisedClaims, grantedClaims
            // as they are computed properties based on rewardClaims.
            print("Successfully deleted reward claim: \(claimId)")
        } catch {
            print("Error deleting reward claim \(claimId): \(error.localizedDescription)")
            errorMessage = "Failed to delete claim: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// Deletes a specific task.
    /// - Parameter task: The ChildTask object to delete.
    @MainActor
    func deleteTask(_ task: ChildTask) async {
        guard let taskId = task.id else {
            errorMessage = "Cannot delete task: Task ID is missing."
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            try await firebaseService.deleteTask(taskId: taskId)
            // Remove from local arrays to update UI immediately
            assignedTasks.removeAll { $0.id == taskId }
            // pendingTasks and completedTasks are computed properties and will update.
            print("Successfully deleted task: \(taskId)")
        } catch {
            print("Error deleting task \(taskId): \(error.localizedDescription)")
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
