import SwiftUI
import Firebase
import FirebaseAppCheck

@main
struct GraffiTagApp: App {

    // Declared without default value so Swift does NOT auto-initialize it
    // before our init() body runs.
    @State private var authService: AuthService

    init() {
        // 1. App Check must be registered first
        AppCheck.setAppCheckProviderFactory(GraffiTagAppCheckProviderFactory())
        // 2. Configure Firebase
        FirebaseApp.configure()
        // 3. NOW it is safe to call Auth.auth() inside AuthService
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
        }
    }
}
