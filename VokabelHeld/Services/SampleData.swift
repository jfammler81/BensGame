import Foundation
import SwiftData

/// Legt beim ersten Start zwei Beispiel-Listen an, damit man sofort loslegen kann.
enum SampleData {
    private static let seededKey = "didSeedSampleData"

    static func seedIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        UserDefaults.standard.set(true, forKey: seededKey)

        let existing = (try? context.fetchCount(FetchDescriptor<VocabularySet>())) ?? 0
        guard existing == 0 else { return }

        addSet(title: "Tiere 🐾 (Beispiel)", language: .english, words: [
            ("the dog", "der Hund", ""),
            ("the cat", "die Katze", ""),
            ("the horse", "das Pferd", ""),
            ("the bird", "der Vogel", ""),
            ("the mouse", "die Maus", ""),
            ("the cow", "die Kuh", ""),
            ("the rabbit", "das Kaninchen", ""),
            ("the fish", "der Fisch", ""),
        ], in: context)

        addSet(title: "In der Schule 🎒 (Beispiel)", language: .french, words: [
            ("le livre", "das Buch", "the book"),
            ("la règle", "das Lineal", "the ruler"),
            ("le stylo", "der Kugelschreiber", "the pen"),
            ("la gomme", "der Radiergummi", "the eraser"),
            ("le cahier", "das Heft", "the exercise book"),
            ("la trousse", "das Mäppchen", "the pencil case"),
        ], in: context)

        try? context.save()
    }

    private static func addSet(title: String,
                               language: Language,
                               words: [(String, String, String)],
                               in context: ModelContext) {
        let set = VocabularySet(title: title, language: language)
        context.insert(set)
        for (index, word) in words.enumerated() {
            let item = VocabularyItem(term: word.0, german: word.1, english: word.2, order: index)
            context.insert(item)
            item.vocabularySet = set
        }
    }
}
