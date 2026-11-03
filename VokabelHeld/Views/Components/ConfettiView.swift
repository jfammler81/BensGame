import SwiftUI

/// Konfetti-Regen für Erfolge.
struct ConfettiView: View {
    private struct Particle {
        let x: Double
        let delay: Double
        let speed: Double
        let wobble: Double
        let phase: Double
        let spin: Double
        let width: CGFloat
        let height: CGFloat
        let color: Color
    }

    private static let colors: [Color] = [Theme.primary, Theme.gold, Theme.success, Theme.danger, .pink, .orange, .cyan, .purple]

    @State private var particles: [Particle] = (0..<100).map { _ in
        Particle(x: Double.random(in: 0...1),
                 delay: Double.random(in: 0...0.9),
                 speed: Double.random(in: 0.25...0.5),
                 wobble: Double.random(in: 2...5),
                 phase: Double.random(in: 0...(2 * Double.pi)),
                 spin: Double.random(in: 2...8),
                 width: CGFloat.random(in: 6...10),
                 height: CGFloat.random(in: 10...16),
                 color: ConfettiView.colors.randomElement() ?? .pink)
    }
    @State private var start = Date.now
    @State private var isDone = false

    var body: some View {
        Group {
            if !isDone {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(start)
                    Canvas { context, size in
                        for particle in particles {
                            let t = elapsed - particle.delay
                            guard t > 0 else { continue }
                            let y = -20 + t * particle.speed * size.height
                            guard y < size.height + 20 else { continue }
                            let x = particle.x * size.width + sin(t * particle.wobble + particle.phase) * 18
                            var copy = context
                            copy.translateBy(x: x, y: y)
                            copy.rotate(by: .radians(t * particle.spin))
                            let rect = CGRect(x: -particle.width / 2, y: -particle.height / 2,
                                              width: particle.width, height: particle.height)
                            copy.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(particle.color))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .task {
            try? await Task.sleep(for: .seconds(6))
            isDone = true
        }
    }
}
