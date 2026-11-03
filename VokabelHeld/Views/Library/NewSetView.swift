import SwiftUI
import SwiftData
import PhotosUI

/// Neue Vokabelliste anlegen – per Foto (mit automatischer Texterkennung) oder von Hand.
struct NewSetView: View {
    var onSaved: ([Badge]) -> Void = { _ in }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var language: Language = .english
    @State private var image: UIImage?
    @State private var pairs: [ParsedPair] = []
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isRecognizing = false
    @State private var recognitionMessage: String?

    private var validPairs: [ParsedPair] { pairs.filter(\.isComplete) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Infos") {
                    TextField("Titel, z. B. Unit 3 – School", text: $title)
                    Picker("Sprache", selection: $language) {
                        ForEach(Language.allCases) { language in
                            Text("\(language.flag) \(language.name)").tag(language)
                        }
                    }
                }

                Section {
                    photoSection
                } header: {
                    Text("Foto der Vokabelliste")
                } footer: {
                    Text("Die Texterkennung läuft direkt auf deinem Gerät. Prüfe die erkannten Wörter danach kurz und korrigiere sie bei Bedarf.")
                }

                Section {
                    ForEach($pairs) { $pair in
                        PairEditorRow(pair: $pair, language: language)
                    }
                    .onDelete { pairs.remove(atOffsets: $0) }

                    Button {
                        withAnimation { pairs.append(ParsedPair(term: "", german: "")) }
                    } label: {
                        Label("Vokabel hinzufügen", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Vokabeln (\(validPairs.count))")
                        Spacer()
                        if !pairs.isEmpty {
                            Button {
                                swapColumns()
                            } label: {
                                Label("Spalten tauschen", systemImage: "arrow.left.arrow.right")
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                    .textCase(nil)
                }
            }
            .navigationTitle("Neue Vokabelliste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .bold()
                        .disabled(validPairs.isEmpty)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadPhoto(newItem) }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { captured in
                    Task { await process(captured) }
                }
                .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 240)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        if isRecognizing {
            HStack(spacing: 12) {
                ProgressView()
                Text("Fuchsi liest deine Vokabeln … 🔍")
            }
        }
        if let recognitionMessage {
            Text(recognitionMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        HStack(spacing: 12) {
            if CameraPicker.isAvailable {
                Button {
                    showCamera = true
                } label: {
                    Label("Kamera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Fotos", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .disabled(isRecognizing)
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let loaded = UIImage(data: data) else {
            recognitionMessage = "Das Foto konnte nicht geladen werden."
            return
        }
        await process(loaded)
    }

    private func process(_ captured: UIImage) async {
        let prepared = captured.resized(maxDimension: 2400)
        image = prepared
        isRecognizing = true
        recognitionMessage = nil
        defer { isRecognizing = false }

        do {
            let texts = try await TextRecognizer.recognize(
                in: prepared,
                preferredLanguages: [language.speechCode, Language.germanSpeechCode]
            )
            let parsed = VocabularyParser.parse(texts)
            if parsed.isEmpty {
                recognitionMessage = "Keine Vokabeln erkannt. Versuche ein schärferes Foto oder trage die Wörter von Hand ein."
                Haptics.warning()
            } else {
                // Leere Platzhalterzeilen entfernen, dann Erkanntes anhängen.
                pairs.removeAll { $0.term.trimmed.isEmpty && $0.german.trimmed.isEmpty }
                withAnimation { pairs.append(contentsOf: parsed) }
                let incomplete = parsed.filter { !$0.isComplete }.count
                recognitionMessage = incomplete == 0
                    ? "✅ \(parsed.count) Vokabeln erkannt! Bitte kurz prüfen."
                    : "✅ \(parsed.count) Zeilen erkannt – bei \(incomplete) fehlt noch die Übersetzung."
                Haptics.success()
            }
        } catch {
            recognitionMessage = "Texterkennung fehlgeschlagen: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    private func swapColumns() {
        withAnimation {
            pairs = pairs.map { ParsedPair(id: $0.id, term: $0.german, german: $0.term, english: $0.english) }
        }
        Haptics.tap()
    }

    private func save() {
        let finalTitle = title.trimmed.isEmpty
            ? "\(language.name) – \(Date.now.formatted(date: .abbreviated, time: .omitted))"
            : title.trimmed
        let photoData = image?.resized(maxDimension: 1600).jpegData(compressionQuality: 0.7)

        let set = VocabularySet(title: finalTitle, language: language, photoData: photoData)
        context.insert(set)
        for (index, pair) in validPairs.enumerated() {
            let item = VocabularyItem(term: pair.term.trimmed,
                                      german: pair.german.trimmed,
                                      english: language.asksForEnglishMeaning ? pair.english.trimmed : "",
                                      order: index)
            context.insert(item)
            item.vocabularySet = set
        }
        try? context.save()

        let badges = RewardService.handleSetCreated(context: context)
        Haptics.success()
        onSaved(badges)
        dismiss()
    }
}

struct PairEditorRow: View {
    @Binding var pair: ParsedPair
    let language: Language

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(language.flag)
                TextField(language.name, text: $pair.term)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.body.weight(.semibold))
            }
            HStack {
                Text("🇩🇪")
                TextField("Deutsch", text: $pair.german)
                    .autocorrectionDisabled()
            }
            if language.asksForEnglishMeaning {
                HStack {
                    Text("🇬🇧")
                    TextField("Englisch (optional)", text: $pair.english)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
