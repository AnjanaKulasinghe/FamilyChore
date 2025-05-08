import SwiftUI

/// A view displaying a reward's title, points progress, claim status, and relevant actions.
struct RewardProgressRow: View {
    // Use RewardClaim now, or pass individual properties if preferred
    let claim: RewardClaim? // Optional if displaying rewards not yet claimed
    let reward: Reward // Still need original reward for cost/title if claim is nil
    let progress: Double
    let currentPoints: Int64
    var onClaim: (() -> Void)? = nil
    var onRemind: (() -> Void)? = nil // Action for reminder

    // Determine status based on claim or progress
    private var displayStatus: ClaimStatus? { claim?.status }
    private var canClaim: Bool { progress >= 1.0 && claim == nil } // Can claim if progress full and not already claimed
    private var canRemind: Bool {
        guard let status = displayStatus else { return false }
        return (status == .pending || status == .promised) && onRemind != nil
        // Add logic here to disable reminder if promisedDate is far future or recently reminded?
    }
     private var isPromised: Bool { displayStatus == .promised }
     private var isGranted: Bool { displayStatus == .granted }


    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(reward.title).font(Font.theme.headline)
                Spacer()
                // Display current vs required points
                Text("\(currentPoints) / \(reward.requiredPoints) pts")
                    .font(Font.theme.caption1) // Adjusted font
                    .foregroundColor(Color.theme.textSecondary)
            } // End HStack

            // Show status text if claimed
            if let status = displayStatus {
                Text("Status: \(status.displayName)")
                    .font(Font.theme.caption1)
                    .foregroundColor(statusColor(status))
                    .padding(.top, 1)
                if isPromised, let date = claim?.promisedDate {
                     Text("Promised by: \(date.dateValue(), style: .date)")
                         .font(Font.theme.caption1)
                         .foregroundColor(statusColor(status))
                 }
                 if isGranted, let date = claim?.grantedAt {
                      Text("Granted on: \(date.dateValue(), style: .date)")
                          .font(Font.theme.caption1)
                          .foregroundColor(statusColor(status))
                  }
            } else {
                 // Only show progress bar if not yet claimed/granted
                 CustomProgressBar(progress: .constant(progress), height: 8)
            }


            // --- Action Buttons ---
            HStack {
                // Claim Button
                if canClaim, let claimAction = onClaim {
                    Button { claimAction() } label: {
                        Text("Claim Reward!")
                            .font(Font.theme.headline)
                            .padding(.vertical, 5).padding(.horizontal, 10)
                            .foregroundColor(Color.theme.buttonPrimaryText)
                            .background(Color.theme.buttonPrimaryBackground)
                            .cornerRadius(8)
                    }
                    .padding(.top, 5)
                }

                // Reminder Button
                if canRemind, let remindAction = onRemind {
                    Button { remindAction() } label: {
                        Label("Remind Parent", systemImage: "bell.fill")
                            .font(Font.theme.caption1) // Smaller button
                            .padding(.vertical, 3).padding(.horizontal, 6)
                            .foregroundColor(.white)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                    .padding(.top, 5)
                    // Disable if promised date is far away?
                    // .disabled(claim?.promisedDate?.dateValue() ?? .distantPast > Date() + (60*60*24*3)) // Example: disable if promised > 3 days away
                }

                // Show message if promised and reminder disabled
                 if isPromised && !canRemind, let date = claim?.promisedDate {
                     Text("Parent promised by \(date.dateValue(), style: .date)")
                         .font(.caption)
                         .foregroundColor(.blue)
                         .padding(.top, 5)
                 }

                 // Show message if granted
                  if isGranted {
                      Text("Reward Granted!")
                          .font(.caption)
                          .foregroundColor(.green)
                          .padding(.top, 5)
                  }

                Spacer() // Push buttons left if needed

            } // End HStack for buttons


        } // End VStack
        .padding(.vertical, 5) // Add some vertical padding to the row
    } // End body

     // Helper function for status color
     private func statusColor(_ status: ClaimStatus?) -> Color {
         guard let status = status else { return .gray }
         switch status {
         case .pending: return Color.theme.textSecondary
         case .reminded: return .orange
         case .promised: return .blue
         case .granted: return .green
         }
     }

} // End struct
//// Optional Preview Provider
//struct RewardProgressRow_Previews: PreviewProvider {
//    static let reward1 = Reward(id: "r1", title: "Ice Cream", requiredPoints: 100, assignedChildIds: ["c1"], createdByParentId: "p1", familyId: "f1")
//    static let reward2 = Reward(id: "r2", title: "Movie Night", requiredPoints: 50, assignedChildIds: ["c1"], createdByParentId: "p1", familyId: "f1")
//    static let childProfile = UserProfile(id: "c1", email: "c@c.com", role: .child, familyId: "f1", name: "Tester", points: 75)
//
//    static var claim1_pending: RewardClaim {
//        var claim = RewardClaim(reward: reward1, child: childProfile, familyId: "f1")
//        claim.status = .pending
//        return claim
//    }
//     static var claim1_reminded: RewardClaim {
//         var claim = RewardClaim(reward: reward1, child: childProfile, familyId: "f1")
//         claim.status = .reminded
//         claim.lastRemindedAt = Timestamp(date: Date() - (60*60*2)) // 2 hours ago
//         return claim
//     }
//    static var claim1_promised: RewardClaim {
//        var claim = RewardClaim(reward: reward1, child: childProfile, familyId: "f1")
//        claim.status = .promised
//        claim.promisedDate = Timestamp(date: Date() + (60*60*24*2)) // 2 days from now
//        return claim
//    }
//     static var claim1_granted: RewardClaim {
//         var claim = RewardClaim(reward: reward1, child: childProfile, familyId: "f1")
//         claim.status = .granted
//         claim.grantedAt = Timestamp(date: Date() - (60*60*24)) // Yesterday
//         return claim
//     }
//
//
//    static var previews: some View {
//        VStack(alignment: .leading) {
//            Text("Not Claimable (Not enough points)").font(.caption).padding(.leading)
//            RewardProgressRow(claim: nil, reward: reward1, progress: 0.75, currentPoints: 75)
//
//            Divider()
//            Text("Claimable (Enough points, not claimed)").font(.caption).padding(.leading)
//            RewardProgressRow(claim: nil, reward: reward2, progress: 1.0, currentPoints: 75, onClaim: {})
//
//             Divider()
//             Text("Claimed (Pending)").font(.caption).padding(.leading)
//             RewardProgressRow(claim: claim1_pending, reward: reward1, progress: 1.0, currentPoints: 0, onRemind: {}) // Points deducted
//
//             Divider()
//             Text("Claimed (Reminded)").font(.caption).padding(.leading)
//             RewardProgressRow(claim: claim1_reminded, reward: reward1, progress: 1.0, currentPoints: 0, onRemind: {})
//
//             Divider()
//             Text("Claimed (Promised)").font(.caption).padding(.leading)
//             RewardProgressRow(claim: claim1_promised, reward: reward1, progress: 1.0, currentPoints: 0, onRemind: {})
//
//             Divider()
//             Text("Claimed (Granted)").font(.caption).padding(.leading)
//             RewardProgressRow(claim: claim1_granted, reward: reward1, progress: 1.0, currentPoints: 0) // No actions when granted
//
//        }
//        .padding()
//        .previewLayout(.sizeThatFits)
//    }
//}
