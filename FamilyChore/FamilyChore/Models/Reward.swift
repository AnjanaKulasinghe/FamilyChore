import Foundation
import FirebaseFirestore // For @DocumentID and potential Timestamp usage

/// Represents a reward that children can work towards.
struct Reward: Codable, Identifiable {
    /// The unique identifier for the reward document in Firestore.
    @DocumentID var id: String?

    /// The title of the reward (e.g., "Trip to the Zoo").
    var title: String

    /// Optional URL string for an image representing the reward.
    var imageUrl: String?

    /// The total number of points required to claim this reward.
    var requiredPoints: Int

    /// An array of UserProfile IDs for the children this reward is assigned to.
    var assignedChildIds: [String]

    /// The UserProfile ID of the parent who created this reward.
    var createdByParentId: String

    /// The ID of the family this reward belongs to.
    var familyId: String // Added familyId

    /// Timestamp when the reward was created. Optional.
    var createdAt: Timestamp? = Timestamp(date: Date())

    // Potential future additions: claimed status, claimed date, etc.

    /// Explicit memberwise initializer for Reward.
    init(id: String? = nil, title: String, imageUrl: String? = nil, requiredPoints: Int, assignedChildIds: [String], createdByParentId: String, familyId: String, createdAt: Timestamp? = Timestamp(date: Date())) { // Added familyId
        self.id = id
        self.title = title
        self.imageUrl = imageUrl
        self.requiredPoints = requiredPoints
        self.assignedChildIds = assignedChildIds
        self.createdByParentId = createdByParentId
        self.familyId = familyId // Added familyId
        self.createdAt = createdAt
    }
}