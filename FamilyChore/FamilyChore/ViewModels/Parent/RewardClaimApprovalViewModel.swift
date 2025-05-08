import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for handling the parent's actions on a specific reward claim.
@MainActor
class RewardClaimApprovalViewModel: ObservableObject {

    @Published var rewardClaim: RewardClaim
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var operationSuccessful = false // General success flag for alerts

    // State for setting promise date
    @Published var promiseDate: Date = Date() // Default to today
    @Published var showingDatePicker = false // To toggle date picker visibility

    private let firebaseService = FirebaseService.shared

    init(rewardClaim: RewardClaim) {
        self.rewardClaim = rewardClaim
        // Set initial promise date reasonably in the future if not already set
        if rewardClaim.promisedDate == nil {
            self.promiseDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        } else {
            self.promiseDate = rewardClaim.promisedDate!.dateValue()
        }
    }

    // MARK: - Actions

    /// Updates the claim status to Promised and sets the promised date.
    func promiseReward() async {
        guard let claimId = rewardClaim.id else {
            errorMessage = "Claim ID is missing."
            return
        }
        isLoading = true
        errorMessage = nil
        operationSuccessful = false

        let updates: [String: Any] = [
            "status": ClaimStatus.promised.rawValue,
            "promisedDate": Timestamp(date: promiseDate)
        ]

        do {
            try await firebaseService.updateRewardClaim(claimId: claimId, updates: updates)
            // Update local state to match
            rewardClaim.status = .promised
            rewardClaim.promisedDate = Timestamp(date: promiseDate)
            operationSuccessful = true
            print("Reward claim \(claimId) status updated to Promised with date \(promiseDate)")
        } catch {
            print("Error promising reward claim \(claimId): \(error.localizedDescription)")
            errorMessage = "Failed to promise reward: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// Updates the claim status to Granted.
    func grantReward() async {
         guard let claimId = rewardClaim.id else {
            errorMessage = "Claim ID is missing."
            return
        }
        isLoading = true
        errorMessage = nil
        operationSuccessful = false

        let updates: [String: Any] = [
            "status": ClaimStatus.granted.rawValue,
            "grantedAt": Timestamp(date: Date())
            // Keep promisedDate if you want to track it
        ]

        do {
            try await firebaseService.updateRewardClaim(claimId: claimId, updates: updates)
             // Update local state to match
            rewardClaim.status = .granted
            rewardClaim.grantedAt = Timestamp(date: Date())
            operationSuccessful = true
            print("Reward claim \(claimId) status updated to Granted.")
        } catch {
            print("Error granting reward claim \(claimId): \(error.localizedDescription)")
            errorMessage = "Failed to grant reward: \(error.localizedDescription)"
        }
        isLoading = false
    }
}