import FirebaseCore
import FirebaseAppCheck

final class GraffiTagAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
#if DEBUG
        // Simulator & debug builds: prints a debug token to the console on first run.
        // Register that token in Firebase Console → App Check → Apps → Debug token.
        return AppCheckDebugProvider(app: app)
#else
        // Physical device release builds: cryptographic device attestation.
        return AppAttestProvider(app: app)
#endif
    }
}
