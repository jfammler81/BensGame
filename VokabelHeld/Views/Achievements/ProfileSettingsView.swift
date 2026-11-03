import SwiftUI
import SwiftData

struct ProfileSettingsView: View {
    @Bindable var profile: PlayerProfile
    @Environment(\.dismiss) private var dismiss

    private let avatars = ["🦊", "🐼", "🐯", "🦁", "🐸", "🐵", "🦄", "🐲", "🐙", "🐧", "🦖", "🐨", "🐶", "🐱", "🦉", "🐝"]
    private let goals: [(Int, String)] = [(30, "Locker"), (50, "Normal"), (100, "Ehrgeizig"), (200, "Profi")]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Dein Name", text: $profile.name)
                }

                Section("Avatar") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], spacing: 8) {
                        ForEach(avatars, id: \.self) { avatar in
                            Button {
                                Haptics.tap()
                                profile.avatar = avatar
                            } label: {
                                Text(avatar)
                                    .font(.system(size: 32))
                                    .frame(width: 52, height: 52)
                                    .background(
                                        Circle().fill(profile.avatar == avatar ? Theme.primary.opacity(0.25) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Picker("Tagesziel", selection: $profile.dailyGoal) {
                        ForEach(goals, id: \.0) { goal in
                            Text("\(goal.1) – \(goal.0) XP").tag(goal.0)
                        }
                    }
                } header: {
                    Text("Tagesziel")
                } footer: {
                    Text("Erreiche jeden Tag dein Ziel, um deine 🔥 Serie zu verlängern.")
                }

                Section("Über VokabelHeld") {
                    LabeledContent("Version", value: "1.0")
                    Text("Bald gibt es auch die Fächer Deutsch 📖 und Mathematik 🧮.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
