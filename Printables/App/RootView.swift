import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedTab: AppTab = .create

    var body: some View {
        Group {
            switch selectedTab {
            case .create:
                NavigationStack { HomeView() }
            case .library:
                NavigationStack { LibraryView() }
            case .settings:
                NavigationStack { SettingsView() }
            }
        }
        .id(selectedTab)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $selectedTab)
        }
        .toastOverlay()
        .sheet(isPresented: $settings.shouldShowOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled(true)
        }
    }
}

#Preview {
    RootView()
        .environmentObject(WorksheetStore.preview)
        .environmentObject(AppSettings())
}
