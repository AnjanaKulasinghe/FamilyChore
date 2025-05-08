import Foundation
import Combine
import FirebaseFirestore // For Firestore types
import SwiftUI // Added for UIImage
// Assuming FirebaseService and Models are accessible

/// ViewModel for managing children within a parent's family.
class ManageChildrenViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Array of children associated with the parent's family.
    @Published var children: [UserProfile] = []

    /// Indicates if data is currently being loaded or an operation is in progress.
    @Published var isLoading = false

    /// Stores any error that occurred.
    @Published var error: Error?

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    /// Listener registration for children updates.
    private var childrenListener: ListenerRegistration?

    // MARK: - Initialization

    init() {
        // Listener will be set up when the view appears
    }

    deinit {
        // Remove listener when the ViewModel is deallocated
        removeListener()
    }

    // MARK: - Data Fetching & Real-time Listener

    /// Sets up a real-time listener for children in the specified family.
    /// - Parameter familyId: The ID of the parent's family.
    func setupListener(forFamily familyId: String) {
        // Remove existing listener first
        removeListener()

        // Listener for children updates
        childrenListener = firebaseService.db.collection("users")
            .whereField("familyId", isEqualTo: familyId)
            .whereField("role", isEqualTo: UserRole.child.rawValue)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for children updates: \(error.localizedDescription)")
                    self.error = error
                    return
                }

                guard let snapshot = querySnapshot else { return }

                let updatedChildren = snapshot.documents.compactMap { document -> UserProfile? in
                    try? document.data(as: UserProfile.self)
                    // Removed detailed print from here for cleaner logs
                }
                self.children = updatedChildren
                // Keep this summary print if desired, or remove it too
                print("Real-time update: Fetched \(self.children.count) children for family \(familyId).")
            }
    }

    /// Removes the active Firestore listener.
    public func removeListener() {
        childrenListener?.remove()
        childrenListener = nil
        print("Children listener removed.")
    }

    // MARK: - Actions

    /// Creates a new child account.
    /// - Parameters:
    ///   - name: The child's display name.
    ///   - email: The email for the child's account.
    ///   - password: The password for the child's account.
    ///   - parentProfile: The UserProfile of the parent creating the child account.
    @MainActor // Ensure UI updates happen on the main thread
    func createChildAccount(name: String, email: String, password: String, parentProfile: UserProfile) async {
//        isLoading = true
//        error = nil
        do {
            // FirebaseService.createChildAccount handles Auth user creation, UserProfile creation, and Family update
            _ = try await firebaseService.createChildAccount(name: name, email: email, password: password, parentProfile: parentProfile)
            print("Child account created successfully.")
            // The listener will automatically update the 'children' array
        } catch {
            self.error = error
            print("Error creating child account: \(error.localizedDescription)")
        }
//        isLoading = false
    }

    // MARK: - Child Management Actions

    /// Updates an existing child's profile.
    /// - Parameter childProfile: The UserProfile object for the child with updated data.
    /// - Parameter newProfileImage: An optional UIImage to be uploaded as the new profile picture.
    @MainActor // Ensure UI updates happen on the main thread
    func updateChildProfile(_ profile: UserProfile, newProfileImage: UIImage? = nil) async {
        isLoading = true
        error = nil
        var modifiableProfile = profile // Create a mutable copy
        // print("[ViewModel] updateChildProfile called for profile ID: \(profile.id ?? "nil_profile_id"). New image provided: \(newProfileImage != nil)") // Removed

        // Handle image upload if a new image is provided
        if let image = newProfileImage, let userId = modifiableProfile.id {
            // print("[ViewModel] New image is present for user ID: \(userId). Attempting upload.") // Removed
            do {
                // print("[ViewModel] Attempting to upload new profile picture for child: \(userId)") // Removed
                let imageUrl = try await firebaseService.uploadProfilePicture(image, forUserId: userId)
                modifiableProfile.profilePictureUrl = imageUrl
                // print("[ViewModel] Successfully uploaded. New profile picture URL: \(imageUrl)") // Removed
            } catch {
                print("Error uploading profile picture for child \(userId): \(error.localizedDescription)") // Keep error log
                self.error = error // Propagate image upload error
                // Optionally, decide if you want to stop the entire update or proceed without image change
                // isLoading = false
                // return
            }
        } else {
            // Optional: Keep these logs if useful for debugging edge cases
            // if newProfileImage != nil && modifiableProfile.id == nil {
            //     print("[ViewModel] New image provided, but profile ID is nil. Skipping image upload.")
            // } else if newProfileImage == nil {
            //     print("[ViewModel] No new profile image provided. Skipping image upload.")
            // }
        }
        
        // print("[ViewModel] Profile to save: ID=\(modifiableProfile.id ?? "nil"), Name=\(modifiableProfile.name ?? "nil"), URL=\(modifiableProfile.profilePictureUrl ?? "nil")") // Removed

        do {
            try await firebaseService.updateUserProfile(modifiableProfile)
            // print("[ViewModel] Child profile updated successfully in Firestore for \(modifiableProfile.id ?? "N/A").") // Removed
            // The listener will automatically update the 'children' array
        } catch {
            self.error = error
            print("Error updating child profile: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Removes a child account from the family and deletes their profile data.
    /// - Parameter childProfile: The UserProfile object for the child to remove.
    @MainActor // Ensure UI updates happen on the main thread
    func removeChild(_ childProfile: UserProfile) async {
        guard let childId = childProfile.id, let familyId = childProfile.familyId else {
            print("Error: Child profile or family ID missing for removal.")
            self.error = NSError(domain: "ManageChildrenViewModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Child profile or family ID missing for removal."])
            return
        }

        isLoading = true
        error = nil
        do {
            try await firebaseService.removeChildAccount(childId: childId, fromFamily: familyId)
            print("Child account removed successfully for \(childId).")
            // The listener will automatically update the 'children' array
        } catch {
            self.error = error
            print("Error removing child account: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
