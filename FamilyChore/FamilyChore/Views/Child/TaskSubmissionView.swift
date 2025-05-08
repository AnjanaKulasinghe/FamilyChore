import SwiftUI
import PhotosUI // For photo selection (requires iOS 14+)

/// A view for a child to submit a completed task with optional photo proof.
struct TaskSubmissionView: View {
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    @StateObject var viewModel: TaskSubmissionViewModel // ViewModel initialized with the task

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showingSubmissionSuccessAlert = false

    // Initialize with the ViewModel containing the task
    init(viewModel: TaskSubmissionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            let task = viewModel.task
                Text("Submit Task: \(task.title)")
                    .font(Font.theme.title1) // Use theme font
                    .foregroundColor(Color.theme.textPrimary)
                    .padding()

                    Text("Description: \(task.description)")
                        .font(Font.theme.body) // Use theme font
                        .foregroundColor(Color.theme.textSecondary)
                        .padding(.horizontal)

                Text("Points to earn: \(task.points)")
                    .font(Font.theme.headline) // Use theme font
                    .foregroundColor(Color.theme.textPrimary)
                    .padding(.top)

                Spacer()

                // Photo Proof Section
                Text("Photo Proof (Optional)")
                    .font(Font.theme.headline) // Use theme font
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(.bottom)

                if let photo = viewModel.photoProof {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.horizontal)
                } else {
                    // TODO: Implement photo selection/taking using PhotosPicker or similar
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images, // Only allow images
                        photoLibrary: .shared() // Use the shared photo library
                    ) {
                        Label("Select Photo", systemImage: "photo.on.rectangle.angled")
                            .font(Font.theme.callout) // Apply font
                    }
                    .padding()
                    .onChange(of: selectedPhotoItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                if let uiImage = UIImage(data: data) {
                                    viewModel.photoProof = uiImage
                                }
                            }
                        }
                    }
                }

                Spacer()

                if viewModel.isLoading {
                    ProgressView("Submitting...")
                        .font(Font.theme.body) // Apply font
                } else {
                    Button("Submit Task") {
                        Task {
                            await viewModel.submitTask()
                            if viewModel.isSubmittedSuccessfully {
                                showingSubmissionSuccessAlert = true
                            }
                        }
                    }
                    .buttonStyle(FunkyButtonStyle()) // Apply funky style
                    .padding(.horizontal)
                    // Removed manual styling
                }

                if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .font(Font.theme.footnote) // Apply font
                        .foregroundColor(.red)
                        .padding(.top)
                }
        }
        .appBackground() // Apply themed background
        .navigationTitle("Submit Task")
        .alert(isPresented: $showingSubmissionSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Task submitted for approval!"), dismissButton: .default(Text("OK")) {
                presentationMode.wrappedValue.dismiss() // Dismiss the view on success
            })
        }
    }
}
