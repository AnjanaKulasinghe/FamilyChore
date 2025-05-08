import SwiftUI

/// A view for adding a co-parent by email.
struct AddCoParentView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel // To get current family ID
    @StateObject private var viewModel = AddCoParentViewModel() // Reverted ViewModel
    
    var body: some View {
        NavigationView {
            ZStack { // Wrap in ZStack for loading overlay
                Form {
                    Section(header: Text("Link Existing Co-Parent Account").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) {
                        
                        Text("Enter the email address of the parent you wish to add. They must have already signed up for their own account using the app's main Sign Up screen.")
                            .font(Font.theme.footnote)
                            .foregroundColor(Color.theme.textSecondary)
                            .padding(.bottom, 5)
                        
                        TextField("Co-parent's email address", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(Font.theme.body)
                            .tint(Color.theme.accentApp)
                    }
                    
                    Section {
                        Button {
                            Task {
                                // Use the reverted link function in ViewModel
                                let success = await viewModel.linkCoParentAccount(familyId: authViewModel.userProfile?.familyId)
                                if success {
                                    // Optionally delay dismissal to show success message
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                                // Error/Success messages are handled by observing viewModel properties below
                            }
                        } label: {
                            Text("Link Co-Parent Account")
                                .font(Font.theme.headline)
                        }
                        .buttonStyle(FunkyButtonStyle())
                        .disabled(viewModel.email.isEmpty || viewModel.isLoading) // Disable if no email or loading
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.clear)
                    
                    // Display Status Messages
                    if let message = viewModel.successMessage {
                        Text(message)
                            .font(Font.theme.footnote)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top)
                    } else if let message = viewModel.errorMessage {
                        Text(message)
                            .font(Font.theme.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top)
                    }
                    
                } // End Form
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .appBackground()
                .disabled(viewModel.isLoading) // Disable form while loading
                .navigationTitle("Link Co-Parent") // Updated title
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(Font.theme.body)
                        .foregroundColor(Color.theme.accentApp)
                    }
                }
                // Removed onChange for photo picker as it's not needed now
                
                // Loading Overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Linking Account...") // Updated text
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .font(Font.theme.body)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
                
            } // End ZStack
        } // End body
    }
}
// Removed ProfilePicturePickerSection as it's not needed for linking

// Add mock if needed for preview
// extension AuthViewModel {
//     static var mock: AuthViewModel {
//         let vm = AuthViewModel()
//         vm.userProfile = UserProfile(id: "parent1", email: "parent@test.com", role: .parent, familyId: "fam1", name: "Test Parent")
//         vm.currentUser = MockFirebaseUser(uid: "parent1")
//         vm.isLoading = false
//         return vm
//     }
// }
// struct MockFirebaseUser { let uid: String } // Define if not elsewhere

