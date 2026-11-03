import Foundation

struct BadgeStats {
    let profile: PlayerProfile
    let setCount: Int
    let wordCount: Int
    let masteredCount: Int
}

struct Badge: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let isEarned: (BadgeStats) -> Bool
}

enum BadgeCatalog {
    static let all: [Badge] = [
        Badge(id: "first_set", emoji: "📸", title: "Fotograf",
              description: "Lege deine erste Vokabelliste an.") { $0.setCount >= 1 },
        Badge(id: "first_quiz", emoji: "🎯", title: "Erste Runde",
              description: "Schließe dein erstes Quiz ab.") { $0.profile.quizzesCompleted >= 1 },
        Badge(id: "perfect_1", emoji: "💯", title: "Fehlerlos",
              description: "Beende ein Quiz ohne Fehler.") { $0.profile.perfectQuizzes >= 1 },
        Badge(id: "combo_10", emoji: "⚡", title: "Combo-König",
              description: "Schaffe 10 richtige Antworten am Stück.") { $0.profile.bestCombo >= 10 },
        Badge(id: "streak_3", emoji: "🔥", title: "Am Ball",
              description: "Übe 3 Tage hintereinander.") { $0.profile.longestStreak >= 3 },
        Badge(id: "blitz_15", emoji: "⏱️", title: "Blitzschnell",
              description: "15 richtige Antworten in einer Blitzrunde.") { $0.profile.blitzBest >= 15 },
        Badge(id: "quiz_10", emoji: "🏃", title: "Fleißig",
              description: "Schließe 10 Quizze ab.") { $0.profile.quizzesCompleted >= 10 },
        Badge(id: "sets_5", emoji: "🗂️", title: "Sammler",
              description: "Lege 5 Vokabellisten an.") { $0.setCount >= 5 },
        Badge(id: "words_50", emoji: "📚", title: "Wortschatz",
              description: "Habe 50 Vokabeln in deiner Sammlung.") { $0.wordCount >= 50 },
        Badge(id: "mastered_10", emoji: "🧠", title: "Gedächtnis-Ass",
              description: "Meistere 10 Vokabeln.") { $0.masteredCount >= 10 },
        Badge(id: "level_5", emoji: "⭐", title: "Aufsteiger",
              description: "Erreiche Level 5.") { $0.profile.level >= 5 },
        Badge(id: "streak_7", emoji: "🗓️", title: "Eine ganze Woche",
              description: "Übe 7 Tage hintereinander.") { $0.profile.longestStreak >= 7 },
        Badge(id: "perfect_10", emoji: "👑", title: "Perfektionist",
              description: "Beende 10 Quizze ohne Fehler.") { $0.profile.perfectQuizzes >= 10 },
        Badge(id: "combo_25", emoji: "🌪️", title: "Unaufhaltsam",
              description: "25 richtige Antworten am Stück.") { $0.profile.bestCombo >= 25 },
        Badge(id: "quiz_50", emoji: "🏅", title: "Dauerläufer",
              description: "Schließe 50 Quizze ab.") { $0.profile.quizzesCompleted >= 50 },
        Badge(id: "level_10", emoji: "🌟", title: "Sprach-Star",
              description: "Erreiche Level 10.") { $0.profile.level >= 10 },
        Badge(id: "mastered_100", emoji: "🏆", title: "Vokabel-Meister",
              description: "Meistere 100 Vokabeln.") { $0.masteredCount >= 100 },
        Badge(id: "streak_30", emoji: "🌋", title: "Feuer-Legende",
              description: "Übe 30 Tage hintereinander.") { $0.profile.longestStreak >= 30 },
    ]

    static func badge(withID id: String) -> Badge? {
        all.first { $0.id == id }
    }
}
