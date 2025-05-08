import Foundation
import Combine

/// ViewModel for the Add Co-Parent view.
@MainActor // Ensure UI updates happen on the main thread
class AddCoParentViewModel: ObservableObject {

    @Published var email: String = "" // Only need email input
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let firebaseService = FirebaseService.shared

    /// Attempts to find an existing parent by email and add them to the specified family.
    /// - Parameter familyId: The ID of the family to add the co-parent to.
    /// - Returns: `true` on success, `false` on failure.
    func linkCoParentAccount(familyId: String?) async -> Bool {
        guard let familyId = familyId else {
            errorMessage = "Current user's family ID not found."
            return false
        }
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Co-parent email cannot be empty."
            return false
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            // 1. Find the potential co-parent by email
            guard let coParentProfile = try await firebaseService.findParentByEmail(email: email) else {
                // This means not found or not a parent
                errorMessage = "No parent account found with that email address."
                isLoading = false
                return false
            }

            // 2. Validate ID
            guard let coParentId = coParentProfile.id else {
                errorMessage = "Found parent profile is missing an ID." // Should be rare
                isLoading = false
                return false
            }
            
            // Note: We are intentionally NOT checking coParentProfile.familyId here anymore
            // to allow linking a parent who might already be in another family.

            // 3. Add the co-parent to the family
            try await firebaseService.addParentToFamily(parentToAddId: coParentId, familyId: familyId)

            successMessage = "Co-parent '\(coParentProfile.name ?? coParentProfile.email)' linked successfully!"
            isLoading = false
            return true

        } catch {
            // Handle potential errors from findParentByEmail or addParentToFamily
            print("Error linking co-parent account: \(error.localizedDescription)")
            errorMessage = "An error occurred: \(error.localizedDescription)" // Generic error
            isLoading = false
            return false
        }
    }
}