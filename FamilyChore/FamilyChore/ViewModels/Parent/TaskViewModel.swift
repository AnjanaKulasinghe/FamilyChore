import Foundation
import Combine
import FirebaseFirestore // For Firestore types
import SwiftUI // Added for UIImage
// Assuming FirebaseService and Models are accessible

/// ViewModel for creating and managing tasks.
class TaskViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The task data being edited or created.
    // Provide a default familyId, it will be overwritten during save.
    @Published var task: ChildTask = ChildTask(title: "", description: "", points: 0, isRecurring: false, assignedChildIds: [], linkedRewardIds: [], createdByParentId: "", familyId: "")

    /// Array of available children to assign the task to.
    @Published var availableChildren: [UserProfile] = []

    /// Array of available rewards to link the task to.
    @Published var availableRewards: [Reward] = []

    /// Indicates if an operation (create/update) is currently in progress.
    @Published var isLoading = false

    /// Stores any error that occurred.
    @Published var error: Error?

    /// Indicates if the task was successfully saved.
    @Published var isSavedSuccessfully = false

    /// Holds the UIImage selected by the user for the task.
    @Published var selectedImage: UIImage? = nil

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    // MARK: - Initialization

    /// Initializes the ViewModel, optionally with an existing task for editing.
    /// - Parameter task: An existing Task object to edit. If nil, a new task is created.
    init(task: ChildTask? = nil) {
        if let task = task {
            self.task = task
        }
    } // End of init

    // MARK: - Data Fetching

    /// Fetches the list of children available to assign tasks to for a given family.
    /// - Parameter familyId: The ID of the parent's family.
    @MainActor // Ensure UI updates happen on the main thread
    func fetchAvailableChildren(forFamily familyId: String) async {
        isLoading = true
        error = nil
        do {
            // Use FirebaseService to fetch children
            self.availableChildren = try await firebaseService.fetchChildren(forFamily: familyId)
            print("Fetched \(self.availableChildren.count) available children for task assignment.")
        } catch {
            self.error = error
            print("Error fetching available children: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Fetches the list of available rewards for a given family.
    /// - Parameter familyId: The ID of the parent's family.
    @MainActor // Ensure UI updates happen on the main thread
    func fetchAvailableRewards(forFamily familyId: String) async {
        isLoading = true // This might overlap with child fetching, consider separate loading states if needed
        error = nil
        do {
            // Use FirebaseService to fetch rewards
            self.availableRewards = try await firebaseService.fetchRewards(forFamily: familyId)
            print("Fetched \(self.availableRewards.count) available rewards for task linking.")
        } catch {
            self.error = error
            print("Error fetching available rewards: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Actions

    /// Saves the current task (either creates a new one or updates an existing one).
    /// - Parameter parentId: The ID of the parent creating/updating the task.
    @MainActor // Ensure UI updates happen on the main thread
    func saveTask(createdBy parentId: String, familyId: String) async { // Added familyId parameter
        isLoading = true
        error = nil
        isSavedSuccessfully = false

        // Ensure the task has the creator's ID and family ID
        task.createdByParentId = parentId
        task.familyId = familyId // Set familyId here

        // Validate that at least one reward is linked
        guard !task.linkedRewardIds.isEmpty else {
            self.error = NSError(domain: "TaskViewModelError", code: 400, userInfo: [NSLocalizedDescriptionKey: "A task must be linked to at least one reward."])
            isLoading = false
            return
        }

        // Handle image upload if an image is selected
        if let selectedImage = selectedImage {
            let imageName = task.id ?? UUID().uuidString // Use task ID or new UUID for image name
            do {
                // We'll need a new method in FirebaseService: uploadTaskImage
                // For now, let's assume it exists or add a placeholder name.
                // Let's call it uploadTaskDisplayImage to distinguish from proof images.
                let imageUrl = try await firebaseService.uploadTaskDisplayImage(selectedImage, imageName: imageName)
                task.imageUrl = imageUrl
                print("Task display image uploaded successfully: \(imageUrl)")
            } catch {
                print("Error uploading task display image: \(error.localizedDescription)")
                self.error = error
                isLoading = false
                return
            }
        }

        do {
            if task.id == nil {
                // Create a new task
                try await firebaseService.createTask(task)
                print("Task created successfully. Image URL: \(task.imageUrl ?? "None")")
            } else {
                // Update an existing task
                try await firebaseService.updateTask(task)
                print("Task updated successfully. Image URL: \(task.imageUrl ?? "None")")
            }
            isSavedSuccessfully = true
        } catch {
            self.error = error
            print("Error saving task: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Helper Methods

    /// Toggles the assignment status of a child for the current task.
    /// - Parameter childId: The ID of the child to toggle.
    func toggleChildAssignment(childId: String) {
        if task.assignedChildIds.contains(childId) {
            task.assignedChildIds.removeAll(where: { $0 == childId })
        } else {
            task.assignedChildIds.append(childId)
        }
    }

    /// Toggles the linked status of a reward for the current task.
    /// - Parameter rewardId: The ID of the reward to toggle.
    func toggleRewardLinking(rewardId: String) {
        if task.linkedRewardIds.contains(rewardId) {
            task.linkedRewardIds.removeAll(where: { $0 == rewardId })
        } else {
            task.linkedRewardIds.append(rewardId)
        }
    }
}
