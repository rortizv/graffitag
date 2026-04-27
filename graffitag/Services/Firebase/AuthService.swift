import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit

// MARK: - Protocol

protocol AuthServiceProtocol: AnyObject {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    func signInWithGoogle() async throws
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, displayName: String) async throws
    func signOut() throws
    func resetPassword(email: String) async throws
}

// MARK: - Implementation

@MainActor
@Observable
final class AuthService: AuthServiceProtocol {

    private(set) var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }

    private let auth: Auth
    private var stateHandle: AuthStateDidChangeListenerHandle?

    init(auth: Auth = .auth()) {
        self.auth = auth
        stateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                self?.currentUser = user
            }
        }
    }

    deinit {
        // MainActor.assumeIsolated is safe here: AuthService lives on @MainActor
        // and is always released from the main thread by SwiftUI's @State lifecycle.
        MainActor.assumeIsolated {
            if let stateHandle {
                auth.removeStateDidChangeListener(stateHandle)
            }
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            throw AppError.authFailed("No active window found.")
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AppError.authFailed("Google ID token missing.")
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await auth.signIn(with: credential)
    }

    // MARK: - Email / Password

    func signIn(email: String, password: String) async throws {
        do {
            try await auth.signIn(withEmail: email, password: password)
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let request = result.user.createProfileChangeRequest()
            request.displayName = displayName
            try await request.commitChanges()
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        do {
            try auth.signOut()
        } catch let error as NSError {
            throw AppError.authFailed(error.localizedDescription)
        }
    }

    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }

    // MARK: - Private

    private func mapAuthError(_ error: NSError) -> AppError {
        switch AuthErrorCode(rawValue: error.code) {
        case .wrongPassword, .invalidCredential:
            return .authFailed("Wrong email or password.")
        case .emailAlreadyInUse:
            return .authFailed("This email is already registered.")
        case .weakPassword:
            return .authFailed("Password must be at least 6 characters.")
        case .invalidEmail:
            return .authFailed("Enter a valid email address.")
        case .userNotFound:
            return .authFailed("No account found with this email.")
        case .networkError:
            return .authFailed("Network error. Check your connection.")
        default:
            return .authFailed(error.localizedDescription)
        }
    }
}

