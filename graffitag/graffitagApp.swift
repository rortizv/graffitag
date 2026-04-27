import SwiftUI
import Firebase

@main
struct GraffiTagApp: App {

    @State private var authService = AuthService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
        }
    }
}
