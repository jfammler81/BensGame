import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home
    case library
    case achievements
}

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Start", systemImage: "house.fill") }
                .tag(AppTab.home)

            LibraryView()
                .tabItem { Label("Vokabeln", systemImage: "books.vertical.fill") }
                .tag(AppTab.library)

            AchievementsView()
                .tabItem { Label("Erfolge", systemImage: "trophy.fill") }
                .tag(AppTab.achievements)
        }
        .tint(Theme.primary)
        .task {
            _ = PlayerProfile.current(in: context)
            SampleData.seedIfNeeded(in: context)
        }
    }
}
