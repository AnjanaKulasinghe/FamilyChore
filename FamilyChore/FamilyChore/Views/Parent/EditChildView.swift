import SwiftUI
import PhotosUI // Import for PhotosPicker

/// A view for editing a child's profile.
struct EditChildView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var manageChildrenViewModel: ManageChildrenViewModel // Assuming ManageChildrenViewModel is provided as an environment object
    
    @State private var childProfile: UserProfile // State to hold the editable child profile
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    
    init(childProfile: UserProfile) {
        _childProfile = State(initialValue: childProfile)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Child Details").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) { // Style header
                    TextField("Name", text: Binding(
                        get: { childProfile.name ?? "" },
                        set: { childProfile.name = $0.isEmpty ? nil : $0 }
                    ))
                    .font(Font.theme.body) // Apply font
                    .tint(Color.theme.accentApp) // Tint cursor/selection
                    // Add other editable fields here if needed
                }

                // Extracted Profile Picture Section
                ProfilePictureSection(
                    selectedPhotoItem: $selectedPhotoItem,
                    selectedUIImage: $selectedUIImage,
                    profilePictureUrl: $childProfile.profilePictureUrl // Pass binding
                )

                Section {
                    Button("Save Changes") {
                        Task {
                            await manageChildrenViewModel.updateChildProfile(childProfile, newProfileImage: selectedUIImage)
                            presentationMode.wrappedValue.dismiss() // Dismiss view after saving
                        }
                    }
                    .buttonStyle(FunkyButtonStyle()) // Apply default style (uses accent color by default)
                    .frame(maxWidth: .infinity, alignment: .center) // Center button within section
                }
                .listRowBackground(Color.clear) // Make section background clear if needed
                
                // Removed the separate "Remove Child" button section
                
            } // End of Form
            .scrollContentBackground(.hidden) // Make Form background transparent (iOS 16+)
            .background(Color.clear) // Fallback/alternative for Form background
            .appBackground() // Apply themed background behind the Form
            .navigationTitle("Edit Child")
            .navigationBarTitleDisplayMode(.inline) // Use inline title to reduce top space
            // Removed explicit Cancel button; rely on back navigation
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedUIImage = UIImage(data: data)
                    }
                }
            }
        } // End of NavigationView
    } // End of body
}

// MARK: - Subviews

private struct ProfilePictureSection: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedUIImage: UIImage?
    @Binding var profilePictureUrl: String? // Use binding to existing URL

    var body: some View {
        Section(header: Text("Profile Picture").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) { // Style header
            VStack {
                if let selectedImage = selectedUIImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let imageUrlString = profilePictureUrl, let imageUrl = URL(string: imageUrlString) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case .success(let image):
                            image.resizable()
                                 .scaledToFill()
                                 .frame(width: 100, height: 100)
                                 .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                                .frame(width: 100, height: 100)
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Change Profile Picture")
                        .font(Font.theme.callout) // Apply font
                        .foregroundColor(Color.theme.accentApp)
                }
                .padding(.top)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}


struct EditChildView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock data for preview
        EditChildView(childProfile: UserProfile(id: "mock_child_id", email: "child@example.com", role: .child, familyId: "mock_family_id", name: "Mock Child"))
            .environmentObject(ManageChildrenViewModel()) // Provide a mock ViewModel
    }
}
