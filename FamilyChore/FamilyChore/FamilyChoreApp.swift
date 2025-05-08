//
//  FamilyChoreApp.swift
//  FamilyChore
//
//  Created by Anjana Kulasinghe on 30/04/2025.
//

import SwiftUI
import FirebaseCore // Import Firebase

@main
struct FamilyChoreApp: App {
    // Create a StateObject for the AuthViewModel to manage its lifecycle
    @StateObject private var authViewModel = AuthViewModel()

    // Configure Firebase and UI Appearance on app launch
    init() {
        FirebaseService.configure()
        configureNavigationBarAppearance()
    }

    private func configureNavigationBarAppearance() {
        // Configure standard appearance
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground() // Or .defaultBackground()
        // Set background color if desired (can use UIColor(Color.theme.primaryApp) etc.)
        // standardAppearance.backgroundColor = UIColor(Color.theme.primaryApp)

        // Set title font and color
        standardAppearance.titleTextAttributes = [
            .font: UIFont(name: ThemeFonts.boldName, size: 22) ?? UIFont.systemFont(ofSize: 22, weight: .bold), // Fallback to system font
            .foregroundColor: UIColor(Color.theme.textPrimary) // Use themed text color
        ]

        // Set large title font and color (if using large titles)
        standardAppearance.largeTitleTextAttributes = [
            .font: UIFont(name: ThemeFonts.boldName, size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold), // Fallback
            .foregroundColor: UIColor(Color.theme.textPrimary)
        ]

        // Apply the appearance
        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = standardAppearance // For large titles
        UINavigationBar.appearance().compactAppearance = standardAppearance // For compact states

        // Optional: Configure button item appearance
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .font: UIFont(name: ThemeFonts.regularName, size: 17) ?? UIFont.systemFont(ofSize: 17), // Fallback
            .foregroundColor: UIColor(Color.theme.accentApp) // Use accent color for buttons
        ]
        standardAppearance.buttonAppearance = buttonAppearance
        standardAppearance.doneButtonAppearance = buttonAppearance // Apply to Done buttons too

        // Re-apply after setting button appearance
        UINavigationBar.appearance().standardAppearance = standardAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = standardAppearance
        UINavigationBar.appearance().compactAppearance = standardAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject the AuthViewModel into the environment
                .environmentObject(authViewModel)
        }
    }
}
