import SwiftUI
import PhotosUI // Import for PhotosPicker

/// A view for parents to create a new task.
struct CreateTaskView: View {
    @EnvironmentObject var authViewModel: AuthViewModel // To get parent's ID and family ID
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    // ViewModel is now injected, allowing for both creation and editing
    @StateObject var viewModel: TaskViewModel

    @State private var showingSuccessAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil // For PhotosPicker

    // Initializer to accept the ViewModel
    init(viewModel: TaskViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView { // Added ScrollView
            VStack {
                // Removed redundant large title Text view
                // If you want a title here, use:
                // Text(viewModel.task.id == nil ? "Create New Task" : "Edit Task")
                //    .font(Font.theme.funLargeTitle)
                //    .foregroundColor(Color.theme.textPrimary)
                //    .padding()

                TextField("Task Title", text: $viewModel.task.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(Font.theme.body) // Apply font
                .tint(Color.theme.accentApp) // Apply tint

            TextField("Description", text: $viewModel.task.description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .font(Font.theme.body) // Apply font
                .tint(Color.theme.accentApp) // Apply tint

            HStack {
                Text("Points:")
                    .font(Font.theme.body) // Apply font
                    .foregroundColor(Color.theme.textSecondary)
                TextField("Points", value: $viewModel.task.points, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(Font.theme.body) // Apply font
                    .tint(Color.theme.accentApp) // Apply tint
            }
            .padding(.horizontal)

            Toggle("Recurring Task", isOn: $viewModel.task.isRecurring)
                .padding(.horizontal)
                .font(Font.theme.body) // Apply font
                .tint(Color.theme.accentApp) // Apply tint to Toggle
            
                        // Section for Task Image Picker
                        Section(header: Text("Task Image (Optional)").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) { // Style header
                            VStack {
                                if let selectedImage = viewModel.selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 50) // Reduced height
                                        .cornerRadius(8)
                                } else if let imageUrlString = viewModel.task.imageUrl, let imageUrl = URL(string: imageUrlString) {
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
                                    matching: .images,
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
                    Text("No children available to assign tasks.")
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
                                Image(systemName: viewModel.task.assignedChildIds.contains(child.id!) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.task.assignedChildIds.contains(child.id!) ? .blue : .gray)
                                    .onTapGesture {
                                        if let childId = child.id {
                                            viewModel.toggleChildAssignment(childId: childId)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(viewModel.availableChildren.count) * 100, 200)) // Increased max height
                }
            }
            .padding(.horizontal)

            Section(header: Text("Link to Rewards (Required)").font(Font.theme.headline).foregroundColor(Color.theme.textSecondary)) { // Style header
                if viewModel.isLoading {
                    ProgressView("Loading Rewards...")
                        .font(Font.theme.body) // Apply font
                } else if let error = viewModel.error, viewModel.availableRewards.isEmpty { // Show error only if rewards failed to load
                    Text("Error loading rewards: \(error.localizedDescription)")
                        .font(Font.theme.footnote) // Apply font
                        .foregroundColor(.red)
                } else if viewModel.availableRewards.isEmpty {
                    Text("No rewards available to link. Please create a reward first.")
                        .font(Font.theme.body) // Apply font
                        .foregroundColor(Color.theme.textSecondary)
                } else {
                    List {
                        ForEach(viewModel.availableRewards) { reward in
                            HStack {
                                Text(reward.title)
                                    .font(Font.theme.body) // Apply font
                                    .foregroundColor(Color.theme.textPrimary)
                                Spacer()
                                Image(systemName: viewModel.task.linkedRewardIds.contains(reward.id!) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.task.linkedRewardIds.contains(reward.id!) ? .blue : .gray)
                                    .onTapGesture {
                                        if let rewardId = reward.id {
                                            viewModel.toggleRewardLinking(rewardId: rewardId)
                                        }
                                    }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(viewModel.availableRewards.count) * 100, 200)) // Limit list height
                }
            }
            .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView("Saving Task...")
                    .font(Font.theme.body) // Apply font
            } else {
                Button(viewModel.task.id == nil ? "Create Task" : "Update Task") {
                    // Ensure parent ID is available before saving
                    if let parentId = authViewModel.currentUser?.uid, let familyId = authViewModel.userProfile?.familyId {
                        Task {
                            await viewModel.saveTask(createdBy: parentId, familyId: familyId)
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
                        viewModel.error = NSError(domain: "CreateTaskViewError", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    }
                }
                .buttonStyle(FunkyButtonStyle()) // Use default funky style
                .padding(.horizontal)
                // Removed manual styling modifiers
            }

            // Display validation error specifically for reward linking
            if let error = viewModel.error, error.localizedDescription == "A task must be linked to at least one reward.", !viewModel.isLoading {
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
        .navigationTitle(viewModel.task.id == nil ? "Create Task" : "Edit Task")
        .onAppear {
            // Fetch available children when the view appears
            if let familyId = authViewModel.userProfile?.familyId {
                Task {
                    await viewModel.fetchAvailableChildren(forFamily: familyId)
                    await viewModel.fetchAvailableRewards(forFamily: familyId) // Fetch rewards as well
                }
            } else {
                // Handle case where parent profile doesn't have a familyId
                viewModel.error = NSError(domain: "CreateTaskViewError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Parent profile missing family ID."])
            }
        }
        .alert(isPresented: $showingSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Task saved successfully!"), dismissButton: .default(Text("OK")) {
                presentationMode.wrappedValue.dismiss() // Dismiss the view on success
            })
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.selectedImage = UIImage(data: data)
                }
            }
        }
    }
}

//struct CreateTaskView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            // Provide mock data for preview
//            CreateTaskView()
//                .environmentObject(AuthViewModel()) // Provide a mock AuthViewModel
//        }
//    }
//}
