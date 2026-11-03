import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VocabularySet.createdAt, order: .reverse) private var sets: [VocabularySet]

    @State private var showNewSet = false
    @State private var toast: (emoji: String, title: String, subtitle: String?)?

    private struct LanguageGroup: Identifiable {
        let language: Language
        let sets: [VocabularySet]
        var id: String { language.rawValue }
    }

    private var groups: [LanguageGroup] {
        Language.allCases.compactMap { language in
            let matching = sets.filter { $0.languageCode == language.rawValue }
            return matching.isEmpty ? nil : LanguageGroup(language: language, sets: matching)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sets.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Vokabeln")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewSet = true
                    } label: {
                        Label("Neue Liste", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationDestination(for: VocabularySet.self) { set in
                SetDetailView(set: set)
            }
        }
        .sheet(isPresented: $showNewSet) {
            NewSetView { badges in
                showToast(for: badges)
            }
        }
        .overlay(alignment: .top) {
            if let toast {
                ToastView(emoji: toast.emoji, title: toast.title, subtitle: toast.subtitle)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
    }

    private var list: some View {
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.sets) { set in
                        NavigationLink(value: set) {
                            SetRow(set: set)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            context.delete(group.sets[index])
                        }
                        try? context.save()
                    }
                } header: {
                    Text("\(group.language.flag) \(group.language.name)")
                        .font(.headline)
                        .textCase(nil)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("📸").font(.system(size: 80))
            Text("Noch keine Vokabeln")
                .font(.title.bold())
            Text("Fotografiere die Vokabelliste aus deinem Schulbuch oder Heft – die App liest die Wörter automatisch ein.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                showNewSet = true
            } label: {
                Label("Erste Liste anlegen", systemImage: "plus")
            }
            .buttonStyle(GameButtonStyle())
            .frame(maxWidth: 320)
            Spacer()
        }
        .padding(32)
    }

    private func showToast(for badges: [Badge]) {
        let badgeText = badges.isEmpty ? nil : "Neues Abzeichen: " + badges.map { "\($0.emoji) \($0.title)" }.joined(separator: ", ")
        withAnimation(.spring()) {
            toast = ("📸", "+\(RewardService.setCreatedXP) XP für deine neue Liste!", badgeText)
        }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut) { toast = nil }
        }
    }
}

struct SetRow: View {
    let set: VocabularySet

    var body: some View {
        HStack(spacing: 14) {
            if let data = set.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Text(set.language.flag)
                    .font(.title)
                    .frame(width: 48, height: 48)
                    .background(Theme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(set.title).font(.headline)
                Text("\(set.items.count) Wörter · ⭐ \(set.masteredCount) gemeistert")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressBar(value: set.progress, color: Theme.success, height: 6)
            }
        }
        .padding(.vertical, 4)
    }
}
