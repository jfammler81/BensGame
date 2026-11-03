import Foundation

/// Erzeugt Quizfragen für ein Fach.
///
/// Erweiterung für zukünftige Fächer: einfach einen neuen Provider schreiben,
/// z. B. `MathQuestionProvider` (Kopfrechnen) oder `GermanQuestionProvider`
/// (Rechtschreibung). Quiz-Ablauf, XP, Combos und Abzeichen funktionieren
/// dann ohne weitere Änderungen.
protocol QuestionProvider {
    func makeQuestions(mode: QuizMode, count: Int?) -> [QuizQuestion]
}

/// Konfiguration einer Quizrunde.
struct QuizConfig: Identifiable {
    let id = UUID()
    let title: String
    let mode: QuizMode
    /// Anzahl Fragen, `nil` = alle.
    let questionCount: Int?
    let provider: any QuestionProvider

    func makeSession() -> QuizSession {
        QuizSession(mode: mode,
                    title: title,
                    questions: provider.makeQuestions(mode: mode, count: questionCount))
    }
}

/// Fragen aus Vokabeln.
struct VocabularyQuestionProvider: QuestionProvider {
    let items: [VocabularyItem]

    static let blitzQuestionCount = 150

    func makeQuestions(mode: QuizMode, count: Int?) -> [QuizQuestion] {
        let usable = items.filter { !$0.term.trimmed.isEmpty && !$0.german.trimmed.isEmpty }
        let pool = mode == .meaningEnglish ? usable.filter { $0.englishMeaning != nil } : usable
        guard !pool.isEmpty else { return [] }

        let selection: [VocabularyItem]
        if mode == .blitz {
            var list: [VocabularyItem] = []
            while list.count < Self.blitzQuestionCount {
                list += pool.shuffled()
            }
            selection = list
        } else {
            // Schwächere Wörter (niedrige Lernstufe) kommen bevorzugt dran.
            let prioritized = pool.shuffled().sorted { $0.box < $1.box }
            let limit = count.map { min($0, pool.count) } ?? pool.count
            selection = Array(prioritized.prefix(limit)).shuffled()
        }
        return selection.compactMap { question(for: $0, mode: mode) }
    }

    private func question(for item: VocabularyItem, mode: QuizMode) -> QuizQuestion? {
        let language = item.language
        let german = Language.germanSpeechCode

        switch mode {
        case .mixed:
            var modes: [QuizMode] = [.multipleChoice, .writing, .meaningGerman]
            if language != .english && item.englishMeaning != nil {
                modes.append(.meaningEnglish)
            }
            return question(for: item, mode: modes.randomElement() ?? .multipleChoice)

        case .multipleChoice, .blitz:
            if Double.random(in: 0..<1) < 0.35 {
                return make(item,
                            instruction: "Wie heißt das auf \(language.name)?",
                            prompt: item.german, promptCode: german,
                            answer: item.term, answerCode: language.speechCode,
                            options: choices(for: item, correct: item.term) { $0.term },
                            style: .choice)
            }
            return make(item,
                        instruction: "Was bedeutet das?",
                        prompt: item.term, promptCode: language.speechCode,
                        answer: item.german, answerCode: german,
                        options: choices(for: item, correct: item.german) { $0.german },
                        style: .choice)

        case .writing:
            return make(item,
                        instruction: "Schreibe auf \(language.name)",
                        prompt: item.german, promptCode: german,
                        answer: item.term, answerCode: language.speechCode,
                        options: choices(for: item, correct: item.term) { $0.term },
                        style: .typing)

        case .meaningGerman:
            return make(item,
                        instruction: "Was bedeutet das auf Deutsch?",
                        prompt: item.term, promptCode: language.speechCode,
                        answer: item.german, answerCode: german,
                        options: choices(for: item, correct: item.german) { $0.german },
                        style: .typing)

        case .meaningEnglish:
            guard let english = item.englishMeaning else { return nil }
            if language == .english {
                return make(item,
                            instruction: "Was heißt das auf Englisch?",
                            prompt: item.german, promptCode: german,
                            answer: english, answerCode: Language.englishSpeechCode,
                            options: choices(for: item, correct: english) { $0.englishMeaning },
                            style: .typing)
            }
            return make(item,
                        instruction: "Was bedeutet das auf Englisch?",
                        prompt: item.term, promptCode: language.speechCode,
                        answer: english, answerCode: Language.englishSpeechCode,
                        options: choices(for: item, correct: english) { $0.englishMeaning },
                        style: .typing)
        }
    }

    private func make(_ item: VocabularyItem,
                      instruction: String,
                      prompt: String,
                      promptCode: String?,
                      answer: String,
                      answerCode: String,
                      options: [String],
                      style: AnswerStyle) -> QuizQuestion {
        // Ohne genug Auswahlmöglichkeiten wird automatisch getippt.
        let finalStyle: AnswerStyle = (style == .choice && options.count < 2) ? .typing : style
        return QuizQuestion(item: item,
                            instruction: instruction,
                            prompt: prompt,
                            promptSpeechCode: promptCode,
                            correctAnswer: answer,
                            acceptedAnswers: [answer],
                            options: options,
                            style: finalStyle,
                            answerLanguageCode: answerCode)
    }

    /// Richtige Antwort plus bis zu drei falsche aus derselben Sprache.
    private func choices(for item: VocabularyItem,
                         correct: String,
                         value: (VocabularyItem) -> String?) -> [String] {
        var seen: Set<String> = [AnswerChecker.normalize(correct)]
        var distractors: [String] = []
        let language = item.language
        for other in items.shuffled() where other !== item && other.language == language {
            guard let candidate = value(other)?.trimmed, !candidate.isEmpty else { continue }
            if seen.insert(AnswerChecker.normalize(candidate)).inserted {
                distractors.append(candidate)
            }
            if distractors.count == 3 { break }
        }
        return (distractors + [correct]).shuffled()
    }
}
