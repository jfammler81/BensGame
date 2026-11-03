import Foundation
import SwiftData

/// Spielerprofil mit XP, Level, Serie (Streak), Tagesziel und Abzeichen.
@Model
final class PlayerProfile {
    var name: String
    var avatar: String
    var totalXP: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDay: Date? = nil
    var todayXP: Int
    var todayDate: Date? = nil
    var dailyGoal: Int
    var quizzesCompleted: Int
    var perfectQuizzes: Int
    var totalCorrect: Int
    var totalAnswered: Int
    var bestCombo: Int
    var blitzBest: Int
    var unlockedBadgeIDs: [String] = []

    init(name: String = "Ben", avatar: String = "🦊") {
        self.name = name
        self.avatar = avatar
        self.totalXP = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.todayXP = 0
        self.dailyGoal = 50
        self.quizzesCompleted = 0
        self.perfectQuizzes = 0
        self.totalCorrect = 0
        self.totalAnswered = 0
        self.bestCombo = 0
        self.blitzBest = 0
    }

    var level: Int { LevelSystem.level(forXP: totalXP) }

    /// Serie, die aktuell noch „lebt“ (heute oder gestern gespielt).
    var displayStreak: Int {
        guard let last = lastActiveDay else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: last),
                                           to: calendar.startOfDay(for: .now)).day ?? 0
        return days <= 1 ? currentStreak : 0
    }

    var xpToday: Int {
        guard let date = todayDate, Calendar.current.isDateInToday(date) else { return 0 }
        return todayXP
    }

    var dailyGoalProgress: Double {
        guard dailyGoal > 0 else { return 1 }
        return min(Double(xpToday) / Double(dailyGoal), 1)
    }

    var accuracy: Double {
        totalAnswered == 0 ? 0 : Double(totalCorrect) / Double(totalAnswered)
    }

    /// Verbucht XP und aktualisiert Tages-XP und Serie.
    func registerActivity(xp: Int, now: Date = .now) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        if let last = lastActiveDay {
            let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: today).day ?? 0
            if diff == 1 {
                currentStreak += 1
            } else if diff > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }
        if currentStreak == 0 { currentStreak = 1 }
        lastActiveDay = today
        longestStreak = max(longestStreak, currentStreak)

        if let date = todayDate, calendar.isDate(date, inSameDayAs: today) {
            todayXP += xp
        } else {
            todayDate = today
            todayXP = xp
        }
        totalXP += xp
    }

    /// Liefert das (einzige) Profil und legt es bei Bedarf an.
    static func current(in context: ModelContext) -> PlayerProfile {
        if let existing = try? context.fetch(FetchDescriptor<PlayerProfile>()).first {
            return existing
        }
        let profile = PlayerProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }
}
