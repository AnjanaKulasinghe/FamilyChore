import Foundation

/// Defines the possible states a task can be in.
enum TaskStatus: String, Codable, CaseIterable {
    /// Task has been created but not yet submitted by the child.
    case pending = "Pending"

    /// Task has been marked as done and submitted by the child for review.
    case submitted = "Submitted"

    /// Task submission has been approved by the parent.
    case approved = "Approved"

    /// Task submission has been declined by the parent.
    case declined = "Declined"

    // Provides a user-friendly display name
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .submitted:
            return "Sent to Approve" // Changed display name
        case .approved:
            return "Approved"
        case .declined:
            return "Declined"
        }
    }
}