import SwiftUI
import Firebase
import FirebaseAppCheck

@main
struct GraffiTagApp: App {

    @State private var authService = AuthService()

    init() {
        // App Check must be registered before FirebaseApp.configure()
        AppCheck.setAppCheckProviderFactory(GraffiTagAppCheckProviderFactory())
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
        }
    }
}
