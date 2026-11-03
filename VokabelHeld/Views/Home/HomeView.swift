import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: AppTab

    @Query private var profiles: [PlayerProfile]
    @Query(sort: \VocabularySet.createdAt, order: .reverse) private var sets: [VocabularySet]

    @State private var setupSet: VocabularySet?
    @State private var dailyQuiz: QuizConfig?
    @State private var lockedSubject: Subject?

    private var profile: PlayerProfile? { profiles.first }
    private var allItems: [VocabularyItem] { sets.flatMap(\.items) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile {
                        ProfileHeader(profile: profile)
                    }
                    MascotView(message: greeting)
                    dailyChallengeCard
                    subjectsSection
                    if !sets.isEmpty {
                        recentSetsSection
                    }
                }
                .padding()
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Hallo \(profile?.name ?? "")! 👋")
        }
        .sheet(item: $setupSet) { set in
            QuizSetupView(items: set.items, title: set.title)
        }
        .fullScreenCover(item: $dailyQuiz) { config in
            QuizView(config: config)
        }
        .alert("Bald verfügbar 🚧",
               isPresented: Binding(get: { lockedSubject != nil }, set: { if !$0 { lockedSubject = nil } }),
               presenting: lockedSubject) { _ in
            Button("Okay") {}
        } message: { subject in
            Text("\(subject.title) kommt in einem der nächsten Updates. Bis dahin: fleißig Vokabeln üben! 💪")
        }
    }

    private var greeting: String {
        guard let profile else { return "Hi! Ich bin Fuchsi. Lass uns Vokabeln lernen!" }
        if profile.xpToday >= profile.dailyGoal {
            return "Tagesziel geschafft! Du bist spitze! 🎉"
        }
        if profile.displayStreak > 0 {
            return "Halte deine 🔥 \(profile.displayStreak)-Tage-Serie am Leben! Noch \(profile.dailyGoal - profile.xpToday) XP bis zum Tagesziel."
        }
        if sets.isEmpty {
            return "Fotografiere deine erste Vokabelliste – ich lese sie für dich ein! 📸"
        }
        return "Hi \(profile.name)! Bereit für ein paar Vokabeln? 🚀"
    }

    // MARK: - Tägliche Übung

    private var dailyChallengeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎲").font(.largeTitle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tägliche Übung").font(.title3.bold())
                    Text("10 gemischte Fragen zu deinen schwierigsten Wörtern")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Button {
                dailyQuiz = QuizConfig(title: "Tägliche Übung",
                                       mode: .mixed,
                                       questionCount: 10,
                                       provider: VocabularyQuestionProvider(items: allItems))
            } label: {
                Label("Los geht's", systemImage: "play.fill")
            }
            .buttonStyle(GameButtonStyle(color: QuizMode.mixed.color))
            .disabled(allItems.isEmpty)
        }
        .card()
    }

    // MARK: - Fächer

    private var subjectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fächer").font(.title2.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
                ForEach(Subject.allCases) { subject in
                    Button {
                        Haptics.tap()
                        if subject.isAvailable {
                            selectedTab = .library
                        } else {
                            lockedSubject = subject
                        }
                    } label: {
                        SubjectCard(subject: subject)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Listen

    private var recentSetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weiter üben").font(.title2.bold())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(sets.prefix(8)) { set in
                        Button {
                            setupSet = set
                        } label: {
                            SetCard(set: set)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
        }
    }
}

struct ProfileHeader: View {
    let profile: PlayerProfile

    var body: some View {
        let progress = LevelSystem.progress(forXP: profile.totalXP)
        HStack(spacing: 16) {
            Text(profile.avatar)
                .font(.system(size: 44))
                .frame(width: 72, height: 72)
                .background(Theme.primary.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("Level \(progress.level) · \(LevelSystem.title(for: progress.level))")
                    .font(.headline)
                ProgressBar(value: Double(progress.current) / Double(progress.needed), color: Theme.primary)
                Text("\(progress.current) / \(progress.needed) XP")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(profile.displayStreak)")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Theme.flame)
                        .monospacedDigit()
                }
                ZStack {
                    RingProgress(value: profile.dailyGoalProgress, color: Theme.success, lineWidth: 6)
                    Text(profile.dailyGoalProgress >= 1 ? "✅" : "🎯").font(.caption)
                }
                .frame(width: 38, height: 38)
            }
        }
        .card()
    }
}

struct SubjectCard: View {
    let subject: Subject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subject.emoji).font(.system(size: 38))
                Spacer()
                if !subject.isAvailable {
                    Label("Bald", systemImage: "lock.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.gray.opacity(0.2), in: Capsule())
                }
            }
            Text(subject.title).font(.headline)
            Text(subject.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(subject.color.opacity(subject.isAvailable ? 0.18 : 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(subject.color.opacity(subject.isAvailable ? 0.5 : 0.15), lineWidth: 2)
        )
        .saturation(subject.isAvailable ? 1 : 0.3)
    }
}

struct SetCard: View {
    let set: VocabularySet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(set.language.flag).font(.largeTitle)
                Spacer()
                ZStack {
                    RingProgress(value: set.progress, color: Theme.success, lineWidth: 5)
                    Text("\(Int(set.progress * 100))%")
                        .font(.system(size: 10, weight: .bold))
                }
                .frame(width: 40, height: 40)
            }
            Text(set.title)
                .font(.headline)
                .lineLimit(2, reservesSpace: true)
            Text("\(set.items.count) Wörter · ⭐ \(set.masteredCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Label("Üben", systemImage: "play.circle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.primary)
        }
        .frame(width: 180, alignment: .leading)
        .card()
    }
}
