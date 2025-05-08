import Foundation
import FirebaseFirestore

/// Represents an instance of a child claiming a specific reward.
struct RewardClaim: Codable, Identifiable {
    @DocumentID var id: String?

    let rewardId: String          // ID of the Reward being claimed
    let rewardTitle: String       // Denormalized title for easier display
    let rewardCost: Int           // Denormalized cost at time of claim

    let childId: String           // ID of the child claiming the reward
    let childName: String?        // Denormalized name for easier display

    let familyId: String          // ID of the family

    var status: ClaimStatus = .pending // Current status of the claim
    let claimedAt: Timestamp      // When the child initiated the claim

    var lastRemindedAt: Timestamp? // When the child last sent a reminder
    var promisedDate: Timestamp?   // Date the parent promised to fulfill by
    var grantedAt: Timestamp?      // When the parent marked it as granted

    // Initializer
    init(id: String? = nil, reward: Reward, child: UserProfile, familyId: String) {
        self.id = id
        guard let rewardId = reward.id else {
            fatalError("Reward ID missing during claim creation") // Or handle more gracefully
        }
        self.rewardId = rewardId
        self.rewardTitle = reward.title
        self.rewardCost = reward.requiredPoints // Use requiredPoints field name

        guard let childId = child.id else {
            fatalError("Child ID missing during claim creation") // Or handle more gracefully
        }
        self.childId = childId
        self.childName = child.name // Store name at time of claim

        self.familyId = familyId
        self.claimedAt = Timestamp(date: Date())
        self.status = .pending
    } // Missing closing brace for init

    // Add a memberwise initializer for Codable conformance if needed,
    // although the default should work if all stored properties are Codable.
    // Need to ensure Reward and UserProfile are available or handle missing IDs gracefully.
} // Missing closing brace for struct