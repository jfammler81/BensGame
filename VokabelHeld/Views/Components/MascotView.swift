import SwiftUI

/// „Fuchsi“, das Maskottchen der App, mit Sprechblase.
struct MascotView: View {
    var message: String
    var emoji: String = "🦊"

    @State private var bounce = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Text(emoji)
                .font(.system(size: 52))
                .rotationEffect(.degrees(bounce ? -5 : 5))
                .offset(y: bounce ? -5 : 0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        bounce = true
                    }
                }

            Text(message)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Theme.card, in: SpeechBubble())
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)

            Spacer(minLength: 0)
        }
    }
}

struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: 18, style: .continuous)
        var tail = Path()
        tail.move(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 22))
        tail.addLine(to: CGPoint(x: rect.minX - 9, y: rect.maxY - 6))
        tail.addLine(to: CGPoint(x: rect.minX + 14, y: rect.maxY - 10))
        tail.closeSubpath()
        path.addPath(tail)
        return path
    }
}
