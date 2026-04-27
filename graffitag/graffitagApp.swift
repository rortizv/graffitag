import SwiftUI
import Firebase
import FirebaseAppCheck
import GoogleSignIn

@main
struct GraffiTagApp: App {

    @State private var authService: AuthService
    @State private var locationManager = LocationManager()

    init() {
        AppCheck.setAppCheckProviderFactory(GraffiTagAppCheckProviderFactory())
        FirebaseApp.configure()
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
                .environment(locationManager)
        }
    }
}
