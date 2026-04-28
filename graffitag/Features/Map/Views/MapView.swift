import SwiftUI
import MapKit
import CoreLocation
import FirebaseAuth

struct GraffiMapView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(FirestoreService.self) private var firestoreService
    @Environment(AuthService.self) private var authService

    @State private var viewModel: MapViewModel?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Group {
            if let vm = viewModel {
                content(for: vm)
            } else {
                Color.black
            }
        }
        .onAppear {
            guard viewModel == nil else { return }
            let vm = MapViewModel(firestoreService: firestoreService, locationManager: locationManager)
            viewModel = vm
            vm.onAppear()
        }
        .onDisappear { viewModel?.onDisappear() }
    }

    private func content(for vm: MapViewModel) -> some View {
        let regionKey = "\(vm.region.center.latitude),\(vm.region.center.longitude),\(vm.region.span.latitudeDelta),\(vm.region.span.longitudeDelta)"
        return MapContent(
            viewModel: vm,
            cameraPosition: $cameraPosition,
            authService: authService
        )
        .onChange(of: regionKey) { _, _ in
            cameraPosition = .region(vm.region)
        }
    }
}

// MARK: - Map Content

private struct MapContent: View {
    let viewModel: MapViewModel
    @Binding var cameraPosition: MapCameraPosition
    let authService: AuthService

    private var showDetailBinding: Binding<Bool> {
        Binding(get: { viewModel.showTagDetail }, set: { viewModel.showTagDetail = $0 })
    }

    var body: some View {
        mapLayer
            .sheet(isPresented: showDetailBinding, content: detailSheet)
    }

    private var mapLayer: some View {
        ZStack(alignment: .bottomTrailing) {
            mapView
            controls
        }
    }

    private var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            ForEach(viewModel.nearbyTags) { tag in
                Annotation("", coordinate: tag.coordinate) {
                    AnyView(tagPin(for: tag))
                }
            }
        }
        .ignoresSafeArea()
    }

    private func tagPin(for tag: GraffiTag) -> some View {
        TagAnnotationView(
            tag: tag,
            level: viewModel.proximity(to: tag),
            isSelected: viewModel.selectedTag?.id == tag.id
        )
        .onTapGesture { viewModel.selectTag(tag) }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            MapControlButton(icon: "location.fill") { viewModel.centerOnUser() }
            MapControlButton(icon: "plus.circle.fill", accent: true) { viewModel.showNewTagSheet = true }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 100)
    }

    private func deleteAction(for tag: GraffiTag) -> (() async -> Void)? {
        guard tag.authorId == authService.currentUser?.uid else { return nil }
        return { await viewModel.deleteTag(tag) }
    }

    @ViewBuilder
    private func detailSheet() -> some View {
        if let tag = viewModel.selectedTag {
            TagDetailSheet(
                tag: tag,
                level: viewModel.proximity(to: tag),
                distance: viewModel.distance(to: tag),
                onLike: { await viewModel.likeTag(tag) },
                onDelete: deleteAction(for: tag)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }
}

// MARK: - Map Control Button

private struct MapControlButton: View {
    let icon: String
    var accent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accent ? .black : .white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(accent ? Color.orange : Color.black.opacity(0.7))
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                )
        }
    }
}

