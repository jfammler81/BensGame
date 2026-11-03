import SwiftUI
import SwiftData

/// Das eigentliche Quiz (Vollbild).
struct QuizView: View {
    let config: QuizConfig

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var session: QuizSession
    @State private var typedAnswer = ""
    @State private var selectedOption: String?
    @State private var reward: QuizReward?
    @State private var showQuitConfirm = false
    @State private var shake: CGFloat = 0
    @State private var comboPulse = false
    @FocusState private var inputFocused: Bool

    init(config: QuizConfig) {
        self.config = config
        _session = State(initialValue: config.makeSession())
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            if session.questions.isEmpty {
                emptyState
            } else if session.isFinished {
                QuizResultView(session: session,
                               reward: reward,
                               onRepeat: restart,
                               onClose: { dismiss() })
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else if let question = session.current {
                quizContent(question)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: session.isFinished)
        .task(id: session.id) {
            await runBlitzTimer()
        }
        .confirmationDialog("Runde beenden?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
            Button("Beenden", role: .destructive) { quit() }
            Button("Weiterspielen", role: .cancel) {}
        } message: {
            Text("Deine bisher gesammelten XP bleiben erhalten.")
        }
    }

    // MARK: - Layout

    private func quizContent(_ question: QuizQuestion) -> some View {
        VStack(spacing: 20) {
            topBar

            Spacer(minLength: 0)

            QuestionCard(question: question)
                .modifier(ShakeEffect(animatableData: shake))
                .id(question.id)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))

            Spacer(minLength: 0)

            if session.currentStyle == .choice {
                choiceGrid(question)
            } else {
                typingArea(question)
            }

            bottomBar
        }
        .padding()
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                showQuitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }

            ProgressBar(value: session.progress, color: config.mode.color, height: 16)

            if config.mode == .blitz {
                Label("\(session.timeRemaining)s", systemImage: "timer")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(session.timeRemaining <= 10 ? Theme.danger : .primary)
            }

            if session.combo >= 2 {
                Text("🔥 \(session.combo)")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.flame)
                    .scaleEffect(comboPulse ? 1.35 : 1)
                    .transition(.scale)
            }

            Text("⭐ \(session.xpEarned)")
                .font(.headline.weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: session.combo)
    }

    private func choiceGrid(_ question: QuizQuestion) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(question.options, id: \.self) { option in
                OptionButton(text: option, state: optionState(option, question: question)) {
                    choose(option)
                }
                .disabled(session.feedback != nil)
            }
        }
    }

    private func typingArea(_ question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            TextField("Deine Antwort …", text: $typedAnswer)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($inputFocused)
                .onSubmit(checkTypedAnswer)
                .padding()
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(inputBorderColor, lineWidth: 3)
                )
                .disabled(session.feedback != nil)

            if session.feedback == nil {
                AccentBar(languageCode: question.answerLanguageCode) { character in
                    typedAnswer.append(character)
                }

                if session.canUseJoker {
                    Button {
                        Haptics.tap()
                        withAnimation(.spring()) { session.useJoker() }
                    } label: {
                        Label("Joker: Antworten zeigen (½ XP)", systemImage: "wand.and.stars")
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(config.mode.color)
                }
            }
        }
        .onAppear { inputFocused = true }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if let feedback = session.feedback, config.mode != .blitz {
            FeedbackPanel(feedback: feedback, onContinue: advance)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else if session.currentStyle == .typing && session.feedback == nil {
            Button("Prüfen", action: checkTypedAnswer)
                .buttonStyle(GameButtonStyle(color: config.mode.color))
                .disabled(typedAnswer.trimmed.isEmpty)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Text("🤷").font(.system(size: 70))
            Text("Keine passenden Vokabeln").font(.title2.bold())
            Text("Für diese Übungsart fehlen noch Wörter. Füge zuerst Vokabeln hinzu.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Zurück") { dismiss() }
                .buttonStyle(GameButtonStyle())
                .frame(maxWidth: 280)
        }
        .padding(32)
    }

    private var inputBorderColor: Color {
        guard let feedback = session.feedback else { return config.mode.color.opacity(0.4) }
        switch feedback.verdict {
        case .correct: return Theme.success
        case .almost: return Theme.warning
        case .wrong: return Theme.danger
        }
    }

    private func optionState(_ option: String, question: QuizQuestion) -> OptionButton.Status {
        guard session.feedback != nil else {
            return option == selectedOption ? .selected : .idle
        }
        if option == question.correctAnswer { return .correct }
        if option == selectedOption { return .wrong }
        return .dimmed
    }

    // MARK: - Aktionen

    private func choose(_ option: String) {
        guard session.feedback == nil else { return }
        selectedOption = option
        react(to: session.submit(option))
    }

    private func checkTypedAnswer() {
        guard session.feedback == nil, !typedAnswer.trimmed.isEmpty else { return }
        react(to: session.submit(typedAnswer))
    }

    private func react(to verdict: AnswerVerdict) {
        switch verdict {
        case .correct, .almost:
            Haptics.success()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { comboPulse = true }
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                withAnimation(.spring()) { comboPulse = false }
            }
        case .wrong:
            Haptics.error()
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
        }

        if config.mode == .blitz {
            let sessionID = session.id
            Task {
                try? await Task.sleep(for: .milliseconds(verdict == .wrong ? 700 : 350))
                if session.id == sessionID { advance() }
            }
        }
    }

    private func advance() {
        guard session.feedback != nil else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            session.next()
        }
        typedAnswer = ""
        selectedOption = nil
        finalizeIfNeeded()
        if !session.isFinished && session.currentStyle == .typing {
            inputFocused = true
        }
    }

    private func finalizeIfNeeded() {
        guard session.isFinished, reward == nil, session.answeredCount > 0 else { return }
        inputFocused = false
        reward = RewardService.apply(session: session, context: context)
        Haptics.success()
    }

    private func runBlitzTimer() async {
        guard config.mode == .blitz else { return }
        while !session.isFinished {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            session.tick()
            if session.timeRemaining == 5 { Haptics.warning() }
        }
        finalizeIfNeeded()
    }

    private func restart() {
        typedAnswer = ""
        selectedOption = nil
        reward = nil
        withAnimation {
            session = config.makeSession()
        }
    }

    private func quit() {
        if reward == nil && session.answeredCount > 0 {
            _ = RewardService.apply(session: session, context: context, completed: false)
        }
        dismiss()
    }
}

