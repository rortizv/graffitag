import SwiftUI
import Firebase
import FirebaseAppCheck
import GoogleSignIn

@main
struct GraffiTagApp: App {

    @State private var authService: AuthService
    @State private var locationManager: LocationManager
    @State private var firestoreService: FirestoreService

    init() {
        AppCheck.setAppCheckProviderFactory(GraffiTagAppCheckProviderFactory())
        FirebaseApp.configure()
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        _authService = State(initialValue: AuthService())
        _locationManager = State(initialValue: LocationManager())
        _firestoreService = State(initialValue: FirestoreService())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authService)
                .environment(locationManager)
                .environment(firestoreService)
        }
    }
}
