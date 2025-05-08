# Family Chore & Rewards App - Project Plan

This document outlines the plan for building the SwiftUI-based Family Chore & Rewards app using Firebase.

**Tech Stack:**

*   UI: SwiftUI
*   Architecture: MVVM
*   Backend: Firebase (Firestore, Authentication, Storage)
*   Optional: Lottie / SwiftUI Animations

**User Roles:** Parent, Child

---

## Phase 1: Project Setup & Core Models

1.  **Xcode Project Initialization:**
    *   Create a new SwiftUI App project (iOS & iPadOS).
    *   Configure basic project settings.
2.  **Firebase SDK Integration:**
    *   Add `FirebaseFirestore`, `FirebaseFirestoreSwift`, `FirebaseAuth`, `FirebaseStorage` via SPM.
    *   Configure Firebase using `GoogleService-Info.plist` in `App.swift`.
3.  **Folder Structure Creation:**
    *   Create `Views/`, `ViewModels/`, `Models/`, `Firebase/`, `Utils/`.
4.  **Model Definition (`Models/`):**
    *   `UserRole.swift`: `enum UserRole: String, Codable { case parent, child }`
    *   `UserProfile.swift`: `struct UserProfile: Codable, Identifiable { var id: String; var email: String; var role: UserRole; var familyId: String?; var profilePictureUrl: String? }`
    *   `Family.swift`: `struct Family: Codable, Identifiable { @DocumentID var id: String?; var parentIds: [String]; var childIds: [String] }`
    *   `Child.swift`: `struct Child: Codable, Identifiable { var id: String; var name: String; var profilePictureUrl: String?; var points: Int = 0 }`
    *   `Task.swift`: `struct Task: Codable, Identifiable { @DocumentID var id: String?; var title: String; var description: String?; var points: Int; var imageUrl: String?; var isRecurring: Bool; var assignedChildIds: [String]; var linkedRewardIds: [String]?; var createdByParentId: String; var isCompleted: Bool = false; var proofImageUrl: String?; var status: TaskStatus = .pending }`
    *   `TaskStatus.swift`: `enum TaskStatus: String, Codable { case pending, submitted, approved, declined }`
    *   `Reward.swift`: `struct Reward: Codable, Identifiable { @DocumentID var id: String?; var title: String; var imageUrl: String?; var requiredPoints: Int; var assignedChildIds: [String]; var createdByParentId: String }`

---

## Phase 2: Authentication & Core Firebase Service

1.  **FirebaseService Setup (`Firebase/FirebaseService.swift`):**
    *   Create singleton `FirebaseService`.
    *   Initialize Auth, Firestore, Storage references.
2.  **Authentication Logic:**
    *   Implement `signUpParent(email:, password:)`.
    *   Implement `login(email:, password:)`.
    *   Implement `fetchUserProfile(userId:)`.
    *   Implement `signOut()`.
    *   Implement `createChildAccount(name:, email:, password:, parentProfile:)`.
3.  **Basic Firestore Operations:**
    *   Functions for fetching family, children, tasks, rewards.

---

## Phase 3: ViewModels & Basic Views

1.  **Auth ViewModel (`ViewModels/AuthViewModel.swift`):**
    *   Manage auth state, user profile.
    *   Call `FirebaseService` auth methods.
2.  **Login/Signup Views (`Views/Auth/`):**
    *   `LoginView.swift`
    *   `SignupView.swift` (Parent only initially).
3.  **Content View / Router (`App.swift` or `Views/ContentView.swift`):**
    *   Observe `AuthViewModel`.
    *   Route to Login/Signup or appropriate Dashboard based on auth state and role.

---

## Phase 4: Parent Flow Implementation

1.  **Parent ViewModels (`ViewModels/Parent/`):**
    *   `ParentDashboardViewModel.swift`
    *   `ManageChildrenViewModel.swift`
    *   `TaskViewModel.swift`
    *   `RewardViewModel.swift`
    *   `TaskApprovalViewModel.swift`
2.  **Parent Views (`Views/Parent/`):**
    *   `ParentDashboardView.swift`
    *   `AddChildView.swift`
    *   `CreateTaskView.swift`
    *   `CreateRewardView.swift`
    *   `TaskApprovalView.swift`
    *   `RewardProgressView.swift` (Shared/Parent)

---

## Phase 5: Child Flow Implementation

1.  **Child ViewModels (`ViewModels/Child/`):**
    *   `ChildDashboardViewModel.swift`
    *   `TaskSubmissionViewModel.swift`
    *   `ProfileViewModel.swift`
2.  **Child Views (`Views/Child/`):**
    *   `ChildDashboardView.swift`
    *   `TaskDetailView.swift`
    *   `TaskSubmissionView.swift`
    *   `RewardProgressView.swift` (Shared/Child)
    *   `ChildProfileView.swift`

---

## Phase 6: Firebase Integration & Refinements

1.  **Complete `FirebaseService`:**
    *   Implement Task/Reward CRUD.
    *   Implement `submitTask`, `approveTask`, `declineTask`.
    *   Implement Storage interactions for images.
2.  **Connect ViewModels to FirebaseService:**
    *   Wire up actions using Combine or async/await.
3.  **UI/UX Polish (`Utils/` & Views):**
    *   Implement kid-friendly design system.
    *   Add animations (SwiftUI/Lottie).
    *   Create reusable components.
4.  **Firebase Security Rules:**
    *   Define rules for Firestore and Storage to enforce permissions based on roles and family structure.

---

## Phase 7: Testing & Deployment Prep

1.  **Testing:**
    *   Unit tests.
    *   UI testing (different devices/orientations).
    *   User flow testing (Parent/Child).
    *   Edge case testing.
2.  **App Store Prep:**
    *   App Store Connect setup.
    *   Assets (icons, launch screens).
    *   Guideline compliance check.

---

## Architecture Overview (Mermaid)

```mermaid
graph LR
    subgraph "Firebase Backend"
        Auth[Firebase Auth]
        Store[Firestore Database]
        Storage[Firebase Storage]
    end

    subgraph "SwiftUI App (MVVM)"
        V[Views (SwiftUI)]
        VM[ViewModels (ObservableObject)]
        M[Models (Codable)]
        FS[FirebaseService (Singleton)]
        Utils[Utilities]
    end

    V --> VM
    VM --> FS
    VM --> M
    FS --> Auth
    FS --> Store
    FS --> Storage
    FS --> M
    V --> Utils
    VM --> Utils