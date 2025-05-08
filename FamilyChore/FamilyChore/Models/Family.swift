import Foundation
import FirebaseFirestore

/// Represents a family unit within the app, linking parents and children.
struct Family: Codable, Identifiable {
    /// The unique identifier for the family document in Firestore.
    @DocumentID var id: String?

    /// An array of user IDs (UserProfile IDs) for the parents in this family.
    var parentIds: [String]

    /// An array of user IDs (UserProfile IDs) for the children in this family.
    var childIds: [String]

    // Potential future additions: Family name, shared settings, etc.
}
