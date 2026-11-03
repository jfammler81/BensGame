import Foundation

/// Fremdsprachen, für die Vokabellisten angelegt werden können.
enum Language: String, CaseIterable, Identifiable, Codable {
    case english
    case french
    case spanish
    case italian
    case latin
    case dutch

    var id: String { rawValue }

    var name: String {
        switch self {
        case .english: "Englisch"
        case .french: "Französisch"
        case .spanish: "Spanisch"
        case .italian: "Italienisch"
        case .latin: "Latein"
        case .dutch: "Niederländisch"
        }
    }

    var flag: String {
        switch self {
        case .english: "🇬🇧"
        case .french: "🇫🇷"
        case .spanish: "🇪🇸"
        case .italian: "🇮🇹"
        case .latin: "🏛️"
        case .dutch: "🇳🇱"
        }
    }

    /// BCP-47-Code für Sprachausgabe und Texterkennung.
    var speechCode: String {
        switch self {
        case .english: "en-GB"
        case .french: "fr-FR"
        case .spanish: "es-ES"
        case .italian: "it-IT"
        case .latin: "it-IT"
        case .dutch: "nl-NL"
        }
    }

    /// Bei allen Sprachen außer Englisch kann zusätzlich die englische Bedeutung gespeichert werden.
    var asksForEnglishMeaning: Bool { self != .english }

    static let germanSpeechCode = "de-DE"
    static let englishSpeechCode = "en-GB"
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
