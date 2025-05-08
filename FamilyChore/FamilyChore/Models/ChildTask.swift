import Foundation
import FirebaseFirestore // For @DocumentID and potential Timestamp usage

/// Represents a task assigned within the family.
struct ChildTask: Codable, Identifiable {
    /// The unique identifier for the task document in Firestore.
    @DocumentID var id: String?

    /// The title of the task (e.g., "Clean your room").
    var title: String

    /// Optional longer description of the task.
    var description: String

    /// The number of points awarded upon successful completion.
    var points: Int

    /// Optional URL string for an image illustrating the task.
    var imageUrl: String?

    /// Indicates if the task repeats (e.g., weekly). Logic for recurrence needs implementation elsewhere.
    var isRecurring: Bool

    /// An array of UserProfile IDs for the children assigned to this task.
    var assignedChildIds: [String]

    /// Optional array of Reward IDs that this task contributes towards.
    var linkedRewardIds: [String]

    /// The UserProfile ID of the parent who created this task.
    var createdByParentId: String

    /// The ID of the family this task belongs to.
    var familyId: String // Added familyId

    /// The current status of the task (pending, submitted, approved, declined).
    var status: TaskStatus = .pending

    /// Optional URL string for the photo proof submitted by the child.
    var proofImageUrl: String?

    /// Timestamp when the task was created. Optional, but useful for sorting.
    var createdAt: Timestamp? = Timestamp(date: Date())

    /// Timestamp when the task was last updated (e.g., submitted, approved). Optional.
    var updatedAt: Timestamp? = Timestamp(date: Date())

/// Explicit memberwise initializer for Task.
    init(id: String? = nil, title: String, description: String, points: Int, imageUrl: String? = nil, isRecurring: Bool, assignedChildIds: [String], linkedRewardIds: [String], createdByParentId: String, familyId: String, status: TaskStatus = .pending, proofImageUrl: String? = nil, createdAt: Timestamp? = Timestamp(date: Date()), updatedAt: Timestamp? = Timestamp(date: Date())) { // Added familyId
        self.id = id
        self.title = title
        self.description = description
        self.points = points
        self.imageUrl = imageUrl
        self.isRecurring = isRecurring
        self.assignedChildIds = assignedChildIds
        self.linkedRewardIds = linkedRewardIds
        self.createdByParentId = createdByParentId
        self.familyId = familyId // Added familyId
        self.status = status
        self.proofImageUrl = proofImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    // Note: For recurring tasks, additional logic will be needed to handle resets/re-assignments.
    // This might involve creating new instances of the task or updating its status/timestamps.
}
