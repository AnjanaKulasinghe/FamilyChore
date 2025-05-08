import Foundation
import FirebaseCore // For FirebaseApp.configure()
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit // Needed for UIImage

// Custom Error for Co-Parent Linking Issues
enum FindParentError: Error, LocalizedError {
    case alreadyInFamily(email: String, familyId: String)
    // Add other specific cases if needed

    var errorDescription: String? {
        switch self {
        case .alreadyInFamily(let email, let familyId):
            // Provide a user-friendly message
            return "Parent with email \(email) already belongs to a family."
            // Alternative: "This parent account is already linked to a family."
        }
    }
}

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
        
        // Use a batched write for atomic updates where possible
        let batch = db.batch()
        
        // 1. Find Tasks assigned to the child and remove them from the assignment list
        let tasksQuery = db.collection("tasks").whereField("assignedChildIds", arrayContains: childId)
        let tasksSnapshot = try await tasksQuery.getDocuments()
        
        for document in tasksSnapshot.documents {
            let taskRef = db.collection("tasks").document(document.documentID)
            batch.updateData(["assignedChildIds": FieldValue.arrayRemove([childId])], forDocument: taskRef)
            print("Scheduled removal of child \(childId) from task \(document.documentID)")
        }
        
        // 2. Find Rewards assigned to the child and remove them from the assignment list
        let rewardsQuery = db.collection("rewards").whereField("assignedChildIds", arrayContains: childId)
        let rewardsSnapshot = try await rewardsQuery.getDocuments()
        
        for document in rewardsSnapshot.documents {
            let rewardRef = db.collection("rewards").document(document.documentID)
            batch.updateData(["assignedChildIds": FieldValue.arrayRemove([childId])], forDocument: rewardRef)
            print("Scheduled removal of child \(childId) from reward \(document.documentID)")
        }
        
        // 3. Schedule deletion of the child's UserProfile document
        let userRef = db.collection("users").document(childId)
        batch.deleteDocument(userRef)
        print("Scheduled deletion of UserProfile document for child: \(childId)")
        
        // 4. Schedule removal of the child's ID from the Family document
        let familyRef = db.collection("families").document(familyId)
        batch.updateData(["childIds": FieldValue.arrayRemove([childId])], forDocument: familyRef)
        print("Scheduled removal of child \(childId) from family \(familyId)")
        
        // 5. Commit the batch
        try await batch.commit()
        print("Successfully committed batch removal for child \(childId)")
        
        // NOTE: Still doesn't delete the Auth user.
    }
    
    /// Finds a UserProfile document for a parent user based on their email address.
    /// Only returns a profile if the user has the 'parent' role.
    /// Further validation (like checking familyId) should happen in the ViewModel.
    /// - Parameter email: The email address to search for.
    /// - Returns: The UserProfile object if found and eligible (parent role, not in a family).
    /// - Throws: `FindParentError.alreadyInFamily` if found but ineligible, or other Firestore errors.
    func findParentByEmail(email: String) async throws -> UserProfile? {
        let querySnapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .whereField("role", isEqualTo: UserRole.parent.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            return nil // Not found or not a parent
        }
        
        let userProfile = try document.data(as: UserProfile.self)
        
        // Removed check for existing familyId - Allow linking parents already in a family
        // Note: This requires handling multi-family logic elsewhere in the app later.
        
        // Found and is a parent
        return userProfile
    }
    
    /// Adds an existing parent user to a specified family.
    /// Updates both the Family document and the parent's UserProfile document.
    /// - Parameters:
    ///   - parentToAddId: The ID of the parent user to add.
    ///   - familyId: The ID of the family to add the parent to.
    /// - Throws: An error if any Firestore operation fails.
    func addParentToFamily(parentToAddId: String, familyId: String) async throws {
        // 1. Update the Family document to include the new parent's ID
        let familyRef = db.collection("families").document(familyId)
        try await familyRef.updateData([
            "parentIds": FieldValue.arrayUnion([parentToAddId])
        ])
        print("Successfully added parent \(parentToAddId) to family \(familyId)")
        
        // 2. Update the co-parent's UserProfile document to set their familyId
        // Note: Consider security implications and Cloud Functions for production.
        let userRef = db.collection("users").document(parentToAddId)
        try await userRef.updateData([
            "familyId": familyId
        ])
        print("Successfully updated familyId for parent \(parentToAddId)")
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
    
    /// Fetches the UserProfile documents for all parents in a given family.
    /// - Parameter familyId: The ID of the family.
    /// - Returns: An array of UserProfile objects for the parents in the family.
    /// - Throws: An error if the Firestore query fails or documents cannot be decoded.
    func fetchParents(forFamily familyId: String) async throws -> [UserProfile] {
        let querySnapshot = try await db.collection("users")
            .whereField("familyId", isEqualTo: familyId)
            .whereField("role", isEqualTo: UserRole.parent.rawValue) // Filter by parent role
            .getDocuments()
        
        // Use compactMap to attempt decoding each document and discard failures
        let parents = querySnapshot.documents.compactMap { document in
            try? document.data(as: UserProfile.self)
        }
        
        print("Successfully fetched \(parents.count) parents for family \(familyId)")
        return parents
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
    /// Helper function to automatically assign linked rewards to children assigned to a task.
    /// Adds updates to the provided WriteBatch. Does not commit the batch.
    /// - Parameters:
    ///   - task: The task being created or updated.
    ///   - batch: The Firestore WriteBatch to add updates to.
    private func _autoAssignRewardsForTask(task: ChildTask, batch: WriteBatch) {
        guard !task.linkedRewardIds.isEmpty, !task.assignedChildIds.isEmpty else {
            // No linked rewards or no assigned children, nothing to do.
            return
        }
        
        print("Checking reward assignments for task: \(task.id ?? "new")")
        // For each reward linked to the task...
        for rewardId in task.linkedRewardIds {
            let rewardRef = db.collection("rewards").document(rewardId)
            // ...schedule an update to ensure all children assigned to the task
            // are also added to the reward's assigned list.
            // arrayUnion prevents duplicates if they are already assigned.
            batch.updateData(["assignedChildIds": FieldValue.arrayUnion(task.assignedChildIds)], forDocument: rewardRef)
            print("Scheduled update for reward \(rewardId) to ensure children \(task.assignedChildIds) are assigned.")
        }
    }
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
        let batch = db.batch()
        
        // 1. Create the new task document reference (Firestore generates ID)
        let newTaskRef = db.collection("tasks").document()
        // Set the task data in the batch
        try batch.setData(from: task, forDocument: newTaskRef)
        print("Scheduled creation for task: \(task.title)")
        
        // 2. Schedule reward assignments if needed
        // Create a temporary task copy with the generated ID for the helper
        var taskWithId = task
        taskWithId.id = newTaskRef.documentID
        _autoAssignRewardsForTask(task: taskWithId, batch: batch)
        
        // 3. Commit the batch
        try await batch.commit()
        print("Successfully committed batch for creating task: \(task.title)")
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
        
        let batch = db.batch()
        let taskRef = db.collection("tasks").document(taskId)
        
        // 1. Schedule task update (merge ensures we only update fields present in the model)
        try batch.setData(from: task, forDocument: taskRef, merge: true)
        print("Scheduled update for task: \(task.title) (\(taskId))")
        
        // 2. Schedule reward assignments if needed
        _autoAssignRewardsForTask(task: task, batch: batch)
        
        // 3. Commit the batch
        try await batch.commit()
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
    
    
    // MARK: - Reward Claiming Operations
// MARK: - Reward Claim Fetching

    /// Fetches RewardClaim documents for a given family, optionally filtering by status.
    /// - Parameters:
    ///   - familyId: The ID of the family.
    ///   - statuses: An optional array of ClaimStatus raw values to filter by. If nil or empty, fetches all claims for the family.
    /// - Returns: An array of RewardClaim objects.
    /// - Throws: An error if the Firestore query fails.
    func fetchRewardClaims(forFamily familyId: String, statuses: [String]? = nil) async throws -> [RewardClaim] {
        var query: Query = db.collection("rewardClaims").whereField("familyId", isEqualTo: familyId)

        if let statuses = statuses, !statuses.isEmpty {
            query = query.whereField("status", in: statuses)
        }
        // Add ordering if needed, e.g., by claimedAt date descending
        query = query.order(by: "claimedAt", descending: true)

        let querySnapshot = try await query.getDocuments()
        let claims = querySnapshot.documents.compactMap { try? $0.data(as: RewardClaim.self) }

        print("Successfully fetched \(claims.count) reward claims for family \(familyId) (statuses: \(statuses?.joined(separator: ", ") ?? "all"))")
        return claims
    }

    /// Fetches RewardClaim documents for a given child.
    /// - Parameter childId: The ID of the child.
    /// - Returns: An array of RewardClaim objects for the specified child.
    /// - Throws: An error if the Firestore query fails.
    func fetchRewardClaims(forChild childId: String) async throws -> [RewardClaim] {
        let query = db.collection("rewardClaims")
            .whereField("childId", isEqualTo: childId)
            .order(by: "claimedAt", descending: true) // Order by claim date

        let querySnapshot = try await query.getDocuments()
        let claims = querySnapshot.documents.compactMap { try? $0.data(as: RewardClaim.self) }

        print("Successfully fetched \(claims.count) reward claims for child \(childId)")
        return claims
    }
    
    /// Creates a RewardClaim document and deducts points from the child's profile within a transaction.
    /// - Parameters:
    ///   - reward: The Reward being claimed.
    ///   - child: The UserProfile of the child claiming the reward.
    ///   - familyId: The ID of the family.
    /// - Throws: An error if the transaction fails, child has insufficient points, or required IDs are missing.
    func claimReward(reward: Reward, child: UserProfile, familyId: String) async throws {
        guard let childId = child.id else {
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Child ID missing for reward claim."])
        }
        guard let rewardId = reward.id else {
            throw NSError(domain: "FirebaseServiceError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Reward ID missing for reward claim."])
        }
        // Use the non-optional points field
        guard child.points >= reward.requiredPoints else {
            throw NSError(domain: "FirebaseServiceError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Insufficient points to claim this reward."])
        }
        
        let childRef = db.collection("users").document(childId)
        let newClaimRef = db.collection("rewardClaims").document() // Auto-generate ID for the new claim
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            // 1. Read the child's current points within the transaction (for safety)
            let childSnapshot: DocumentSnapshot
            do {
                childSnapshot = try transaction.getDocument(childRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                print("Transaction Error: Failed to read child document \(childId). \(fetchError.localizedDescription)")
                return nil
            }
            
            // Use the non-optional points field, default to 0 if somehow missing in DB
            let pointsOnServer = childSnapshot.data()?["points"] as? Int64 ?? 0
            
            // 2. Verify points again within transaction
            guard pointsOnServer >= reward.requiredPoints else {
                let error = NSError(domain: "FirebaseServiceError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Insufficient points (checked in transaction)."])
                errorPointer?.pointee = error
                print("Transaction Error: Insufficient points for child \(childId) to claim reward \(rewardId).")
                return nil
            }
            
            // 3. Deduct points
            transaction.updateData(["points": FieldValue.increment(-Int64(reward.requiredPoints))], forDocument: childRef)
            
            // 4. Create the RewardClaim document
            // Ensure RewardClaim initializer uses correct field names (reward.requiredPoints)
            let newClaim = RewardClaim(reward: reward, child: child, familyId: familyId)
            do {
                // Set the data for the auto-generated document ID
                try transaction.setData(from: newClaim, forDocument: newClaimRef)
            } catch let encodeError as NSError {
                errorPointer?.pointee = encodeError
                print("Transaction Error: Failed to encode RewardClaim. \(encodeError.localizedDescription)")
                return nil
            }
            
            return nil // Indicate success to Firestore transaction API
        }
        
        // If the transaction completes without throwing, it was successful.
        print("Successfully claimed reward \(rewardId) for child \(childId) and created claim \(newClaimRef.documentID)")
    }
    /// Updates specific fields on a RewardClaim document.
    /// - Parameters:
    ///   - claimId: The ID of the RewardClaim document to update.
    ///   - updates: A dictionary containing the fields and values to update.
    /// - Throws: An error if the Firestore operation fails.
    func updateRewardClaim(claimId: String, updates: [String: Any]) async throws {
        let claimRef = db.collection("rewardClaims").document(claimId)
        try await claimRef.updateData(updates)
        print("Successfully updated reward claim \(claimId) with fields: \(updates.keys.joined(separator: ", "))")
    }
    
    /// Updates a RewardClaim to set the reminder status and timestamp.
    /// - Parameter claimId: The ID of the RewardClaim document to update.
    /// - Throws: An error if the Firestore operation fails.
    func updateRewardClaimReminder(claimId: String) async throws {
        let claimRef = db.collection("rewardClaims").document(claimId)
        // Only update if status is pending or promised? Or allow multiple reminders?
        // For now, allow reminder anytime before granted.
        // Consider adding logic in ViewModel to limit reminder frequency.
        try await claimRef.updateData([
            "status": ClaimStatus.reminded.rawValue,
            "lastRemindedAt": Timestamp(date: Date())
        ])
        print("Successfully updated reminder for reward claim \(claimId)")
    }
}
