import SwiftUI
import SwiftData

struct SetDetailView: View {
    @Bindable var set: VocabularySet

    @Environment(\.modelContext) private var context
    @State private var showSetup = false
    @State private var editingItem: VocabularyItem?
    @State private var showNewWord = false
    @State private var showPhoto = false
    @State private var showRename = false
    @State private var newTitle = ""

    var body: some View {
        List {
            Section {
                header
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            Section("Wörter (\(set.items.count))") {
                ForEach(set.sortedItems) { item in
                    WordRow(item: item, language: set.language)
                        .contentShape(Rectangle())
                        .onTapGesture { editingItem = item }
                }
                .onDelete(perform: deleteItems)

                Button {
                    showNewWord = true
                } label: {
                    Label("Wort hinzufügen", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle(set.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        newTitle = set.title
                        showRename = true
                    } label: {
                        Label("Umbenennen", systemImage: "pencil")
                    }
                    Button {
                        showNewWord = true
                    } label: {
                        Label("Wort hinzufügen", systemImage: "plus")
                    }
                    Button(role: .destructive) {
                        set.items.forEach { $0.resetProgress() }
                    } label: {
                        Label("Lernstand zurücksetzen", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showSetup) {
            QuizSetupView(items: set.items, title: set.title)
        }
        .sheet(item: $editingItem) { item in
            WordEditorView(item: item, set: set)
        }
        .sheet(isPresented: $showNewWord) {
            WordEditorView(item: nil, set: set)
        }
        .sheet(isPresented: $showPhoto) {
            PhotoViewer(data: set.photoData)
        }
        .alert("Liste umbenennen", isPresented: $showRename) {
            TextField("Titel", text: $newTitle)
            Button("Abbrechen", role: .cancel) {}
            Button("Speichern") {
                if !newTitle.trimmed.isEmpty { set.title = newTitle.trimmed }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                if let data = set.photoData, let image = UIImage(data: data) {
                    Button {
                        showPhoto = true
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 84, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption2.bold())
                                    .padding(5)
                                    .background(.thinMaterial, in: Circle())
                                    .padding(4)
                            }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(set.language.flag)
                        .font(.system(size: 48))
                        .frame(width: 84, height: 84)
                        .background(Theme.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(set.language.flag) \(set.language.name)").font(.headline)
                    Text("⭐ \(set.masteredCount) von \(set.items.count) gemeistert")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ProgressBar(value: set.progress, color: Theme.success, height: 10)
                }
            }

            Button {
                showSetup = true
            } label: {
                Label("Jetzt üben!", systemImage: "play.fill")
            }
            .buttonStyle(GameButtonStyle())
            .disabled(set.items.isEmpty)
        }
        .card()
    }

    private func deleteItems(at offsets: IndexSet) {
        let items = set.sortedItems
        for index in offsets {
            context.delete(items[index])
        }
        try? context.save()
    }
}

struct WordRow: View {
    let item: VocabularyItem
    let language: Language

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.term).font(.headline)
                Text(item.german).font(.subheadline).foregroundStyle(.secondary)
                if language.asksForEnglishMeaning, let english = item.englishMeaning {
                    Text("🇬🇧 \(english)").font(.caption).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            MasteryDots(box: item.box)
            Button {
                SpeechService.shared.speak(item.term, languageCode: language.speechCode)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(Theme.primary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}

struct PhotoViewer: View {
    let data: Data?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                if let data, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .containerRelativeFrame(.horizontal)
                }
            }
            .navigationTitle("Foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
