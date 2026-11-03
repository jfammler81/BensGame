import SwiftUI

/// Auswahl der Übungsart und Anzahl der Fragen.
struct QuizSetupView: View {
    let items: [VocabularyItem]
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var mode: QuizMode = .multipleChoice
    @State private var count = 10
    @State private var config: QuizConfig?

    private static let countOptions = [5, 10, 20, 0]

    private var hasEnglishMeanings: Bool {
        items.contains { $0.englishMeaning != nil }
    }

    private func isAvailable(_ mode: QuizMode) -> Bool {
        mode == .meaningEnglish ? hasEnglishMeanings : true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    MascotView(message: "Wie möchtest du heute üben? Du hast \(items.count) Wörter in dieser Liste.")

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                        ForEach(QuizMode.allCases) { option in
                            Button {
                                guard isAvailable(option) else { return }
                                Haptics.tap()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    mode = option
                                }
                            } label: {
                                ModeCard(mode: option,
                                         isSelected: mode == option,
                                         isAvailable: isAvailable(option))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !hasEnglishMeanings {
                        Text("💡 Tipp: Trage bei deinen Vokabeln die englische Bedeutung ein, um „Was heißt das auf Englisch?“ freizuschalten.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if mode == .blitz {
                        Text("⏱️ \(QuizSession.blitzDuration) Sekunden – beantworte so viele Fragen wie möglich!")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Anzahl Fragen").font(.headline)
                            Picker("Anzahl Fragen", selection: $count) {
                                ForEach(Self.countOptions, id: \.self) { value in
                                    Text(value == 0 ? "Alle" : "\(value)").tag(value)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    Button {
                        Haptics.heavy()
                        config = QuizConfig(title: title,
                                            mode: mode,
                                            questionCount: count == 0 ? nil : count,
                                            provider: VocabularyQuestionProvider(items: items))
                    } label: {
                        Text("Los geht's! 🚀")
                    }
                    .buttonStyle(GameButtonStyle(color: mode.color))
                    .disabled(items.isEmpty)
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .fullScreenCover(item: $config, onDismiss: { dismiss() }) { config in
            QuizView(config: config)
        }
    }
}

struct ModeCard: View {
    let mode: QuizMode
    let isSelected: Bool
    let isAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mode.emoji)
                    .font(.system(size: 30))
                    .frame(width: 50, height: 50)
                    .background(mode.color.opacity(0.18), in: Circle())
                Spacer()
                if !isAvailable {
                    Image(systemName: "lock.fill").foregroundStyle(.secondary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(mode.color)
                        .transition(.scale)
                }
            }
            Text(mode.title)
                .font(.headline)
                .lineLimit(2, reservesSpace: true)
            Text(mode.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? mode.color : Color.clear, lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .scaleEffect(isSelected ? 1.03 : 1)
        .opacity(isAvailable ? 1 : 0.5)
    }
}
