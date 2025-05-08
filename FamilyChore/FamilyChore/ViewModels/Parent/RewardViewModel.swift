import Foundation
import Combine
import FirebaseFirestore // For Firestore types
import SwiftUI // Added for UIImage
// Assuming FirebaseService and Models are accessible

/// ViewModel for creating and managing rewards.
class RewardViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The reward data being edited or created.
    // Provide a default familyId, it will be overwritten during save.
    @Published var reward: Reward = Reward(title: "", requiredPoints: 0, assignedChildIds: [], createdByParentId: "", familyId: "")

    /// Array of available children to assign the reward to.
    @Published var availableChildren: [UserProfile] = []

    /// Indicates if an operation (create/update) is currently in progress.
    @Published var isLoading = false

    /// Stores any error that occurred.
    @Published var error: Error?

    /// Indicates if the reward was successfully saved.
    @Published var isSavedSuccessfully = false

    /// Holds the UIImage selected by the user for the reward.
    @Published var selectedImage: UIImage? = nil

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    // MARK: - Initialization

    /// Initializes the ViewModel, optionally with an existing reward for editing.
    /// - Parameter reward: An existing Reward object to edit. If nil, a new reward is created.
    init(reward: Reward? = nil) {
        if let reward = reward {
            self.reward = reward
        }
        // Available children will be fetched when needed, e.g., when the view appears.
    }

    // MARK: - Data Fetching

    /// Fetches the list of children available to assign rewards to for a given family.
    /// - Parameter familyId: The ID of the parent's family.
    @MainActor // Ensure UI updates happen on the main thread
    func fetchAvailableChildren(forFamily familyId: String) async {
        isLoading = true
        error = nil
        do {
            // Use FirebaseService to fetch children
            self.availableChildren = try await firebaseService.fetchChildren(forFamily: familyId)
            print("Fetched \(self.availableChildren.count) available children for reward assignment.")
        } catch {
            self.error = error
            print("Error fetching available children: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Actions

    /// Saves the current reward (either creates a new one or updates an existing one).
    /// - Parameter parentId: The ID of the parent creating/updating the reward.
    @MainActor // Ensure UI updates happen on the main thread
    func saveReward(createdBy parentId: String, familyId: String) async { // Added familyId parameter
        isLoading = true
        error = nil
        isSavedSuccessfully = false

        // Ensure the reward has the creator's ID and family ID
        reward.createdByParentId = parentId
        reward.familyId = familyId // Set familyId here

        // Handle image upload if an image is selected
        if let selectedImage = selectedImage {
            // Generate a unique ID for the image or use reward ID if available
            // For new rewards, reward.id might be nil initially.
            // We might need to create reward document first, get ID, then update with image URL,
            // or generate a UUID for the image name.
            // For simplicity now, let's assume reward.id will be available or we generate one.
            // A more robust solution might involve a two-step save or pre-generating reward ID.

            let imageName = reward.id ?? UUID().uuidString // Use reward ID or new UUID for image name
            do {
                let imageUrl = try await firebaseService.uploadRewardImage(selectedImage, imageName: imageName)
                reward.imageUrl = imageUrl
                print("Image uploaded successfully: \(imageUrl)")
            } catch {
                print("Error uploading reward image: \(error.localizedDescription)")
                // Decide if this error should prevent reward saving or just save without image
                self.error = error // Propagate image upload error
                isLoading = false
                return // Stop if image upload fails
            }
        }


        do {
            if reward.id == nil {
                // Create a new reward
                try await firebaseService.createReward(reward)
                print("Reward created successfully with familyId: \(familyId). Image URL: \(reward.imageUrl ?? "None")")
            } else {
                // Update an existing reward (familyId should already be set if editing an existing one)
                // If familyId could change during edit, ensure it's updated here too.
                // For now, assuming familyId doesn't change for existing rewards during edit.
                try await firebaseService.updateReward(reward)
                print("Reward updated successfully.")
            }
            isSavedSuccessfully = true
        } catch {
            self.error = error
            print("Error saving reward: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Helper Methods

    /// Toggles the assignment status of a child for the current reward.
    /// - Parameter childId: The ID of the child to toggle.
    func toggleChildAssignment(childId: String) {
        if reward.assignedChildIds.contains(childId) {
            reward.assignedChildIds.removeAll(where: { $0 == childId })
        } else {
            reward.assignedChildIds.append(childId)
        }
    }
}