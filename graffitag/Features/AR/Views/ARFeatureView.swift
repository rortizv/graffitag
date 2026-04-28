import SwiftUI

// Entry point for the AR tab — switches between Camera and Editor modes.
struct ARFeatureView: View {
    @Environment(FirestoreService.self) private var firestoreService
    @Environment(AuthService.self) private var authService
    @Environment(LocationManager.self) private var locationManager

    @State private var viewModel: ARViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.mode == .camera {
                    ARCameraView(viewModel: vm)
                } else {
                    AREditorView(viewModel: vm)
                }
            } else {
                Color.black
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ARViewModel(
                    firestoreService: firestoreService,
                    authService: authService,
                    locationManager: locationManager
                )
            }
        }
        .ignoresSafeArea()
    }
}
