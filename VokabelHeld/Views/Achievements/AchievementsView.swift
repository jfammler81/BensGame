import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var profiles: [PlayerProfile]
    @Query private var items: [VocabularyItem]

    @State private var showSettings = false
    @State private var selectedBadge: Badge?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile = profiles.first {
                        ProfileHeader(profile: profile)
                        statsGrid(profile)
                        badgesSection(profile)
                    }
                }
                .padding()
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Erfolge")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Profil", systemImage: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                if let profile = profiles.first {
                    ProfileSettingsView(profile: profile)
                }
            }
            .alert(selectedBadge?.title ?? "",
                   isPresented: Binding(get: { selectedBadge != nil }, set: { if !$0 { selectedBadge = nil } }),
                   presenting: selectedBadge) { _ in
                Button("Okay") {}
            } message: { badge in
                Text("\(badge.emoji) \(badge.description)")
            }
        }
    }

    private func statsGrid(_ profile: PlayerProfile) -> some View {
        let mastered = items.filter(\.isMastered).count
        return VStack(alignment: .leading, spacing: 12) {
            Text("Statistik").font(.title2.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                StatTile(emoji: "⭐", value: "\(profile.totalXP)", label: "Gesamt-XP")
                StatTile(emoji: "🔥", value: "\(profile.displayStreak)", label: "Aktuelle Serie")
                StatTile(emoji: "🏔️", value: "\(profile.longestStreak)", label: "Längste Serie")
                StatTile(emoji: "📚", value: "\(items.count)", label: "Vokabeln")
                StatTile(emoji: "🧠", value: "\(mastered)", label: "Gemeistert")
                StatTile(emoji: "🎮", value: "\(profile.quizzesCompleted)", label: "Quizze")
                StatTile(emoji: "🎯", value: "\(Int((profile.accuracy * 100).rounded()))%", label: "Genauigkeit")
                StatTile(emoji: "⚡", value: "\(profile.blitzBest)", label: "Blitz-Rekord")
            }
        }
    }

    private func badgesSection(_ profile: PlayerProfile) -> some View {
        let unlocked = Set(profile.unlockedBadgeIDs)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Abzeichen").font(.title2.bold())
                Spacer()
                Text("\(unlocked.count) / \(BadgeCatalog.all.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(BadgeCatalog.all) { badge in
                    Button {
                        selectedBadge = badge
                    } label: {
                        BadgeCell(badge: badge, isUnlocked: unlocked.contains(badge.id))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct BadgeCell: View {
    let badge: Badge
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Text(badge.emoji)
                    .font(.system(size: 44))
                    .frame(width: 72, height: 72)
                    .background(
                        Circle().fill(isUnlocked ? Theme.gold.opacity(0.25) : Color.gray.opacity(0.12))
                    )
                    .grayscale(isUnlocked ? 0 : 1)
                    .opacity(isUnlocked ? 1 : 0.45)
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption.bold())
                        .padding(6)
                        .background(.thinMaterial, in: Circle())
                }
            }
            Text(badge.title)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(badge.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 12)
    }
}
