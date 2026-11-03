import SwiftUI

/// Auswertung nach einer Runde mit Sternen, XP, Level-Up und neuen Abzeichen.
struct QuizResultView: View {
    let session: QuizSession
    let reward: QuizReward?
    let onRepeat: () -> Void
    let onClose: () -> Void

    @State private var visibleStars = 0
    @State private var displayedXP = 0
    @State private var showConfetti = false

    private var stars: Int {
        if session.mode == .blitz {
            switch session.correctCount {
            case 20...: return 3
            case 12...: return 2
            case 5...: return 1
            default: return 0
            }
        }
        switch session.accuracy {
        case 0.9...: return 3
        case 0.7...: return 2
        case 0.4...: return 1
        default: return 0
        }
    }

    private var headline: String {
        switch stars {
        case 3: "Perfekt! 🏆"
        case 2: "Super gemacht! 🎉"
        case 1: "Gut gemacht! 👍"
        default: "Weiter üben! 💪"
        }
    }

    private var mascotMessage: String {
        if session.isPerfect { return "Wow, alles richtig! Du bist ein echter Vokabel-Held!" }
        if session.mode == .blitz { return "\(session.correctCount) richtige Antworten in \(QuizSession.blitzDuration) Sekunden! Schaffst du mehr?" }
        if session.mistakes.isEmpty { return "Klasse Runde!" }
        return "Die Wörter unten üben wir beim nächsten Mal extra oft. Du schaffst das!"
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 22) {
                    Text(headline)
                        .font(.largeTitle.bold())
                        .padding(.top, 24)

                    HStack(spacing: 14) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: index == 1 ? 68 : 50))
                                .foregroundStyle(index < visibleStars ? Theme.gold : Color.gray.opacity(0.25))
                                .scaleEffect(index < visibleStars ? 1 : 0.7)
                                .offset(y: index == 1 ? -12 : 0)
                                .shadow(color: index < visibleStars ? Theme.gold.opacity(0.5) : .clear, radius: 10)
                        }
                    }

                    MascotView(message: mascotMessage)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        StatTile(emoji: "⭐", value: "+\(displayedXP)", label: "XP")
                        StatTile(emoji: "✅", value: "\(session.correctCount)/\(session.answeredCount)", label: "Richtig")
                        StatTile(emoji: "🔥", value: "\(session.bestCombo)", label: "Beste Combo")
                        StatTile(emoji: "🎯", value: "\(Int((session.accuracy * 100).rounded()))%", label: "Genauigkeit")
                    }

                    if let reward {
                        rewardBanners(reward)
                    }

                    if !session.mistakes.isEmpty {
                        mistakesCard
                    }

                    VStack(spacing: 12) {
                        Button(action: onRepeat) {
                            Label("Nochmal spielen", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(GameButtonStyle(color: session.mode.color))

                        Button("Fertig", action: onClose)
                            .buttonStyle(GameButtonStyle(color: Color(.systemGray4), foreground: .primary))
                    }
                    .padding(.bottom, 24)
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }

            if showConfetti {
                ConfettiView().ignoresSafeArea()
            }
        }
        .task {
            await animateIn()
        }
    }

    @ViewBuilder
    private func rewardBanners(_ reward: QuizReward) -> some View {
        if reward.bonusXP > 0 {
            banner(emoji: "🎁", title: "Bonus: +\(reward.bonusXP) XP",
                   subtitle: session.isPerfect ? "Runde beendet + fehlerfrei!" : "Für das Beenden der Runde",
                   color: Theme.gold)
        }
        if reward.leveledUp {
            banner(emoji: "🆙", title: "Level \(reward.levelAfter) erreicht!",
                   subtitle: "Du bist jetzt „\(LevelSystem.title(for: reward.levelAfter))“",
                   color: Theme.primary)
        }
        if reward.dailyGoalReached {
            banner(emoji: "🎯", title: "Tagesziel erreicht!", subtitle: "Deine Serie wächst weiter 🔥", color: Theme.success)
        }
        ForEach(reward.newBadges) { badge in
            banner(emoji: badge.emoji, title: "Neues Abzeichen: \(badge.title)", subtitle: badge.description, color: .purple)
        }
    }

    private func banner(emoji: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Text(emoji).font(.system(size: 40))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(color.opacity(0.4), lineWidth: 2)
        )
    }

    private var mistakesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Das üben wir nochmal 💡").font(.headline)
            ForEach(session.mistakes) { question in
                HStack {
                    Text(question.prompt).font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.right").foregroundStyle(.secondary)
                    Text(question.correctAnswer)
                        .font(.subheadline)
                        .foregroundStyle(Theme.success)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func animateIn() async {
        for index in 0..<stars {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                visibleStars = index + 1
            }
            Haptics.tap()
        }
        if stars >= 2 || reward?.leveledUp == true || reward?.newBadges.isEmpty == false {
            showConfetti = true
            Haptics.success()
        }
        let total = reward?.totalXP ?? session.xpEarned
        let steps = 20
        for step in 1...steps {
            try? await Task.sleep(for: .milliseconds(30))
            displayedXP = total * step / steps
        }
    }
}
