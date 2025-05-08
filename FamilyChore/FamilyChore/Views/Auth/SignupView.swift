import SwiftUI

/// A view for user signup (specifically for Parents initially).
struct SignupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Access the shared AuthViewModel
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPasswordMismatchAlert = false

    var body: some View {
        VStack {
            Text("Join the Family!")
                .font(Font.theme.funLargeTitle) // Use fun font for main title
                .foregroundColor(Color.theme.textPrimary) // Use theme color
                .padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .font(Font.theme.body) // Use theme font
                .tint(Color.theme.accentApp) // Tint cursor/selection

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(Font.theme.body) // Use theme font
                .tint(Color.theme.accentApp) // Tint cursor/selection

            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(Font.theme.body) // Use theme font
                .tint(Color.theme.accentApp) // Tint cursor/selection

            if authViewModel.isLoading {
                ProgressView()
            } else {
                Button("Sign Up as Parent") {
                    if password != confirmPassword {
                        showingPasswordMismatchAlert = true
                    } else {
                        Task {
                            await authViewModel.signUpParent(email: email, password: password)
                            // Dismiss view on successful signup (Auth state listener handles navigation)
                            if authViewModel.error == nil {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
                .buttonStyle(FunkyButtonStyle()) // Apply funky style
                .padding(.horizontal)
                 // Removed manual styling modifiers
            }

            if let error = authViewModel.error {
                Text(error.localizedDescription)
                    .font(Font.theme.footnote) // Use theme font
                    .foregroundColor(.red)
                    .padding(.top)
            }

            Spacer()
        }
        .appBackground() // Apply themed background
        .navigationTitle("Sign Up")
        .alert(isPresented: $showingPasswordMismatchAlert) {
            Alert(title: Text("Error"), message: Text("Passwords do not match."), dismissButton: .default(Text("OK")))
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Provide a mock AuthViewModel for preview
            SignupView()
                .environmentObject(AuthViewModel())
        }
    }
}