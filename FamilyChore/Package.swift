// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "FamilyChore", // Matches the typical project/app name
    platforms: [
        .iOS(.v16)
    ],
    // Products can often be inferred for executables, removed for simplicity
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .executableTarget(
            name: "FamilyChore", // This should match your app's main target name
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                // If you use other Firebase services like Storage or Messaging, add them:
                // .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                // .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ],
            path: "FamilyChore" // Specifies that sources for this target are in the "FamilyChore" subdirectory
        )
    ]
)