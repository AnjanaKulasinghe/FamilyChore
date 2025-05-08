import SwiftUI

/// A view for parents to add a new child account to their family.
struct AddChildView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To get parent's profile
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    @StateObject var viewModel = ManageChildrenViewModel() // ViewModel for child management

    @State private var childName = ""
    @State private var childEmail = ""
    @State private var childPassword = ""
    @State private var showingSuccessAlert = false

    var body: some View {
        VStack {
            Text("Add New Child")
                .font(Font.theme.funLargeTitle) // Use fun font
                .foregroundColor(Color.theme.textPrimary) // Use theme color
                .padding()

            TextField("Child's Name", text: $childName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(Font.theme.body) // Apply font
                .tint(Color.theme.accentApp) // Tint cursor/selection

            TextField("Child's Email", text: $childEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .font(Font.theme.body) // Apply font
                .tint(Color.theme.accentApp) // Tint cursor/selection

            SecureField("Child's Password", text: $childPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(Font.theme.body) // Apply font
                .tint(Color.theme.accentApp) // Tint cursor/selection

            if viewModel.isLoading {
                ProgressView("Adding Child...")
                    .font(Font.theme.body) // Apply font
            } else {
                Button("Add Child") {
                    // Ensure parent profile is available before creating child account
                    if let parentProfile = authViewModel.userProfile {
                        Task {
                            await viewModel.createChildAccount(name: childName, email: childEmail, password: childPassword, parentProfile: parentProfile)
                            if viewModel.error == nil {
                                showingSuccessAlert = true
                            }
                        }
                    } else {
                        // Handle case where parent profile is missing (shouldn't happen if routed correctly)
                        viewModel.error = NSError(domain: "AddChildViewError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Parent profile not available."])
                    }
                }
                .buttonStyle(FunkyButtonStyle()) // Apply funky style
                .padding(.horizontal)
                // Removed manual styling modifiers
            }

            if let error = viewModel.error {
                Text(error.localizedDescription)
                    .font(Font.theme.footnote) // Apply font
                    .foregroundColor(.red)
                    .padding(.top)
            }

            Spacer()
        }
        .appBackground() // Apply themed background
        .navigationTitle("Add Child")
        .navigationBarTitleDisplayMode(.inline) // Use inline title
        .alert(isPresented: $showingSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Child account created successfully!"), dismissButton: .default(Text("OK")) {
                presentationMode.wrappedValue.dismiss() // Dismiss the view on success
            })
        }
    }
}

struct AddChildView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Provide mock data for preview
            AddChildView()
                .environmentObject(AuthViewModel()) // Provide a mock AuthViewModel
        }
    }
}