import Foundation

enum AnswerStyle {
    /// Antwort aus mehreren Möglichkeiten auswählen.
    case choice
    /// Antwort selbst eintippen.
    case typing
}

/// Eine fachunabhängige Quizfrage. Vokabeln, später aber auch Deutsch- oder
/// Mathe-Aufgaben werden in dieses Format übersetzt.
struct QuizQuestion: Identifiable {
    let id = UUID()
    /// Die zugehörige Vokabel (für den Lernstand). `nil` bei Aufgaben ohne Vokabel, z. B. Mathe.
    let item: VocabularyItem?
    /// Arbeitsanweisung, z. B. „Was bedeutet das auf Deutsch?“
    let instruction: String
    /// Das abgefragte Wort / die Aufgabe.
    let prompt: String
    /// Sprache des Prompts für die Vorlesefunktion.
    let promptSpeechCode: String?
    let correctAnswer: String
    let acceptedAnswers: [String]
    /// Auswahlmöglichkeiten (inkl. richtiger Antwort). Wird auch für den Joker genutzt.
    let options: [String]
    let style: AnswerStyle
    /// Sprache der Antwort (für Sonderzeichen-Leiste).
    let answerLanguageCode: String
}
