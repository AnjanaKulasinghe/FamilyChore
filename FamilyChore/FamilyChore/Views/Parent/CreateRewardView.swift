import SwiftUI
import PhotosUI // Import for PhotosPicker

/// A view for parents to create a new reward.
struct CreateRewardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To get parent's ID and family ID
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    // ViewModel is now injected, allowing for both creation and editing
    @StateObject var viewModel: RewardViewModel

    @State private var showingSuccessAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil // For PhotosPicker

    // Initializer to accept the ViewModel
    init(viewModel: RewardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView { // Re-add ScrollView
            VStack {
                // Removed redundant title Text view again, rely on navigationTitle
                // Text(viewModel.reward.id == nil ? "Create New Reward" : "Edit Reward")
                //    .font(Font.theme.funLargeTitle) // Use fun font
                //    .foregroundColor(Color.theme.textPrimary)
                //    .padding()

                TextField("Reward Title", text: $viewModel.reward.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(Font.theme.body) // Apply font
                .tint(Color.theme.accentApp) // Apply tint

            HStack {
                Text("Required Points:")
                    .font(Font.theme.body) // Apply font
                    .foregroundColor(Color.theme.textSecondary)
                TextField("Points", value: $viewModel.reward.requiredPoints, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(Font.theme.body) // Apply font
                    .tint(Color.theme.accentApp) // Apply tint
            }
            .padding(.horizontal)

            // Section for Image Picker
            Section(header: Text("Reward Image").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) { // Style header
                VStack {
                    if let selectedImage = viewModel.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50) // Reduced height
                            .cornerRadius(8)
                    } else if let imageUrlString = viewModel.reward.imageUrl, let imageUrl = URL(string: imageUrlString) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 50) // Reduced height
                            case .success(let image):
                                image.resizable()
                                     .scaledToFit()
                                     .frame(height: 50) // Reduced height
                                     .cornerRadius(8)
                            case .failure:
                                Image(systemName: "photo.fill") // Placeholder for failure
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 50) // Reduced height
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                                    .frame(height: 50) // Reduced height
                            }
                        }
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50) // Consistent height for placeholder
                            .foregroundColor(.gray)
                            .padding(.bottom, 10)
                        Text("No image selected")
                            .font(Font.theme.caption1) // Apply font
                            .foregroundColor(.gray)
                    }

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images, // Only allow images
                        photoLibrary: .shared()
                    ) {
                        Label("Select Image", systemImage: "photo.on.rectangle")
                            .font(Font.theme.callout) // Apply font
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .padding(.horizontal)


            Section(header: Text("Assign to Children").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) { // Style header
                if viewModel.isLoading {
                    ProgressView("Loading Children...")
                        .font(Font.theme.body) // Apply font
                } else if let error = viewModel.error {
                    Text("Error loading children: \(error.localizedDescription)")
                        .font(Font.theme.footnote) // Apply font
                        .foregroundColor(.red)
                } else if viewModel.availableChildren.isEmpty {
                    Text("No children available to assign rewards.")
                        .font(Font.theme.body) // Apply font
                        .foregroundColor(Color.theme.textSecondary)
                } else {
                    List {
                        ForEach(viewModel.availableChildren) { child in
                            HStack {
                                Text(child.name ?? "Unnamed Child")
                                    .font(Font.theme.body) // Apply font
                                    .foregroundColor(Color.theme.textPrimary)
                                Spacer()
                                Image(systemName: viewModel.reward.assignedChildIds.contains(child.id!) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.reward.assignedChildIds.contains(child.id!) ? .blue : .gray)
                                    .onTapGesture {
                                        if let childId = child.id {
                                            viewModel.toggleChildAssignment(childId: childId)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(viewModel.availableChildren.count) * 100, 200)) // Limit list height
                }
            }
            .padding(.horizontal)
            

            if viewModel.isLoading {
                ProgressView("Saving Reward...")
                    .font(Font.theme.body) // Apply font
            } else {
                Button(viewModel.reward.id == nil ? "Create Reward" : "Update Reward") {
                    // Ensure parent ID is available before saving
                    if let parentId = authViewModel.currentUser?.uid, let familyId = authViewModel.userProfile?.familyId {
                        Task {
                            await viewModel.saveReward(createdBy: parentId, familyId: familyId)
                            if viewModel.isSavedSuccessfully {
                                showingSuccessAlert = true
                            }
                        }
                    } else {
                        // Handle case where parent ID or family ID is missing
                        var errorMessage = "Parent user not authenticated."
                        if authViewModel.currentUser?.uid != nil && authViewModel.userProfile?.familyId == nil {
                            errorMessage = "Family ID not found for the current user."
                        }
                        viewModel.error = NSError(domain: "CreateRewardViewError", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    }
                }
                .buttonStyle(FunkyButtonStyle()) // Use default funky style
                .padding(.horizontal)
                // Removed manual styling modifiers
            }

            if let error = viewModel.error, !viewModel.isLoading {
                Text(error.localizedDescription)
                    .font(Font.theme.footnote) // Apply font
                    .foregroundColor(.red)
                    .padding(.top)
            }

            Spacer() // Spacer might be less effective inside ScrollView depending on content length
            Spacer() // Spacer might be less effective inside ScrollView depending on content length
            } // End of VStack
            .padding(.top) // Add padding between nav title and content
        } // End of ScrollView
        .appBackground()
        .navigationTitle(viewModel.reward.id == nil ? "Create Reward" : "Edit Reward")
        .onAppear {
            // Fetch available children when the view appears
            if let familyId = authViewModel.userProfile?.familyId {
                Task {
                    await viewModel.fetchAvailableChildren(forFamily: familyId)
                }
            } else {
                // Handle case where parent profile doesn't have a familyId
                viewModel.error = NSError(domain: "CreateRewardViewError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Parent profile missing family ID."])
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.selectedImage = UIImage(data: data)
                }
            }
        }
        .alert(isPresented: $showingSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Reward saved successfully!"), dismissButton: .default(Text("OK")) {
                presentationMode.wrappedValue.dismiss() // Dismiss the view on success
            })
        }
    }
}

//struct CreateRewardView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            // Provide mock data for preview
//            CreateRewardView(viewModel: <#RewardViewModel#>)
//                .environmentObject(AuthViewModel()) // Provide a mock AuthViewModel
//        }
//    }
//}