// MARK: - Bausteine

struct QuestionCard: View {
    let question: QuizQuestion

    var body: some View {
        VStack(spacing: 16) {
            Text(question.instruction.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(question.prompt)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)
                .lineLimit(3)

            if let code = question.promptSpeechCode {
                Button {
                    SpeechService.shared.speak(question.prompt, languageCode: code)
                } label: {
                    Label("Anhören", systemImage: "speaker.wave.2.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .card()
    }
}

struct OptionButton: View {
    enum Status {
        case idle, selected, correct, wrong, dimmed
    }

    let text: String
    let state: Status
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity)
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                } else if state == .wrong {
                    Image(systemName: "xmark.circle.fill")
                }
            }
            .foregroundStyle(foreground)
            .padding(.vertical, 18)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(border, lineWidth: 3)
            )
            .scaleEffect(state == .correct ? 1.04 : 1)
            .opacity(state == .dimmed ? 0.45 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: state)
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch state {
        case .idle, .dimmed: Theme.card
        case .selected: Theme.primary.opacity(0.15)
        case .correct: Theme.success.opacity(0.2)
        case .wrong: Theme.danger.opacity(0.2)
        }
    }

    private var border: Color {
        switch state {
        case .idle, .dimmed: Color.gray.opacity(0.2)
        case .selected: Theme.primary
        case .correct: Theme.success
        case .wrong: Theme.danger
        }
    }

    private var foreground: Color {
        switch state {
        case .correct: Theme.success
        case .wrong: Theme.danger
        default: .primary
        }
    }
}

struct FeedbackPanel: View {
    let feedback: AnswerFeedback
    let onContinue: () -> Void

    private var color: Color {
        switch feedback.verdict {
        case .correct: Theme.success
        case .almost: Theme.warning
        case .wrong: Theme.danger
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(feedback.message)
                        .font(.title3.bold())
                        .foregroundStyle(color)
                    if feedback.verdict != .correct {
                        Text("Richtig: \(feedback.correctAnswer)")
                            .font(.headline)
                    }
                }
                Spacer()
                if feedback.xp > 0 {
                    Text("+\(feedback.xp) XP")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.gold.opacity(0.18), in: Capsule())
                }
            }
            Button("Weiter", action: onContinue)
                .buttonStyle(GameButtonStyle(color: color))
        }
        .padding()
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
