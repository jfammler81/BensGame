import Foundation
import Observation

struct AnswerFeedback {
    let verdict: AnswerVerdict
    let correctAnswer: String
    let xp: Int
    let message: String
}

/// Der Zustand einer laufenden Quizrunde.
@Observable
final class QuizSession {
    static let blitzDuration = 60

    let id = UUID()
    let mode: QuizMode
    let title: String
    let questions: [QuizQuestion]

    private(set) var index = 0
    private(set) var combo = 0
    private(set) var bestCombo = 0
    private(set) var correctCount = 0
    private(set) var answeredCount = 0
    private(set) var xpEarned = 0
    private(set) var feedback: AnswerFeedback?
    private(set) var jokerUsed = false
    private(set) var isFinished = false
    private(set) var mistakes: [QuizQuestion] = []
    private(set) var timeRemaining: Int

    init(mode: QuizMode, title: String, questions: [QuizQuestion]) {
        self.mode = mode
        self.title = title
        self.questions = questions
        self.timeRemaining = mode == .blitz ? Self.blitzDuration : 0
        self.isFinished = questions.isEmpty
    }

    var current: QuizQuestion? {
        index < questions.count ? questions[index] : nil
    }

    /// Fortschritt 0…1 (bei der Blitzrunde: abgelaufene Zeit).
    var progress: Double {
        if mode == .blitz {
            return Double(Self.blitzDuration - timeRemaining) / Double(Self.blitzDuration)
        }
        guard !questions.isEmpty else { return 0 }
        return Double(index) / Double(questions.count)
    }

    var accuracy: Double {
        answeredCount == 0 ? 0 : Double(correctCount) / Double(answeredCount)
    }

    var isPerfect: Bool {
        answeredCount >= 3 && correctCount == answeredCount
    }

    /// Antwortart der aktuellen Frage – nach einem Joker wird aus Tippen Auswählen.
    var currentStyle: AnswerStyle {
        guard let question = current else { return .choice }
        return jokerUsed ? .choice : question.style
    }

    var canUseJoker: Bool {
        guard let question = current else { return false }
        return question.style == .typing && !jokerUsed && feedback == nil && question.options.count >= 2
    }

    /// Joker: zeigt Antwortmöglichkeiten statt Tippen (halbe XP).
    func useJoker() {
        guard canUseJoker else { return }
        jokerUsed = true
    }

    @discardableResult
    func submit(_ answer: String) -> AnswerVerdict {
        guard let question = current, feedback == nil, !isFinished else { return .wrong }

        let verdict: AnswerVerdict
        if currentStyle == .choice {
            verdict = AnswerChecker.normalize(answer) == AnswerChecker.normalize(question.correctAnswer)
                ? .correct : .wrong
        } else {
            verdict = AnswerChecker.verdict(for: answer, accepted: question.acceptedAnswers)
        }

        answeredCount += 1
        var xp = 0
        if verdict == .wrong {
            combo = 0
            if !mistakes.contains(where: { $0.prompt == question.prompt && $0.correctAnswer == question.correctAnswer }) {
                mistakes.append(question)
            }
        } else {
            correctCount += 1
            combo += 1
            bestCombo = max(bestCombo, combo)
            xp = baseXP(for: question, verdict: verdict) + comboBonus
            if jokerUsed { xp = max(1, xp / 2) }
        }
        xpEarned += xp
        question.item?.registerAnswer(correct: verdict != .wrong)

        feedback = AnswerFeedback(verdict: verdict,
                                  correctAnswer: question.correctAnswer,
                                  xp: xp,
                                  message: Self.message(for: verdict, combo: combo))
        return verdict
    }

    func next() {
        guard !isFinished else { return }
        feedback = nil
        jokerUsed = false
        index += 1
        if index >= questions.count {
            finish()
        }
    }

    /// Wird in der Blitzrunde jede Sekunde aufgerufen.
    func tick() {
        guard mode == .blitz, !isFinished else { return }
        timeRemaining -= 1
        if timeRemaining <= 0 {
            timeRemaining = 0
            finish()
        }
    }

    func finish() {
        feedback = nil
        isFinished = true
    }

    // MARK: - XP

    private func baseXP(for question: QuizQuestion, verdict: AnswerVerdict) -> Int {
        if mode == .blitz { return 5 }
        let base = question.style == .typing ? 12 : 8
        return verdict == .almost ? base - 2 : base
    }

    /// Ab 3 richtigen Antworten in Folge gibt es Bonus-XP (max. +10).
    private var comboBonus: Int {
        combo >= 3 ? min((combo - 2) * 2, 10) : 0
    }

    private static func message(for verdict: AnswerVerdict, combo: Int) -> String {
        switch verdict {
        case .correct:
            if combo >= 5 { return "Unglaublich! \(combo)er-Combo! 🔥" }
            return ["Super! 🎉", "Klasse! ⭐", "Genau richtig! ✅", "Stark! 💪", "Weiter so! 🚀", "Spitze! 🙌"]
                .randomElement() ?? "Super!"
        case .almost:
            return "Fast perfekt! Achte auf die Schreibweise ✏️"
        case .wrong:
            return ["Nicht ganz …", "Knapp daneben!", "Das üben wir nochmal 💡"].randomElement() ?? "Leider falsch"
        }
    }
}
