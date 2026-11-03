import SwiftUI

/// Die Fächer der App.
///
/// In Version 1 ist nur `.languages` (Vokabeln) freigeschaltet. Weitere Fächer
/// wie Deutsch oder Mathematik werden in einem späteren Release ergänzt:
/// Sie bekommen einen eigenen `QuestionProvider` (siehe `Quiz/QuestionProvider.swift`)
/// und nutzen dieselbe Quiz-, XP- und Abzeichen-Logik.
enum Subject: String, CaseIterable, Identifiable, Codable {
    case languages
    case german
    case math

    var id: String { rawValue }

    var title: String {
        switch self {
        case .languages: "Sprachen"
        case .german: "Deutsch"
        case .math: "Mathematik"
        }
    }

    var subtitle: String {
        switch self {
        case .languages: "Vokabeln üben"
        case .german: "Rechtschreibung & Grammatik"
        case .math: "Rechnen & Knobeln"
        }
    }

    var emoji: String {
        switch self {
        case .languages: "🌍"
        case .german: "📖"
        case .math: "🧮"
        }
    }

    var color: Color {
        switch self {
        case .languages: Theme.primary
        case .german: .orange
        case .math: .purple
        }
    }

    /// Nur freigeschaltete Fächer können geöffnet werden.
    var isAvailable: Bool { self == .languages }
}
