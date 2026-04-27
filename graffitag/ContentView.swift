import SwiftUI

// AppRootView acts as the navigation root.
// Auth state injection happens here once AuthService is wired (FASE 1 Task 3).
struct AppRootView: View {
    var body: some View {
        Text("GraffiTag")
            .font(.largeTitle.bold())
            .foregroundStyle(.primary)
    }
}

#Preview {
    AppRootView()
}
