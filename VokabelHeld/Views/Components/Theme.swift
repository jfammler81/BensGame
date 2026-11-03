import SwiftUI

enum Theme {
    static let primary = Color(red: 0.36, green: 0.40, blue: 0.98)
    static let success = Color(red: 0.18, green: 0.76, blue: 0.42)
    static let danger = Color(red: 0.95, green: 0.32, blue: 0.36)
    static let warning = Color(red: 1.0, green: 0.62, blue: 0.1)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.18)
    static let flame = Color(red: 1.0, green: 0.48, blue: 0.14)
    static let card = Color(.secondarySystemGroupedBackground)

    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [primary.opacity(0.16), Color(.systemGroupedBackground)],
                       startPoint: .top,
                       endPoint: .center)
    }
}

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

/// Bunter „3D“-Knopf im Spiele-Look.
struct GameButtonStyle: ButtonStyle {
    var color: Color = Theme.primary
    var foreground: Color = .white

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let fill = isEnabled ? color : Color.gray.opacity(0.5)
        return configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous).fill(fill)
            )
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(fill)
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.black.opacity(0.25))
                }
                .offset(y: pressed ? 0 : 5)
            )
            .offset(y: pressed ? 5 : 0)
            .padding(.bottom, 5)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
    }
}

/// Wackel-Effekt bei falschen Antworten.
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 4), y: 0))
    }
}
