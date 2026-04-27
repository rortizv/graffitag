import Foundation

@MainActor
@Observable
final class AuthViewModel {

    // MARK: - Form State
    var email = ""
    var password = ""
    var confirmPassword = ""
    var displayName = ""

    // MARK: - UI State
    var isLoading = false
    var errorMessage: String?
    var showForgotPassword = false
    var forgotPasswordSent = false
    var isShowingRegister = false

    // MARK: - Validation

    var isEmailValid: Bool {
        let regex = /^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: regex) != nil
    }

    var isPasswordValid: Bool { password.count >= 6 }

    var passwordsMatch: Bool { password == confirmPassword }

    var isLoginFormValid: Bool { isEmailValid && isPasswordValid }

    var isRegisterFormValid: Bool {
        isEmailValid && isPasswordValid && passwordsMatch && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Dependencies

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Actions

    func signIn() async {
        guard isLoginFormValid else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signIn(email: email, password: password)
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp() async {
        guard isRegisterFormValid else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signInWithGoogle()
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset() async {
        guard isEmailValid else {
            errorMessage = "Enter a valid email to reset your password."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.resetPassword(email: email)
            forgotPasswordSent = true
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func switchMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isShowingRegister.toggle()
            errorMessage = nil
            password = ""
            confirmPassword = ""
        }
    }

    func clearError() { errorMessage = nil }
}
