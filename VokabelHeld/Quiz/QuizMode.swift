import SwiftUI

/// Die verschiedenen Übungsarten.
enum QuizMode: String, CaseIterable, Identifiable {
    case multipleChoice
    case writing
    case meaningGerman
    case meaningEnglish
    case mixed
    case blitz

    var id: String { rawValue }

    var title: String {
        switch self {
        case .multipleChoice: "Auswählen"
        case .writing: "Vokabeln schreiben"
        case .meaningGerman: "Was heißt das auf Deutsch?"
        case .meaningEnglish: "Was heißt das auf Englisch?"
        case .mixed: "Mix-Challenge"
        case .blitz: "Blitzrunde"
        }
    }

    var subtitle: String {
        switch self {
        case .multipleChoice: "Wähle die richtige Übersetzung aus 4 Antworten."
        case .writing: "Schreibe die Vokabel in der Fremdsprache."
        case .meaningGerman: "Tippe die deutsche Bedeutung ein."
        case .meaningEnglish: "Tippe die englische Bedeutung ein."
        case .mixed: "Alle Übungsarten bunt gemischt."
        case .blitz: "60 Sekunden – so viele wie möglich!"
        }
    }

    var emoji: String {
        switch self {
        case .multipleChoice: "🎯"
        case .writing: "✏️"
        case .meaningGerman: "🇩🇪"
        case .meaningEnglish: "🇬🇧"
        case .mixed: "🎲"
        case .blitz: "⚡"
        }
    }

    var color: Color {
        switch self {
        case .multipleChoice: Theme.primary
        case .writing: .teal
        case .meaningGerman: .orange
        case .meaningEnglish: .pink
        case .mixed: .purple
        case .blitz: Theme.flame
        }
    }
}
