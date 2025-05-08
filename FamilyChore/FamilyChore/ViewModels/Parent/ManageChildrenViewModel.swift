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

                self.children = snapshot.documents.compactMap { document in
                    try? document.data(as: UserProfile.self)
                }
                print("Real-time update: Fetched \(self.children.count) children for family \(familyId)")
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

        // Handle image upload if a new image is provided
        if let image = newProfileImage, let userId = modifiableProfile.id {
            do {
                print("Attempting to upload new profile picture for child: \(userId)")
                let imageUrl = try await firebaseService.uploadProfilePicture(image, forUserId: userId)
                modifiableProfile.profilePictureUrl = imageUrl
                print("New profile picture URL: \(imageUrl)")
            } catch {
                print("Error uploading profile picture for child \(userId): \(error.localizedDescription)")
                // Decide if this error should stop the whole update or just skip image update
                self.error = error // Propagate image upload error
                // isLoading = false // Potentially stop here if image upload is critical
                // return
            }
        }

        do {
            try await firebaseService.updateUserProfile(modifiableProfile)
            print("Child profile updated successfully for \(modifiableProfile.id ?? "N/A").")
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
