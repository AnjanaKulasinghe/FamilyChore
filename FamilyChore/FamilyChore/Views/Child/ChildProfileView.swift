import SwiftUI
import PhotosUI // For photo selection (requires iOS 14+)
import UIKit // Explicitly import UIKit for UIImage

/// A view for a child to customize their profile.
struct ChildProfileView: View {
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    @EnvironmentObject var authViewModel: AuthViewModel // Inject AuthViewModel for sign out
    @StateObject var viewModel: ProfileViewModel // ViewModel initialized with the child's profile

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showingSaveSuccessAlert = false

    // Initialize with the ViewModel containing the child's profile
    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            Text("My Profile")
                .font(Font.theme.funLargeTitle) // Use fun font
                .foregroundColor(Color.theme.textPrimary)
                .padding()

            // TODO: Display current profile picture if available
            if let profileImage = viewModel.profilePictureImage {
                 Image(uiImage: profileImage)
                     .resizable()
                     .scaledToFill()
                     .frame(width: 100, height: 100)
                     .clipShape(Circle())
                     .padding()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .foregroundColor(.gray)
                    .padding()
            }


            // TODO: Implement photo selection/taking using PhotosPicker or similar
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images, // Only allow images
                photoLibrary: .shared() // Use the shared photo library
            ) {
                Label("Change Profile Picture", systemImage: "photo.on.rectangle.angled")
                    .font(Font.theme.callout) // Apply font
                    .foregroundColor(Color.theme.accentApp) // Style link-like text
            }
            .padding()
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            viewModel.profilePictureImage = uiImage
                        }
                    }
                }
            }

            // Editable Name Field
            TextField("Name", text: Binding( // Use binding to the name in the ViewModel's profile copy
                get: { viewModel.childProfile.name ?? "" },
                set: { viewModel.childProfile.name = $0.isEmpty ? nil : $0 }
            ))
            .font(Font.theme.headline) // Apply font
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .tint(Color.theme.accentApp)
            .foregroundColor(Color.theme.textPrimary) // Ensure text color is themed
                .padding(.top)

            // Display child's points
            Text("Points: \(viewModel.childProfile.points)")
                .font(Font.theme.headline) // Apply font
                .foregroundColor(Color.theme.textPrimary)
                .padding(.top)


            Spacer()

            if viewModel.isLoading {
                ProgressView("Saving Profile...")
                    .font(Font.theme.body) // Apply font
            } else {
                Button("Save Profile") {
                    Task {
                        await viewModel.saveProfile()
                        if viewModel.isSavedSuccessfully {
                            showingSaveSuccessAlert = true
                        }
                    }
                }
                .buttonStyle(FunkyButtonStyle()) // Apply funky style
                .padding(.horizontal)
                 // Removed manual styling modifiers
            }

            // Sign Out Button
            // Need EnvironmentObject for AuthViewModel to call signOut
            // Add @EnvironmentObject var authViewModel: AuthViewModel at the top
            Button("Sign Out") {
                 // Need to inject AuthViewModel for this action
                 authViewModel.signOut()
                 // print("Sign Out Tapped - Requires AuthViewModel")
            }
            .buttonStyle(FunkyButtonStyle(backgroundColor: .gray)) // Different style for sign out
            .padding()


            if let error = viewModel.error {
                Text(error.localizedDescription)
                    .font(Font.theme.footnote) // Apply font
                    .foregroundColor(.red)
                    .padding(.top)
            }
        }
        .appBackground() // Apply themed background
        .navigationTitle("Edit Profile")
        .alert(isPresented: $showingSaveSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Profile saved successfully!"), dismissButton: .default(Text("OK")) {
                // Optionally dismiss the view on success
                // presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ChildProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Provide a mock UserProfile and ViewModel for preview
            let mockChildProfile = UserProfile(
                id: "mockChildId",
                email: "child@example.com",
                role: .child,
                familyId: "mockFamilyId",
                profilePictureUrl: nil as String?, // Explicitly cast nil
                name: "Buddy"
            )
            ChildProfileView(viewModel: ProfileViewModel(childProfile: mockChildProfile))
        }
    }
}
