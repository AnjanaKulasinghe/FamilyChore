import SwiftUI
import PhotosUI

/// A view for parents to edit their profile.
struct ParentProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel // Needed for sign out and getting profile
    @StateObject var viewModel: ProfileViewModel // ViewModel initialized with the parent's profile

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showingSaveSuccessAlert = false

    // Initialize with the ViewModel containing the parent's profile
    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            Text("My Profile")
                .font(Font.theme.funLargeTitle)
                .foregroundColor(Color.theme.textPrimary)
                .padding()

            // Profile Picture Section
            VStack {
                 if let profileImage = viewModel.profilePictureImage {
                     Image(uiImage: profileImage)
                         .resizable().scaledToFill()
                         .frame(width: 100, height: 100).clipShape(Circle())
                         .padding(.bottom, 5)
                 } else if let imageUrlString = viewModel.childProfile.profilePictureUrl, let imageUrl = URL(string: imageUrlString) {
                     // Reusing childProfile property name, but it holds parent profile here
                     AsyncImage(url: imageUrl) { phase in
                         switch phase {
                         case .success(let image):
                             image.resizable().scaledToFill()
                                  .frame(width: 100, height: 100).clipShape(Circle())
                                  .padding(.bottom, 5)
                         case .failure, .empty:
                             defaultProfileIcon
                         @unknown default:
                             defaultProfileIcon
                         }
                     }
                 } else {
                     defaultProfileIcon
                 }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Change Profile Picture", systemImage: "photo.on.rectangle.angled")
                        .font(Font.theme.callout)
                        .foregroundColor(Color.theme.accentApp)
                }
            }
            .padding()
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.profilePictureImage = uiImage // Update local preview
                    }
                }
            }

            // Editable Name Field
            TextField("Name", text: Binding( // Use binding to the name in the ViewModel's profile copy
                get: { viewModel.childProfile.name ?? "" },
                set: { viewModel.childProfile.name = $0.isEmpty ? nil : $0 }
            ))
            .font(Font.theme.headline)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .tint(Color.theme.accentApp)


            Spacer() // Push content up

            // Save Button
            if viewModel.isLoading {
                ProgressView("Saving Profile...")
                    .font(Font.theme.body)
            } else {
                Button("Save Profile") {
                    Task {
                        await viewModel.saveProfile() // ViewModel handles name and picture update
                        if viewModel.isSavedSuccessfully {
                            showingSaveSuccessAlert = true
                        }
                    }
                }
                .buttonStyle(FunkyButtonStyle())
                .padding(.horizontal)
            }

            // Sign Out Button
            Button("Sign Out") {
                authViewModel.signOut()
            }
            .buttonStyle(FunkyButtonStyle(backgroundColor: .gray)) // Different style for sign out
            .padding()


            if let error = viewModel.error {
                Text(error.localizedDescription)
                    .font(Font.theme.footnote)
                    .foregroundColor(.red)
                    .padding(.top)
            }
        }
        .appBackground()
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline) // Keep title inline
        .alert(isPresented: $showingSaveSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Profile saved successfully!"), dismissButton: .default(Text("OK")))
        }
        // Fetch initial image when view appears if needed (ViewModel might handle this)
        .onAppear {
             // If ViewModel doesn't load initial image, do it here
             // viewModel.loadInitialImage()
        }
    }

    // Helper view for default icon
    private var defaultProfileIcon: some View {
        Image(systemName: "person.circle.fill")
            .resizable().scaledToFill()
            .frame(width: 100, height: 100).clipShape(Circle())
            .foregroundColor(.gray)
            .padding(.bottom, 5)
    }
}
