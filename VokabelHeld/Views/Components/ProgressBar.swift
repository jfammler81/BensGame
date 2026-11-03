import SwiftUI

struct ProgressBar: View {
    var value: Double
    var color: Color = Theme.primary
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { geometry in
            let clamped = min(max(value, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.18))
                Capsule()
                    .fill(color.gradient)
                    .frame(width: clamped == 0 ? 0 : max(height, geometry.size.width * clamped))
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.white.opacity(0.35))
                            .frame(height: height * 0.25)
                            .padding(.horizontal, height * 0.4)
                            .padding(.top, height * 0.2)
                    }
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: value)
    }
}

struct RingProgress: View {
    var value: Double
    var color: Color
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
    }
}

/// Lernstufe einer Vokabel als 5 Punkte.
struct MasteryDots: View {
    let box: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<Mastery.maxBox, id: \.self) { index in
                Circle()
                    .fill(index < box ? color : Color.gray.opacity(0.25))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityLabel("Lernstufe \(box) von \(Mastery.maxBox)")
    }

    private var color: Color {
        box >= Mastery.maxBox ? Theme.gold : Theme.success
    }
}

struct StatTile: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title2)
            Text(value)
                .font(.title3.weight(.heavy))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 12)
    }
}
