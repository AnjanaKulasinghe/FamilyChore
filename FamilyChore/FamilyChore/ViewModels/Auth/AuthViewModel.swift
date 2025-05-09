import Foundation
import Combine
import FirebaseAuth // To observe Auth state changes
import FirebaseFirestore // For fetching UserProfile

/// ViewModel responsible for managing user authentication state and profile data.
class AuthViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The currently authenticated Firebase User. Nil if not authenticated.
    @Published var currentUser: User?

    /// The UserProfile document for the current user. Nil if not authenticated or profile not fetched.
    @Published var userProfile: UserProfile?

    /// Indicates if an authentication operation is currently in progress.
    @Published var isLoading = false

    /// Stores any error that occurred during an authentication operation.
    @Published var error: Error?

    /// Indicates if a child account was successfully created.
    @Published var childAccountCreatedSuccessfully = false

    // MARK: - Private Properties

    /// Cancellable set for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Listener for Firebase Auth state changes.
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?

    /// Listener for the current user's profile document.
    private var userProfileListener: ListenerRegistration?

    // MARK: - Initialization

    init() {
        // Start observing Firebase Auth state changes immediately
        setupAuthStateListener()
    }

    deinit {
        // Remove listeners when the ViewModel is deallocated
        removeAuthStateListener()
        removeUserProfileListener()
    }

    // MARK: - Auth State Listener

    /// Sets up a listener to react to changes in Firebase Authentication state.
    private func setupAuthStateListener() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            self.currentUser = user
            print("Auth state changed. Current user: \(user?.uid ?? "nil")")

            // If a user is logged in, set up the profile listener
            if let user = user {
                 self.setupUserProfileListener(userId: user.uid)
            } else {
                // If no user is logged in, clear the user profile and remove listener
                self.removeUserProfileListener()
                self.userProfile = nil
            }
        }
    }

    /// Removes the Firebase Authentication state listener.
    private func removeAuthStateListener() {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            print("Auth state listener removed.")
        }
    }

    // MARK: - Authentication Methods

    /// Signs up a new Parent user.
    /// - Parameters:
    ///   - email: The email for the new account.
    ///   - password: The password for the new account.
    @MainActor // Ensure UI updates happen on the main thread
    func signUpParent(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            // FirebaseService.signUpParent handles Auth user creation, Family, and UserProfile creation
            let profile = try await FirebaseService.shared.signUpParent(email: email, password: password)
            // The auth state listener will automatically update currentUser and fetch userProfile
            print("Parent signup successful.")
        } catch {
            self.error = error
            print("Error during parent signup: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Logs in an existing user.
    /// - Parameters:
    ///   - email: The user's email.
    ///   - password: The user's password.
    @MainActor // Ensure UI updates happen on the main thread
    func login(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            // FirebaseService.login handles Auth sign in
            _ = try await FirebaseService.shared.login(email: email, password: password)
            // The auth state listener will automatically update currentUser and fetch userProfile
            print("Login successful.")
            isLoading = false // Correctly set on success
        } catch {
            self.error = error
            print("Error during login: \(error.localizedDescription)")
            isLoading = false // Add this to reset loading state on error
        }
    }

    /// Signs out the current user.
    @MainActor // Ensure UI updates happen on the main thread
    func signOut() {
        isLoading = true
        error = nil
        do {
            try FirebaseService.shared.signOut()
            // The auth state listener will automatically update currentUser and userProfile
            print("Sign out successful.")
        } catch {
            self.error = error
            print("Error during sign out: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - User Profile Fetching

    /// Fetches the user's profile from Firestore (kept for potential direct use, but listener is primary).
    /// - Parameter userId: The UID of the user.
    @MainActor
    func fetchUserProfile(userId: String) async {
        // This function can remain for one-time fetches if needed elsewhere,
        // but the listener handles the main @Published var update.
        // We might not need isLoading/error here anymore if only listener updates UI.
        print("Attempting one-time fetch for profile \(userId) (might be redundant due to listener)")
        do {
            let profile = try await FirebaseService.shared.fetchUserProfile(userId: userId)
            // We could update userProfile here too, but listener should overwrite it
            print("One-time fetch successful for \(userId). Role: \(profile.role)")
        } catch {
            print("One-time fetch failed for \(userId): \(error.localizedDescription)")
            // Handle error appropriately if this fetch is critical for some reason
        }
    }

    /// Sets up a real-time listener for the specified user's profile document.
    /// - Parameter userId: The UID of the user whose profile to listen to.
    private func setupUserProfileListener(userId: String) {
        // Remove existing listener first
        removeUserProfileListener()
        print("Setting up profile listener for user: \(userId)")
        isLoading = true // Indicate loading while listener attaches

        userProfileListener = FirebaseService.shared.db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                DispatchQueue.main.async { // Ensure UI updates on main thread
                    self.isLoading = false // Listener attached or error occurred
                    if let error = error {
                        print("Error listening for user profile updates (\(userId)): \(error.localizedDescription)")
                        self.error = error
                        // Consider what should happen if listener fails - clear profile? Sign out?
                        // self.userProfile = nil
                        // self.signOut()
                        return
                    }

                    guard let document = documentSnapshot else {
                        print("User profile document (\(userId)) was nil.")
                        self.error = NSError(domain: "AuthViewModelError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile document not found."])
                        // Handle missing profile - maybe sign out?
                        // self.userProfile = nil
                        // self.signOut()
                        return
                    }

                    do {
                        let profile = try document.data(as: UserProfile.self)
                        self.userProfile = profile
                        self.error = nil // Clear previous errors on success
                        print("User profile listener updated for \(userId). Name: \(profile.name ?? "N/A")")
                    } catch {
                        print("Error decoding user profile (\(userId)): \(error.localizedDescription)")
                        self.error = error
                        // Handle decoding error - clear profile? Sign out?
                        // self.userProfile = nil
                        // self.signOut()
                    }
                }
            }
    }

    /// Removes the active Firestore listener for the user profile.
    private func removeUserProfileListener() {
        userProfileListener?.remove()
        userProfileListener = nil
        print("User profile listener removed.")
    }

    // MARK: - Child Account Creation (Parent Functionality)

    /// Creates a new child account and links it to the current parent's family.
    /// This method is intended for use by authenticated Parent users.
    /// - Parameters:
    ///   - name: The child's display name.
    ///   - email: The email for the child's account.
    ///   - password: The password for the child's account.
    @MainActor // Ensure UI updates happen on the main thread
    func createChildAccount(name: String, email: String, password: String, parentEmail: String, parentPassword: String) async {
        guard userProfile?.role == .parent, let parentProfile = userProfile else {
            self.error = NSError(domain: "AuthViewModelError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Only parents can create child accounts."])
            print("Attempted to create child account without parent privileges.")
            return
        }

//        isLoading = true
//        error = nil
        do {
            // FirebaseService.createChildAccount handles Auth user creation, UserProfile creation, and Family update
            _ = try await FirebaseService.shared.createChildAccount(name: name, email: email, password: password, parentProfile: parentProfile)
            print("Child account created successfully.")

//            // Sign the parent back in to switch the active user back
//            _ = try await Auth.auth().signIn(withEmail: parentEmail, password: parentPassword)
//            print("Successfully signed parent \(parentProfile.id ?? "N/A") back in.")
//
//            // The auth state listener will automatically update currentUser and fetch userProfile for the parent
//
//            // Signal success for UI navigation
//            self.childAccountCreatedSuccessfully = true
        } catch {
            self.error = error
            print("Error creating child account: \(error.localizedDescription)")
        }
//        isLoading = false
    }
}
