import SwiftUI

struct AuthView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel: AuthViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                AuthContentView(viewModel: vm)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AuthViewModel(authService: authService)
            }
        }
    }
}

// MARK: - Content

private struct AuthContentView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            BackgroundSprayPattern()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo
                    LogoHeader()
                        .padding(.top, 64)
                        .padding(.bottom, 40)

                    // Card
                    VStack(spacing: 24) {
                        // Mode toggle
                        ModeToggle(isRegister: $viewModel.isShowingRegister) {
                            viewModel.switchMode()
                        }

                        // Form fields
                        VStack(spacing: 14) {
                            if viewModel.isShowingRegister {
                                GraffiTextField(
                                    placeholder: "Display name",
                                    text: $viewModel.displayName,
                                    contentType: .name
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            GraffiTextField(
                                placeholder: "Email",
                                text: $viewModel.email,
                                keyboardType: .emailAddress,
                                contentType: .emailAddress,
                                isValid: viewModel.email.isEmpty ? nil : viewModel.isEmailValid
                            )

                            GraffiTextField(
                                placeholder: "Password",
                                text: $viewModel.password,
                                isSecure: true,
                                contentType: viewModel.isShowingRegister ? .newPassword : .password,
                                isValid: viewModel.password.isEmpty ? nil : viewModel.isPasswordValid
                            )

                            if viewModel.isShowingRegister {
                                GraffiTextField(
                                    placeholder: "Confirm password",
                                    text: $viewModel.confirmPassword,
                                    isSecure: true,
                                    contentType: .newPassword,
                                    isValid: viewModel.confirmPassword.isEmpty ? nil : viewModel.passwordsMatch
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }

                        // Error message
                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error) {
                                viewModel.clearError()
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Primary CTA
                        PrimaryButton(
                            title: viewModel.isShowingRegister ? "Create account" : "Sign in",
                            isLoading: viewModel.isLoading,
                            isEnabled: viewModel.isShowingRegister
                                ? viewModel.isRegisterFormValid
                                : viewModel.isLoginFormValid
                        ) {
                            Task {
                                if viewModel.isShowingRegister {
                                    await viewModel.signUp()
                                } else {
                                    await viewModel.signIn()
                                }
                            }
                        }

                        // Forgot password
                        if !viewModel.isShowingRegister {
                            Button {
                                viewModel.showForgotPassword = true
                            } label: {
                                Text("Forgot password?")
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                            }
                        }

                        DividerWithLabel(text: "or")

                        // Google Sign-In
                        GoogleSignInButton(isLoading: viewModel.isLoading) {
                            Task { await viewModel.signInWithGoogle() }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isShowingRegister)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
                }
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $viewModel.showForgotPassword) {
            ForgotPasswordSheet(viewModel: viewModel)
                .presentationDetents([.height(300)])
        }
    }
}

// MARK: - Sub-components

private struct LogoHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("🎨")
                .font(.system(size: 56))
            Text("GraffiTag")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("Leave your mark on the world")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

private struct ModeToggle: View {
    @Binding var isRegister: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(["Sign In", "Register"], id: \.self) { label in
                let selected = (label == "Register") == isRegister
                Button {
                    if !selected { onToggle() }
                } label: {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selected ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selected ? Color.orange : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color.orange : Color.gray.opacity(0.4))
            )
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

private struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                Text("Continue with Google")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .disabled(isLoading)
    }
}

private struct DividerWithLabel: View {
    let text: String
    var body: some View {
        HStack {
            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
            Text(text).font(.caption).foregroundStyle(.gray).padding(.horizontal, 8)
            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
        }
    }
}

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

private struct BackgroundSprayPattern: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.08))
                    .frame(width: 300)
                    .blur(radius: 80)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.1)
                Circle()
                    .fill(Color.yellow.opacity(0.06))
                    .frame(width: 250)
                    .blur(radius: 60)
                    .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.5)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Forgot Password Sheet

private struct ForgotPasswordSheet: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Reset Password")
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                if viewModel.forgotPasswordSent {
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.badge.checkmark.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("Check your inbox — we sent a reset link to \(viewModel.email)")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    GraffiTextField(
                        placeholder: "Your email",
                        text: $viewModel.email,
                        keyboardType: .emailAddress,
                        isValid: viewModel.email.isEmpty ? nil : viewModel.isEmailValid
                    )

                    if let error = viewModel.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }

                    Button {
                        Task { await viewModel.sendPasswordReset() }
                    } label: {
                        Text("Send reset link")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.isEmailValid ? Color.orange : Color.gray.opacity(0.4))
                            )
                    }
                    .disabled(!viewModel.isEmailValid || viewModel.isLoading)
                }

                Button("Close") { dismiss() }
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }
            .padding(28)
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthService())
}
