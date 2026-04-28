import SwiftUI

struct TabRootView: View {
    @State private var selectedTab: Tab = .map

    enum Tab { case map, ar, profile }

    var body: some View {
        TabView(selection: $selectedTab) {
            GraffiMapView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(Tab.map)

            ARFeatureView()
                .tabItem { Label("Tag It", systemImage: "camera.viewfinder") }
                .tag(Tab.ar)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(Tab.profile)
        }
        .tint(.orange)
        .onAppear { configureTabBarAppearance() }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
