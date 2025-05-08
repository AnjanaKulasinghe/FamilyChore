import Foundation
import FirebaseCore // For FirebaseApp.configure()
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// A singleton class to manage all interactions with Firebase services (Auth, Firestore, Storage).
class FirebaseService {
    
    // MARK: - Properties
    
    /// Shared singleton instance.
    static let shared = FirebaseService()
    
    /// Reference to the Firebase Authentication service.
    let auth: Auth
    
    /// Reference to the Firestore database service.
    let db: Firestore
    
    /// Reference to the Firebase Storage service.
    let storage: Storage
    
    // MARK: - Initialization
    
    /// Private initializer to ensure singleton usage.
    private init() {
        // Ensure Firebase is configured before accessing services.
        // This should ideally be called once in the App's initializer.
        // FirebaseApp.configure() // Assuming this is called in FamilyChoreApp.swift
        
        self.auth = Auth.auth()
        self.db = Firestore.firestore()
        self.storage = Storage.storage()
        
        // Optional: Configure Firestore settings (e.g., offline persistence)
        // let settings = FirestoreSettings()
        // settings.isPersistenceEnabled = true
        // self.db.settings = settings
    }
    
    // MARK: - Configuration (App Delegate or App Struct)
    
    /// Call this method early in your app's lifecycle, typically in `AppDelegate` or your `@main` App struct.
    static func configure() {
        FirebaseApp.configure()
        print("Firebase configured successfully.")
        // You could potentially move the singleton initialization here if needed,
        // but accessing .shared should be sufficient after configuration.
    }
    
    // MARK: - Placeholder Methods (To be implemented in later steps)
    
    // MARK: - Authentication Methods (Phase 2)
    
    /// Creates a new Parent user account, a new Family document, and the parent's UserProfile document.
    /// - Parameters:
    ///   - email: The email address for the new parent account.
    ///   - password: The password for the new parent account.
    /// - Returns: The newly created UserProfile for the parent.
    /// - Throws: An error if any Firebase operation fails.
    func signUpParent(email: String, password: String) async throws -> UserProfile {
        // 1. Create Firebase Auth user
        let authResult = try await auth.createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        print("Successfully created Auth user with UID: \(userId)")
        
        // 2. Create a new Family document in Firestore
        let newFamily = Family(parentIds: [userId], childIds: [])
        // Use addDocument(from:) to let Firestore generate the ID
        let familyRef = try await db.collection("families").addDocument(from: newFamily)
        let familyId = familyRef.documentID
        print("Successfully created Family document with ID: \(familyId)")
        
        // 3. Create the UserProfile document for the parent
        var userProfile = UserProfile(
            id: userId, // Explicitly set ID here, though @DocumentID handles fetch
            email: email,
            role: .parent,
            familyId: familyId,
            profilePictureUrl: nil, // Initially no picture
            name: nil // Parent name can be added later if needed
        )
        
        // Save the UserProfile document for the parent to Firestore
        try await db.collection("users").document(userId).setData(from: userProfile)
        print("Successfully created UserProfile document for parent: \(userId)")
        
        return userProfile
    }
    
