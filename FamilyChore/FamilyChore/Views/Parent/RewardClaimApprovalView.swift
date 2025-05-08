import SwiftUI

/// A view for parents to review and manage a claimed reward.
struct RewardClaimApprovalView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: RewardClaimApprovalViewModel

    // State for alert confirmation
    @State private var showingConfirmationAlert = false
    @State private var confirmationTitle = ""
    @State private var confirmationMessage = ""

    init(rewardClaim: RewardClaim) {
        _viewModel = StateObject(wrappedValue: RewardClaimApprovalViewModel(rewardClaim: rewardClaim))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if viewModel.isLoading {
                ProgressView("Updating Claim...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }

            // --- Claim Details ---
            // Removed Group wrapper
            Text(viewModel.rewardClaim.rewardTitle)
                .font(Font.theme.funLargeTitle)
            Text("Claimed by: \(viewModel.rewardClaim.childName ?? "Unknown Child")")
                    .font(Font.theme.headline)
                Text("Cost: \(viewModel.rewardClaim.rewardCost) points")
                    .font(Font.theme.subheadline)
                Text("Claimed On: \(viewModel.rewardClaim.claimedAt.dateValue(), style: .date)")
                    .font(Font.theme.caption1)
                Text("Status: \(viewModel.rewardClaim.status.displayName)")
                    .font(Font.theme.headline)
                    .foregroundColor(statusColor(viewModel.rewardClaim.status))

                if viewModel.rewardClaim.status == .reminded, let remindedAt = viewModel.rewardClaim.lastRemindedAt {
                    Text("Last Reminder: \(remindedAt.dateValue(), style: .date)")
                        .font(Font.theme.caption1)
                        .foregroundColor(.orange)
                }
                
                if viewModel.rewardClaim.status == .promised, let promisedDate = viewModel.rewardClaim.promisedDate {
                     Text("Promised Fulfillment Date: \(promisedDate.dateValue(), style: .date)")
                         .font(Font.theme.caption1)
                         .foregroundColor(.blue)
                 }
                 
                 if viewModel.rewardClaim.status == .granted, let grantedAt = viewModel.rewardClaim.grantedAt {
                      Text("Granted On: \(grantedAt.dateValue(), style: .date)")
                          .font(Font.theme.caption1)
                          .foregroundColor(.green)
                  }



            Spacer() // Push actions to bottom

            // --- Actions ---
            if viewModel.rewardClaim.status == .pending || viewModel.rewardClaim.status == .reminded {
                // Promise Section
                VStack {
                    Divider()
                    Text("Promise Fulfillment Date:").font(Font.theme.headline)
                    DatePicker(
                        "Select Date",
                        selection: $viewModel.promiseDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact) // Or .graphical
                    .labelsHidden()

                    Button("Promise Reward") {
                        Task {
                            await viewModel.promiseReward()
                            if viewModel.operationSuccessful {
                                confirmationTitle = "Reward Promised"
                                confirmationMessage = "You promised to fulfill '\(viewModel.rewardClaim.rewardTitle)' by \(viewModel.promiseDate.formatted(date: .long, time: .omitted))."
                                showingConfirmationAlert = true
                            }
                        }
                    }
                    .buttonStyle(FunkyButtonStyle(backgroundColor: .blue))
                    .disabled(viewModel.isLoading)
                    .padding(.bottom)
                }
                .padding(.horizontal)
            }

            if viewModel.rewardClaim.status != .granted {
                 // Grant Button (available unless already granted)
                 Button("Mark as Granted") {
                     Task {
                         await viewModel.grantReward()
                          if viewModel.operationSuccessful {
                              confirmationTitle = "Reward Granted!"
                              confirmationMessage = "'\(viewModel.rewardClaim.rewardTitle)' has been marked as granted."
                              showingConfirmationAlert = true
                          }
                     }
                 }
                 .buttonStyle(FunkyButtonStyle(backgroundColor: .green))
                 .disabled(viewModel.isLoading)
                 .padding(.horizontal)
                 .padding(.bottom) // Add padding below grant button
            } // End Grant Button Condition


        } // End Main VStack
        .padding(.top) // Add padding at the top
        .appBackground()
        .navigationTitle("Manage Claim")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingConfirmationAlert) {
            Alert(
                title: Text(confirmationTitle),
                message: Text(confirmationMessage),
                dismissButton: .default(Text("OK")) {
                    // Optionally dismiss view after confirmation
                    // presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    private func statusColor(_ status: ClaimStatus) -> Color {
        switch status {
        case .pending: return Color.theme.textSecondary
        case .reminded: return .orange
        case .promised: return .blue
        case .granted: return .green
        }
    }
}

// Preview needs a mock RewardClaim
struct RewardClaimApprovalView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock data
        let mockReward = Reward(id: "r1", title: "Preview Reward", requiredPoints: 100, assignedChildIds: ["c1"], createdByParentId: "p1", familyId: "f1")
        let mockChild = UserProfile(id: "c1", email: "c@c.com", role: .child, familyId: "f1", name: "Test Child", points: 150)
        let mockClaim = RewardClaim(reward: mockReward, child: mockChild, familyId: "f1")
        // mockClaim.status = .reminded // Example status

        return NavigationView {
            RewardClaimApprovalView(rewardClaim: mockClaim)
        }
    }
}
