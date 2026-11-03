import SwiftUI
import SwiftData

@main
struct VokabelHeldApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .fontDesign(.rounded)
        }
        .modelContainer(for: [VocabularySet.self, VocabularyItem.self, PlayerProfile.self])
    }
}
