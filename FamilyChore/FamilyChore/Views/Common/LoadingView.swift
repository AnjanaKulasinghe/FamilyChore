import SwiftUI

/// A view displayed briefly when the app starts.
struct LoadingView: View {
    var onLoadingFinished: () -> Void // Completion handler
    let displayDuration: TimeInterval = 2.0 // Duration in seconds (adjust as needed)
    @State private var imageOpacity: Double = 0.0
    @State private var elementsOpacity: Double = 0.0 // For text and progress bar
    @State private var progress: Double = 0.0
    @State private var progressTimer: Timer? // To control the progress animation

    // Suggested App Name (can be changed)
    let appName = "ChoreQuest Rewards"

    var body: some View {
        ZStack {
            // Use the themed background
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 30) { // Added spacing
                Spacer() // Push content towards center

                // Display the loading screen image asset
                Image("Loading_Screen") // Make sure this asset exists!
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // Adjust size as needed
                    .padding(.bottom, 20)
                    .opacity(imageOpacity)

                // Display the App Name
                Text(appName)
                    .font(Font.theme.funLargeTitle) // Use the fun font
                    .foregroundColor(Color.theme.textPrimary)
                    .opacity(elementsOpacity)

                // Custom Progress Bar
                CustomProgressBar(progress: $progress)
                    .frame(width: 200, height: 12) // Adjust size as needed
                    .opacity(elementsOpacity)
                    .padding(.top, 10) // Add some space above progress bar


                Spacer() // Push content towards center
                Spacer() // Add more space at the bottom if needed
            }
        }
        .onAppear {
            // Start a timer to transition after the duration
            // print("LoadingView: .onAppear, scheduling timers.") // Removed

            // Animate image opacity
            withAnimation(.easeIn(duration: 0.8)) {
                imageOpacity = 1.0
            }

            // Animate other elements slightly later and start progress bar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Stagger the animation
                withAnimation(.easeIn(duration: 0.8)) {
                    elementsOpacity = 1.0
                }
                startProgressBar()
            }

            // Timer to finish loading and transition (overall duration)
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                // print("LoadingView: Main display timer finished, attempting to set isLoadingFinished = true") // Removed
                progressTimer?.invalidate() // Stop the progress bar timer
                progressTimer = nil
                // Ensure progress is full if timer finishes early
                withAnimation(.linear) { progress = 1.0 }


                // Optional: Add a fade-out animation for the whole view
                withAnimation(.easeOut(duration: 0.3)) { // Shorter fade out
                    // To fade out the whole view, you might need another opacity state for the ZStack
                    // For now, direct transition is fine.
                    onLoadingFinished() // Call the completion handler
                }
                // print("LoadingView: onLoadingFinished called") // Removed
            }
        }
        .onDisappear {
            progressTimer?.invalidate() // Clean up timer if view disappears early
            progressTimer = nil
        }
    }

    private func startProgressBar() {
        progressTimer?.invalidate()
        progressTimer = nil
        progress = 0.0

        // Timer fires more frequently for dynamic updates
        let updateInterval = 0.15 // seconds; adjust for desired "granularity" of movement

        progressTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [self] timer in
            guard self.progress < 1.0 else {
                timer.invalidate()
                self.progressTimer = nil
                return
            }

            // Random chance to pause or advance
            if Double.random(in: 0...1) < 0.75 { // 75% chance to advance
                let randomIncrement = Double.random(in: 0.03...0.08) // Random small jump
                
                // Ensure progress doesn't overshoot due to a large randomIncrement near the end
                if self.progress + randomIncrement > 1.0 {
                    self.progress = 1.0
                } else {
                    self.progress += randomIncrement
                }
                
            } // else 25% chance to pause (do nothing this tick)

            // Ensure progress doesn't exceed 1.0 (redundant if logic above is correct, but safe)
            if self.progress > 1.0 {
                self.progress = 1.0
            }
        }
    }
}

// Preview Provider
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView(onLoadingFinished: { print("Preview: Loading finished") })
            // Add environment objects if ThemeColors/Fonts need them for preview
            // .environmentObject(AuthViewModel.mock)
    }
}