import Foundation
import Combine
import FirebaseFirestore // For Storage operations
import UIKit // For UIImage (assuming profile picture is handled as UIImage initially)
// Assuming FirebaseService and Models are accessible

/// ViewModel for managing a child's profile settings, such as profile picture.
class ProfileViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The child's profile being edited.
    @Published var childProfile: UserProfile

    /// The selected profile picture image.
    @Published var profilePictureImage: UIImage?

    /// Indicates if an operation (uploading or saving) is currently in progress.
    @Published var isLoading = false

    /// Stores any error that occurred.
    @Published var error: Error?

    /// Indicates if the profile was successfully saved.
    @Published var isSavedSuccessfully = false

    /// Progress of the profile picture upload (0.0 to 1.0).
    @Published var uploadProgress: Double = 0.0

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    // MARK: - Initialization

    /// Initializes the ViewModel with the child's profile.
    /// - Parameter childProfile: The UserProfile object for the child.
    init(childProfile: UserProfile) {
        self.childProfile = childProfile
        // TODO: Load existing profile picture if profilePictureUrl is available in childProfile
    }

    // MARK: - Actions

    /// Saves the child's profile, including uploading a new profile picture if selected.
    @MainActor // Ensure UI updates happen on the main thread
    func saveProfile() async {
        isLoading = true
        error = nil
        isSavedSuccessfully = false
        uploadProgress = 0.0

        do {
            var updatedProfile = childProfile
            var profilePictureUrl: String? = childProfile.profilePictureUrl // Keep existing URL by default

            // 1. Upload new profile picture if selected
            if let image = profilePictureImage {
                 guard let userId = updatedProfile.id else {
                     print("Error: Child profile ID is missing for profile picture upload.")
                     throw NSError(domain: "ProfileViewModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Child profile ID missing for profile picture upload."])
                 }
                // Upload profile picture to Firebase Storage
                profilePictureUrl = try await firebaseService.uploadProfilePicture(image, forUserId: userId)
                print("Profile picture uploaded successfully to \(profilePictureUrl ?? "nil")")
                // Note: Real upload progress tracking would require more complex implementation
                uploadProgress = 1.0 // Set to 1.0 on completion
            }

            // Update the profile picture URL in the profile object
            updatedProfile.profilePictureUrl = profilePictureUrl

            // 2. Update the UserProfile document in Firestore
            // Assuming UserProfile has an ID and FirebaseService.updateUserProfile exists or setData(from:merge:true) is used
            // TODO: Implement updateUserProfile in FirebaseService or use a generic update function
            // For now, using setData(from:merge:true) directly via FirebaseService instance
            guard let userId = updatedProfile.id else {
                 print("Error: Child profile ID is missing for update.")
                 throw NSError(domain: "ProfileViewModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Child profile ID missing for update."])
            }
             try await firebaseService.db.collection("users").document(userId).setData(from: updatedProfile, merge: true)


            print("Child profile saved successfully.")
            isSavedSuccessfully = true

        } catch {
            self.error = error
            print("Error saving child profile: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Helper Methods

    // TODO: Add methods for selecting/taking profile pictures (e.g., using UIImagePickerController or PhotosPicker)
}
