import SwiftUI
import FirebaseAuth

struct AppRootView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        if authService.isAuthenticated {
            TabRootView()
        } else {
            AuthView(authService: authService)
        }
    }
}

#Preview {
    AppRootView()
        .environment(AuthService())
}
