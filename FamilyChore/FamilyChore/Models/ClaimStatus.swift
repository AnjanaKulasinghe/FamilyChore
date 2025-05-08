import Foundation

/// Represents the status of a claimed reward.
enum ClaimStatus: String, Codable, CaseIterable {
    case pending = "Pending Approval" // Child claimed, waiting for parent acknowledgement/promise
    case reminded = "Reminder Sent"   // Child sent a reminder
    case promised = "Promised"        // Parent acknowledged and set a promised date
    case granted = "Granted"          // Parent fulfilled the reward
    // case cancelled = "Cancelled"   // Optional: If claims can be cancelled

    // Display name for UI if needed
    var displayName: String {
        return self.rawValue
    }
} // Missing closing brace added