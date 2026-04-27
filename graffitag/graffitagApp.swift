import SwiftUI
import Firebase
import FirebaseAppCheck
import GoogleSignIn

@main
struct GraffiTagApp: App {

    @State private var authService: AuthService

    init() {
        // 1. App Check before Firebase
        AppCheck.setAppCheckProviderFactory(GraffiTagAppCheckProviderFactory())
        // 2. Configure Firebase
        FirebaseApp.configure()
        // 3. Configure Google Sign-In using the CLIENT_ID from GoogleService-Info.plist
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        // 4. Safe to initialize Auth now
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
        }
    }
}
