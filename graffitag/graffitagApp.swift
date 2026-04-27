import SwiftUI
import Firebase

@main
struct GraffiTagApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