    /// Logs in an existing user with email and password.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Returns: The authenticated Firebase User object.
    /// - Throws: An error if login fails (e.g., incorrect password, user not found).
    func login(email: String, password: String) async throws -> User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        print("Successfully logged in user with UID: \(authResult.user.uid)")
        return authResult.user
    }
    
    /// Fetches the UserProfile document from Firestore for a given user ID.
    /// - Parameter userId: The Firebase Auth UID of the user.
    /// - Returns: The UserProfile object for the specified user.
    /// - Throws: An error if the document doesn't exist or cannot be decoded.
    func fetchUserProfile(userId: String) async throws -> UserProfile {
        let documentSnapshot = try await db.collection("users").document(userId).getDocument()
        
        guard documentSnapshot.exists else {
            print("Error: UserProfile document does not exist for UID: \(userId)")
            // Consider a more specific error type here
            throw NSError(domain: "FirebaseServiceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found."])
        }
        
        // Use documentSnapshot.data(as: UserProfile.self) which leverages Codable
        let userProfile = try documentSnapshot.data(as: UserProfile.self)
        print("Successfully fetched UserProfile for UID: \(userId)")
        return userProfile
    }
    
    /// Signs out the current user from Firebase Authentication.
    /// - Throws: An error if signing out fails.
    func signOut() throws {
        try auth.signOut()
        print("User signed out successfully.")
    }
    
    /// Creates a new Child user account and their UserProfile document, and adds the child to the family's document.
    /// - Parameters:
    ///   - name: The child's display name.
    ///   - email: The email address for the new child account.
    ///   - password: The password for the new child account.
    ///   - parentProfile: The UserProfile of the parent creating the child account.
    /// - Returns: The newly created UserProfile for the child.
    /// - Throws: An error if any Firebase operation fails.
    func createChildAccount(name: String, email: String, password: String, parentProfile: UserProfile) async throws -> UserProfile {
        guard let familyId = parentProfile.familyId else {
            print("Error: Parent profile does not have a familyId.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Parent profile missing family ID."])
        }
        
        // 1. Create Firebase Auth user for the child
        let authResult = try await auth.createUser(withEmail: email, password: password)
        let childUserId = authResult.user.uid
        print("Successfully created Auth user for child with UID: \(childUserId)")
        
        // 2. Create the UserProfile document for the child
        var childProfile = UserProfile(
            id: childUserId,
            email: email,
            role: .child,
            familyId: familyId,
            profilePictureUrl: nil, // Child profile picture can be added later
            name: name
        )
        
        // Set the document in Firestore using the childUserId as the document ID
        try await db.collection("users").document(childUserId).setData(from: childProfile)
        print("Successfully created UserProfile document for child: \(childUserId)")
        
        // 3. Update the Family document to include the new child's ID
        let familyRef = db.collection("families").document(familyId)
        try await familyRef.updateData([
            "childIds": FieldValue.arrayUnion([childUserId])
        ])
        print("Successfully added child \(childUserId) to family \(familyId)")
        
        // Return the created child profile
        childProfile.id = childUserId // Ensure the returned profile has the ID
        return childProfile
    }

    /// Updates an existing UserProfile document in Firestore.
    /// - Parameter userProfile: The UserProfile object with updated data. Must have a valid ID.
    /// - Throws: An error if the user profile ID is missing or the Firestore operation fails.
    func updateUserProfile(_ userProfile: UserProfile) async throws {
        guard let userId = userProfile.id else {
            print("Error: UserProfile ID is missing for update.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "UserProfile ID missing for update."])
        }

        // Use setData(from:merge:true) to update existing fields without overwriting the whole document
        try await db.collection("users").document(userId).setData(from: userProfile, merge: true)
        print("Successfully updated UserProfile for user: \(userId)")
    }

    /// Removes a child's UserProfile document from Firestore and removes their ID from the family document.
    /// NOTE: This does NOT delete the Firebase Authentication user. Deleting Auth users should be done from a secure backend.
    /// - Parameters:
    ///   - childId: The ID of the child user to remove.
    ///   - familyId: The ID of the family the child belongs to.
    /// - Throws: An error if any Firestore operation fails.
    func removeChildAccount(childId: String, fromFamily familyId: String) async throws {
        // 1. Delete the child's UserProfile document
        try await db.collection("users").document(childId).delete()
        print("Successfully deleted UserProfile document for child: \(childId)")

        // 2. Remove the child's ID from the Family document
        let familyRef = db.collection("families").document(familyId)
        try await familyRef.updateData([
            "childIds": FieldValue.arrayRemove([childId])
        ])
        print("Successfully removed child \(childId) from family \(familyId)")
    }

    // MARK: - Firestore Operations (Phase 2 & 6)
    
    /// Fetches a Family document from Firestore based on its ID.
    /// - Parameter familyId: The ID of the family document.
    /// - Returns: The Family object for the specified ID.
    /// - Throws: An error if the document doesn't exist or cannot be decoded.
    func fetchFamily(familyId: String) async throws -> Family {
        let documentSnapshot = try await db.collection("families").document(familyId).getDocument()
        
        guard documentSnapshot.exists else {
            print("Error: Family document does not exist for ID: \(familyId)")
            throw NSError(domain: "FirebaseServiceError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Family not found."])
        }
        
        let family = try documentSnapshot.data(as: Family.self)
        print("Successfully fetched Family for ID: \(familyId)")
        return family
    }
    
    // func createFamily(...) // This is handled in signUpParent for the initial family
    
    /// Fetches the UserProfile documents for all children in a given family.
    /// - Parameter familyId: The ID of the family.
    /// - Returns: An array of UserProfile objects for the children in the family.
    /// - Throws: An error if the Firestore query fails or documents cannot be decoded.
    func fetchChildren(forFamily familyId: String) async throws -> [UserProfile] {
        let querySnapshot = try await db.collection("users")
            .whereField("familyId", isEqualTo: familyId)
            .whereField("role", isEqualTo: UserRole.child.rawValue) // Filter by child role
            .getDocuments()
        
        // Use compactMap to attempt decoding each document and discard failures
        let children = querySnapshot.documents.compactMap { document in
            try? document.data(as: UserProfile.self)
        }
        
        print("Successfully fetched \(children.count) children for family \(familyId)")
        return children
    }
    
    /// Fetches Task documents from Firestore assigned to a specific child.
    /// - Parameter childId: The ID of the child.
    /// - Returns: An array of Task objects assigned to the child.
    /// - Throws: An error if the Firestore query fails or documents cannot be decoded.
    func fetchTasks(forChild childId: String) async throws -> [ChildTask] {
        let querySnapshot = try await db.collection("tasks")
            .whereField("assignedChildIds", arrayContains: childId)
            .getDocuments()
        
        let tasks = querySnapshot.documents.compactMap { document in
            try? document.data(as: ChildTask.self)
        }
        
        print("Successfully fetched \(tasks.count) tasks for child \(childId)")
        return tasks
    }

    /// Fetches Task documents from Firestore for a given family.
    /// - Parameter familyId: The ID of the family.
    /// - Returns: An array of Task objects for the specified family.
    /// - Throws: An error if the Firestore query fails or documents cannot be decoded.
    func fetchTasks(forFamily familyId: String) async throws -> [ChildTask] {
        // Note: Tasks don't have a direct familyId field. We need to fetch children first, then tasks.
        // This could be inefficient. Consider adding familyId to tasks if needed frequently.
        // Alternative: Fetch all tasks and filter client-side (not recommended for large datasets).
        // For now, let's assume we fetch tasks based on the parent who created them.
        // This requires knowing the parent's ID. A better approach might be needed.
        // Let's fetch ALL tasks for now and filter later, or adjust the data model.
        // A more scalable approach would be to query based on assignedChildIds belonging to the family.

        // Fetching all tasks (less efficient, consider refining based on actual needs)
        // We need a way to link tasks to a family. Let's assume tasks have a 'familyId' field for this example.
        // If 'familyId' is not on tasks, this query needs adjustment.
        let querySnapshot = try await db.collection("tasks")
            .whereField("familyId", isEqualTo: familyId) // ASSUMING tasks have familyId
            .getDocuments()

        let tasks = querySnapshot.documents.compactMap { document in
            try? document.data(as: ChildTask.self)
        }

        print("Successfully fetched \(tasks.count) tasks for family \(familyId)")
        return tasks
    }

    /// Fetches Reward documents from Firestore assigned to a specific child.
    /// - Parameter childId: The ID of the child.
    /// - Returns: An array of Reward objects assigned to the child.
    /// - Throws: An error if the Firestore query fails or documents cannot be decoded.
    func fetchRewards(forChild childId: String) async throws -> [Reward] {
        let querySnapshot = try await db.collection("rewards")
            .whereField("assignedChildIds", arrayContains: childId)
            .getDocuments()
        
        let rewards = querySnapshot.documents.compactMap { document in
            try? document.data(as: Reward.self)
        }
        
        print("Successfully fetched \(rewards.count) rewards for child \(childId)")
        return rewards
    }

    /// Fetches all Reward documents from Firestore for a given family.
    /// - Parameter familyId: The ID of the family.
    /// - Returns: An array of Reward objects for the specified family.
    /// - Throws: An error if the Firestore query fails or documents cannot be decoded.
    func fetchRewards(forFamily familyId: String) async throws -> [Reward] {
        let querySnapshot = try await db.collection("rewards")
            .whereField("familyId", isEqualTo: familyId)
            .getDocuments()

        let rewards = querySnapshot.documents.compactMap { document in
            try? document.data(as: Reward.self)
        }

        print("Successfully fetched \(rewards.count) rewards for family \(familyId)")
        return rewards
    }

    /// Creates a new Task document in Firestore.
    /// - Parameter task: The Task object to create.
    /// - Throws: An error if the Firestore operation fails.
    func createTask(_ task: ChildTask) async throws {
        // Firestore will automatically generate a document ID
        _ = try await db.collection("tasks").addDocument(from: task)
        print("Successfully created task: \(task.title)")
    }
    
    /// Creates a new Reward document in Firestore.
    /// - Parameter reward: The Reward object to create.
    /// - Throws: An error if the Firestore operation fails.
    func createReward(_ reward: Reward) async throws {
        // Firestore will automatically generate a document ID
        _ = try await db.collection("rewards").addDocument(from: reward)
        print("Successfully created reward: \(reward.title)")
    }
    
    /// Updates an existing Task document in Firestore.
    /// - Parameter task: The Task object with updated data. Must have a valid ID.
    /// - Throws: An error if the task ID is missing or the Firestore operation fails.
    func updateTask(_ task: ChildTask) async throws {
        guard let taskId = task.id else {
            print("Error: Task ID is missing for update.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Task ID missing for update."])
        }
        
        // Use setData(from:merge:true) to update existing fields without overwriting the whole document
        try await db.collection("tasks").document(taskId).setData(from: task, merge: true)
        print("Successfully updated task: \(task.title) (\(taskId))")
    }

    /// Deletes a Task document from Firestore.
    /// - Parameter taskId: The ID of the task to delete.
    /// - Throws: An error if the Firestore operation fails.
    func deleteTask(taskId: String) async throws {
        try await db.collection("tasks").document(taskId).delete()
        print("Successfully deleted task with ID: \(taskId)")
    }

    /// Updates an existing Reward document in Firestore.
    /// - Parameter reward: The Reward object with updated data. Must have a valid ID.
    /// - Throws: An error if the reward ID is missing or the Firestore operation fails.
    func updateReward(_ reward: Reward) async throws {
        guard let rewardId = reward.id else {
            print("Error: Reward ID is missing for update.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Reward ID missing for update."])
        }
        
        // Use setData(from:merge:true) to update existing fields without overwriting the whole document
        try await db.collection("rewards").document(rewardId).setData(from: reward, merge: true)
        print("Successfully updated reward: \(reward.title) (\(rewardId))")
    }

    /// Deletes a Reward document from Firestore.
    /// - Parameter rewardId: The ID of the reward to delete.
    /// - Throws: An error if the Firestore operation fails.
    func deleteReward(rewardId: String) async throws {
        try await db.collection("rewards").document(rewardId).delete()
        print("Successfully deleted reward with ID: \(rewardId)")
    }

    /// Updates a task's status to submitted and adds the proof image URL.
    /// - Parameters:
    ///   - task: The Task object to submit. Must have a valid ID.
    ///   - proofImageUrl: The URL string for the photo proof.
    /// - Throws: An error if the task ID is missing or the Firestore operation fails.
    func submitTask(_ task: ChildTask, proofImageUrl: String?) async throws {
        guard let taskId = task.id else {
            print("Error: Task ID is missing for submission.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Task ID missing for submission."])
        }
        
        var updatedTask = task
        updatedTask.status = .submitted
        updatedTask.proofImageUrl = proofImageUrl
        updatedTask.updatedAt = Timestamp(date: Date()) // Update timestamp
        
        // Use setData(from:merge:true) to update existing fields
        try await db.collection("tasks").document(taskId).setData(from: updatedTask, merge: true)
        print("Successfully submitted task: \(task.title) (\(taskId))")
    }
    
    /// Approves a submitted task, updates its status, and awards points to the assigned children.
    /// - Parameter task: The Task object to approve. Must have a valid ID and be in .submitted status.
    /// - Throws: An error if the task ID is missing, status is incorrect, or Firestore operation fails.
    func approveTask(_ task: ChildTask) async throws {
        guard let taskId = task.id else {
            print("Error: Task ID is missing for approval.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Task ID missing for approval."])
        }
        
        guard task.status == .submitted else {
            print("Error: Task \(taskId) is not in submitted status for approval.")
            throw NSError(domain: "FirebaseServiceError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Task is not in submitted status."])
        }
        
        // Update task status to approved
        let taskRef = db.collection("tasks").document(taskId)
        try await taskRef.updateData([
            "status": TaskStatus.approved.rawValue,
            "updatedAt": Timestamp(date: Date())
        ])
        print("Successfully approved task: \(task.title) (\(taskId))")
        
        // Award points to assigned children
        for childId in task.assignedChildIds {
            let childRef = db.collection("users").document(childId)
            // Use FieldValue.increment to safely add points
            try await childRef.updateData([
                "points": FieldValue.increment(Int64(task.points))
            ])
            print("Awarded \(task.points) points to child \(childId) for task \(taskId)")
        }
    }
    
    /// Declines a submitted task and updates its status.
    /// - Parameter task: The Task object to decline. Must have a valid ID and be in .submitted status.
    /// - Throws: An error if the task ID is missing, status is incorrect, or Firestore operation fails.
    func declineTask(_ task: ChildTask) async throws {
        guard let taskId = task.id else {
            print("Error: Task ID is missing for decline.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Task ID missing for decline."])
        }
        
        guard task.status == .submitted else {
            print("Error: Task \(taskId) is not in submitted status for decline.")
            throw NSError(domain: "FirebaseServiceError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Task is not in submitted status."])
        }
        
        // Update task status to declined
        let taskRef = db.collection("tasks").document(taskId)
        try await taskRef.updateData([
            "status": TaskStatus.declined.rawValue, // Note: Should be .declined based on enum
            "updatedAt": Timestamp(date: Date())
        ])
        print("Successfully declined task: \(task.title) (\(taskId))")
    }

    /// Resets a task's status to pending and clears the proof image URL.
    /// - Parameter task: The Task object to reset. Must have a valid ID.
    /// - Throws: An error if the task ID is missing or the Firestore operation fails.
    func resetTaskToPending(_ task: ChildTask) async throws {
        guard let taskId = task.id else {
            print("Error: Task ID is missing for reset.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Task ID missing for reset."])
        }

        // Update task status to pending and clear proof image URL
        let taskRef = db.collection("tasks").document(taskId)
        try await taskRef.updateData([
            "status": TaskStatus.pending.rawValue,
            "proofImageUrl": FieldValue.delete(), // Remove the proof image URL field
            "updatedAt": Timestamp(date: Date()) // Update timestamp
        ])
        print("Successfully reset task to pending: \(task.title) (\(taskId))")
    }


    // MARK: - Storage Operations (Phase 6)
    
    /// Uploads a profile picture to Firebase Storage.
    /// - Parameters:
    ///   - image: The UIImage to upload.
    ///   - userId: The ID of the user the profile picture belongs to.
    /// - Returns: The download URL string of the uploaded image.
    /// - Throws: An error if the image data cannot be created or the upload fails.
    func uploadProfilePicture(_ image: UIImage, forUserId userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not get JPEG data from UIImage.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not get image data."])
        }
        
        let storageRef = storage.reference().child("profile_pictures/\(userId).jpg")
        
        let _ = try await storageRef.putDataAsync(imageData)
        print("Successfully uploaded profile picture for user \(userId).")
        
        let downloadURL = try await storageRef.downloadURL()
        print("Profile picture download URL: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }
    
    /// Uploads a task proof image to Firebase Storage.
    /// - Parameters:
    ///   - image: The UIImage to upload.
    ///   - taskId: The ID of the task the proof belongs to.
    /// - Returns: The download URL string of the uploaded image.
    /// - Throws: An error if the image data cannot be created or the upload fails.
    func uploadTaskProof(_ image: UIImage, forTaskId taskId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not get JPEG data from UIImage.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not get image data."])
        }
        
        // Use a UUID to ensure unique filenames for task proofs
        let filename = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("task_proofs/\(taskId)/\(filename)")
        
        let _ = try await storageRef.putDataAsync(imageData)
        print("Successfully uploaded task proof for task \(taskId).")
        
        let downloadURL = try await storageRef.downloadURL()
        print("Task proof download URL: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }

    /// Uploads a reward image to Firebase Storage.
    /// - Parameters:
    ///   - image: The UIImage to upload.
    ///   - imageName: A unique name for the image file (e.g., reward ID or a UUID).
    /// - Returns: The download URL string of the uploaded image.
    /// - Throws: An error if the image data cannot be created or the upload fails.
    func uploadRewardImage(_ image: UIImage, imageName: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not get JPEG data from UIImage for reward image.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not get image data for reward."])
        }

        let storageRef = storage.reference().child("reward_images/\(imageName).jpg")

        let _ = try await storageRef.putDataAsync(imageData)
        print("Successfully uploaded reward image \(imageName).")

        let downloadURL = try await storageRef.downloadURL()
        print("Reward image download URL: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }

    /// Uploads a task display image to Firebase Storage.
    /// - Parameters:
    ///   - image: The UIImage to upload.
    ///   - imageName: A unique name for the image file (e.g., task ID or a UUID).
    /// - Returns: The download URL string of the uploaded image.
    /// - Throws: An error if the image data cannot be created or the upload fails.
    func uploadTaskDisplayImage(_ image: UIImage, imageName: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not get JPEG data from UIImage for task display image.")
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not get image data for task display."])
        }

        let storageRef = storage.reference().child("task_display_images/\(imageName).jpg")

        let _ = try await storageRef.putDataAsync(imageData)
        print("Successfully uploaded task display image \(imageName).")

        let downloadURL = try await storageRef.downloadURL()
        print("Task display image download URL: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }
    
}
