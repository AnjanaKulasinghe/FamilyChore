import Foundation
import Combine
import FirebaseFirestore // For Firestore types
import FirebaseStorage // For Storage operations
import UIKit // For UIImage (assuming photo proof is handled as UIImage initially)
// Assuming FirebaseService and Models are accessible

/// ViewModel for handling the submission of a completed task by a child.
class TaskSubmissionViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The task being submitted.
    @Published var task: ChildTask

    /// The photo proof provided by the child.
    @Published var photoProof: UIImage?

    /// Indicates if an operation (uploading or submitting) is currently in progress.
    @Published var isLoading = false

    /// Stores any error that occurred.
    @Published var error: Error?

    /// Indicates if the task was successfully submitted.
    @Published var isSubmittedSuccessfully = false

    /// Progress of the photo upload (0.0 to 1.0).
    @Published var uploadProgress: Double = 0.0

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the shared FirebaseService instance.
    private let firebaseService = FirebaseService.shared

    // MARK: - Initialization

    /// Initializes the ViewModel with the task to be submitted.
    /// - Parameter task: The Task object to be submitted.
    init(task: ChildTask) {
        self.task = task
    }

    // MARK: - Actions

    /// Submits the task, including uploading the photo proof if available.
    @MainActor // Ensure UI updates happen on the main thread
    func submitTask() async {
        isLoading = true
        error = nil
        isSubmittedSuccessfully = false
        uploadProgress = 0.0

        do {
            var proofImageUrl: String? = nil

            // 1. Upload photo proof if available
            if let photo = photoProof {
                guard let taskId = task.id else {
                    print("Error: Task ID is missing for photo upload.")
                    throw NSError(domain: "TaskSubmissionViewModelError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Task ID missing for photo upload."])
                }
                // Upload photo proof to Firebase Storage
                proofImageUrl = try await firebaseService.uploadTaskProof(photo, forTaskId: taskId)
                print("Photo uploaded successfully to \(proofImageUrl ?? "nil")")
                // Note: Real upload progress tracking would require more complex implementation
                uploadProgress = 1.0 // Set to 1.0 on completion
            }

            // 2. Submit task details to Firestore
            try await firebaseService.submitTask(task, proofImageUrl: proofImageUrl)

            print("Task submitted successfully.")
            isSubmittedSuccessfully = true

        } catch {
            self.error = error
            print("Error submitting task: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Resets the task status to pending, allowing the child to resubmit.
    @MainActor // Ensure UI updates happen on the main thread
    func resetTask() async {
        isLoading = true
        error = nil
        isSubmittedSuccessfully = false // Reset submission status
        uploadProgress = 0.0 // Reset upload progress

        do {
            try await firebaseService.resetTaskToPending(task)
            print("Task reset to pending successfully.")
            // The task object in the ViewModel will be updated by the listener in ChildDashboardViewModel
        } catch {
            self.error = error
            print("Error resetting task: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Helper Methods

    // TODO: Add methods for selecting/taking photos (e.g., using UIImagePickerController or PhotosPicker)
}
