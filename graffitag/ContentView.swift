import SwiftUI
import FirebaseAuth

struct AppRootView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        if authService.isAuthenticated {
            Text("Welcome, \(authService.currentUser?.displayName ?? "Artist") 🎨")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
        } else {
            AuthView(authService: authService)
        }
    }
}

#Preview {
    AppRootView()
        .environment(AuthService())
}
