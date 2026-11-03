import Foundation
import SwiftData

struct QuizReward {
    let xpEarned: Int
    let bonusXP: Int
    let levelBefore: Int
    let levelAfter: Int
    let newBadges: [Badge]
    let dailyGoalReached: Bool

    var totalXP: Int { xpEarned + bonusXP }
    var leveledUp: Bool { levelAfter > levelBefore }
}

/// Verbucht XP, Statistiken und Abzeichen.
enum RewardService {
    static let setCreatedXP = 20
    static let completionBonus = 5
    static let perfectBonus = 20

    /// Wertet eine (beendete oder abgebrochene) Quizrunde aus.
    static func apply(session: QuizSession, context: ModelContext, completed: Bool = true) -> QuizReward {
        let profile = PlayerProfile.current(in: context)
        let levelBefore = profile.level
        let goalReachedBefore = profile.xpToday >= profile.dailyGoal

        var bonus = 0
        if completed && session.answeredCount > 0 {
            bonus += completionBonus
            profile.quizzesCompleted += 1
            if session.isPerfect {
                bonus += perfectBonus
                profile.perfectQuizzes += 1
            }
        }

        if session.answeredCount > 0 {
            profile.registerActivity(xp: session.xpEarned + bonus)
        }
        profile.totalCorrect += session.correctCount
        profile.totalAnswered += session.answeredCount
        profile.bestCombo = max(profile.bestCombo, session.bestCombo)
        if session.mode == .blitz {
            profile.blitzBest = max(profile.blitzBest, session.correctCount)
        }

        var practicedSets: [VocabularySet] = []
        for question in session.questions {
            if let set = question.item?.vocabularySet, !practicedSets.contains(where: { $0 === set }) {
                practicedSets.append(set)
            }
        }
        practicedSets.forEach { $0.lastPracticed = .now }

        let badges = unlockBadges(for: profile, context: context)
        try? context.save()

        return QuizReward(
            xpEarned: session.xpEarned,
            bonusXP: bonus,
            levelBefore: levelBefore,
            levelAfter: profile.level,
            newBadges: badges,
            dailyGoalReached: !goalReachedBefore && profile.xpToday >= profile.dailyGoal
        )
    }

    /// Belohnung für das Anlegen einer neuen Vokabelliste.
    static func handleSetCreated(context: ModelContext) -> [Badge] {
        let profile = PlayerProfile.current(in: context)
        profile.registerActivity(xp: setCreatedXP)
        let badges = unlockBadges(for: profile, context: context)
        try? context.save()
        return badges
    }

    @discardableResult
    static func unlockBadges(for profile: PlayerProfile, context: ModelContext) -> [Badge] {
        let threshold = Mastery.maxBox
        let masteredDescriptor = FetchDescriptor<VocabularyItem>(
            predicate: #Predicate<VocabularyItem> { item in item.box >= threshold }
        )
        let stats = BadgeStats(
            profile: profile,
            setCount: (try? context.fetchCount(FetchDescriptor<VocabularySet>())) ?? 0,
            wordCount: (try? context.fetchCount(FetchDescriptor<VocabularyItem>())) ?? 0,
            masteredCount: (try? context.fetchCount(masteredDescriptor)) ?? 0
        )
        let newBadges = BadgeCatalog.all.filter {
            !profile.unlockedBadgeIDs.contains($0.id) && $0.isEarned(stats)
        }
        if !newBadges.isEmpty {
            profile.unlockedBadgeIDs.append(contentsOf: newBadges.map(\.id))
        }
        return newBadges
    }
}
