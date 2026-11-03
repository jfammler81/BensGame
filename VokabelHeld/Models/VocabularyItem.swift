import Foundation
import SwiftData

enum Mastery {
    /// Höchste Lernstufe (Karteikasten-Prinzip). Ab dieser Stufe gilt ein Wort als „gemeistert“.
    static let maxBox = 5
}

/// Eine einzelne Vokabel.
@Model
final class VocabularyItem {
    /// Das Wort in der Fremdsprache, z. B. „the dog“ oder „le chien“.
    var term: String
    /// Deutsche Bedeutung, z. B. „der Hund“.
    var german: String
    /// Optionale englische Bedeutung (für Französisch, Spanisch, …).
    var english: String
    var order: Int
    /// Lernstufe 0…5 (Karteikasten). Richtig = eine Stufe hoch, falsch = eine Stufe runter.
    var box: Int
    var correctCount: Int
    var wrongCount: Int
    var lastReviewed: Date? = nil
    var createdAt: Date
    var vocabularySet: VocabularySet? = nil

    init(term: String, german: String, english: String = "", order: Int = 0) {
        self.term = term
        self.german = german
        self.english = english
        self.order = order
        self.box = 0
        self.correctCount = 0
        self.wrongCount = 0
        self.createdAt = .now
    }

    var language: Language { vocabularySet?.language ?? .english }

    /// Englische Bedeutung – bei englischen Listen ist das das Wort selbst.
    var englishMeaning: String? {
        if language == .english { return term }
        let value = english.trimmed
        return value.isEmpty ? nil : value
    }

    var isMastered: Bool { box >= Mastery.maxBox }

    func registerAnswer(correct: Bool) {
        if correct {
            correctCount += 1
            box = min(box + 1, Mastery.maxBox)
        } else {
            wrongCount += 1
            box = max(box - 1, 0)
        }
        lastReviewed = .now
    }

    func resetProgress() {
        box = 0
        correctCount = 0
        wrongCount = 0
        lastReviewed = nil
    }
}
