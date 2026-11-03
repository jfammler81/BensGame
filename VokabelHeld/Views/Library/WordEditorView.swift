import SwiftUI
import SwiftData

/// Einzelne Vokabel bearbeiten oder neu anlegen.
struct WordEditorView: View {
    let item: VocabularyItem?
    let set: VocabularySet

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var term: String
    @State private var german: String
    @State private var english: String

    init(item: VocabularyItem?, set: VocabularySet) {
        self.item = item
        self.set = set
        _term = State(initialValue: item?.term ?? "")
        _german = State(initialValue: item?.german ?? "")
        _english = State(initialValue: item?.english ?? "")
    }

    private var canSave: Bool { !term.trimmed.isEmpty && !german.trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vokabel") {
                    HStack {
                        Text(set.language.flag)
                        TextField(set.language.name, text: $term)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Text("🇩🇪")
                        TextField("Deutsch", text: $german)
                            .autocorrectionDisabled()
                    }
                    if set.language.asksForEnglishMeaning {
                        HStack {
                            Text("🇬🇧")
                            TextField("Englisch (optional)", text: $english)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                }

                if let item {
                    Section("Lernstand") {
                        HStack {
                            Text("Stufe \(item.box) von \(Mastery.maxBox)")
                            Spacer()
                            MasteryDots(box: item.box)
                        }
                        Text("✅ \(item.correctCount) richtig · ❌ \(item.wrongCount) falsch")
                            .foregroundStyle(.secondary)
                        Button("Lernstand zurücksetzen", role: .destructive) {
                            item.resetProgress()
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "Neue Vokabel" : "Vokabel bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .bold()
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        if let item {
            item.term = term.trimmed
            item.german = german.trimmed
            item.english = english.trimmed
        } else {
            let nextOrder = (set.items.map(\.order).max() ?? -1) + 1
            let newItem = VocabularyItem(term: term.trimmed,
                                         german: german.trimmed,
                                         english: english.trimmed,
                                         order: nextOrder)
            context.insert(newItem)
            newItem.vocabularySet = set
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
