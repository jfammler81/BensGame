import Foundation
import SwiftData

/// Eine Vokabelliste, z. B. „Unit 3 – School“, optional mit dem Foto, aus dem sie erstellt wurde.
@Model
final class VocabularySet {
    var title: String
    var languageCode: String
    /// Fach, zu dem die Liste gehört (für zukünftige Erweiterungen).
    var subjectCode: String
    var createdAt: Date
    var lastPracticed: Date? = nil
    @Attribute(.externalStorage) var photoData: Data? = nil

    @Relationship(deleteRule: .cascade, inverse: \VocabularyItem.vocabularySet)
    var items: [VocabularyItem] = []

    init(title: String, language: Language, subject: Subject = .languages, photoData: Data? = nil) {
        self.title = title
        self.languageCode = language.rawValue
        self.subjectCode = subject.rawValue
        self.createdAt = .now
        self.photoData = photoData
    }

    var language: Language { Language(rawValue: languageCode) ?? .english }

    var subject: Subject { Subject(rawValue: subjectCode) ?? .languages }

    var sortedItems: [VocabularyItem] { items.sorted { $0.order < $1.order } }

    var masteredCount: Int { items.filter(\.isMastered).count }

    /// Lernfortschritt 0…1 auf Basis der Lernstufen aller Wörter.
    var progress: Double {
        guard !items.isEmpty else { return 0 }
        let total = items.reduce(0) { $0 + $1.box }
        return Double(total) / Double(items.count * Mastery.maxBox)
    }
}
