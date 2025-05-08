//
//  ContentView.swift
//  FamilyChore
//
//  Created by Anjana Kulasinghe on 30/04/2025.
//

import SwiftUI
import FirebaseAuth // Needed for observing Auth state if not using ViewModel's published property directly
// Assuming AuthViewModel is in the same module or accessible

struct ContentView: View {
    // Observe the authentication state and user profile from the environment
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isAppLoading = true // State to control the initial loading view display
    @State private var canShowMainContent = false // New state to delay auth logic
    
    var body: some View {
        Group { // Explicit Group wrapping the if/else
            if isAppLoading {
                LoadingView(onLoadingFinished: {
                    // print("ContentView: onLoadingFinished callback received. Setting isAppLoading to false.") // Removed
                    self.isAppLoading = false
                })
            } else if canShowMainContent { // Only show main content if this is also true
                // Main content based on auth state
                Group {
                    // Check if the user is authenticated
                    if authViewModel.currentUser == nil {
                        // If not authenticated, show the Login view
                        LoginView()
                    } else {
                        // If authenticated, check if the user profile is loaded
                        if authViewModel.isLoading {
                            // If user is authenticated but profile is not loaded, show a loading indicator
                            ProgressView("Loading Profile...")
                                .font(Font.theme.body) // Apply theme font
                        } else if let userProfile = authViewModel.userProfile {
                            // Based on the user's role, show the appropriate dashboard
                            if userProfile.role == .parent {
                                ParentDashboardView()
                            } else { // Assuming role is .child
                                ChildDashboardView()
                            }
                        } else {
                            // If not loading and profile is nil (implies error or not found)
                            // Handle error or show login again
                            LoginView() // Or show an error message
                        }
                    }
                }
                // Inject the AuthViewModel into the environment for descendant views
                // This is typically done higher up, e.g., in the App struct, but included here for completeness
                // .environmentObject(authViewModel) // This line might be redundant if already in App struct
            } else {
                // Fallback: Still loading or waiting for canShowMainContent
                // This could be a transparent view or a minimal ProgressView
                // to avoid showing nothing if canShowMainContent is delayed.
                Color.clear // Or another ProgressView if preferred
                    .onAppear {
                        // print("ContentView: In 'else' but canShowMainContent is false. Waiting...") // Removed
                    }
            }
        }
        .onChange(of: isAppLoading) { oldValue, newValue in
            // print("ContentView: isAppLoading changed from \(oldValue) to \(newValue).") // Removed
            if newValue == false { // When isAppLoading becomes false
                // Now that isAppLoading is false, we can allow main content to be shown.
                // A tiny delay can sometimes help ensure the UI has settled from the LoadingView disappearing.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // Minimal delay
                    // print("ContentView: Setting canShowMainContent to true.") // Removed
                    self.canShowMainContent = true
                }
            }
        }
        // Removed the diagnostic .onAppear block
    }
}
