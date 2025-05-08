import SwiftUI

/// A view for user login.
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // Access the shared AuthViewModel

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome Back!")
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

                if authViewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Login") {
                        Task {
                            await authViewModel.login(email: email, password: password)
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

                NavigationLink("Don't have an account? Sign Up") {
                    SignupView()
                }
                .font(Font.theme.callout) // Use theme font
                .foregroundColor(Color.theme.accentApp) // Style the link
                .padding()
            }
            .appBackground() // Apply themed background
            .navigationTitle("Login")
            // Consider styling navigation title if needed via appearance proxy or custom toolbar
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a mock AuthViewModel for preview
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
