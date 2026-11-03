import Foundation

enum LevelSystem {
    static let titles = [
        "Wort-Neuling",
        "Wort-Sammler",
        "Vokabel-Entdecker",
        "Sprach-Abenteurer",
        "Wörter-Ritter",
        "Vokabel-Profi",
        "Sprach-Magier",
        "Vokabel-Held",
        "Sprach-Legende",
    ]

    /// XP, die man braucht, um von `level` auf `level + 1` zu kommen.
    static func xpNeeded(toAdvanceFrom level: Int) -> Int {
        100 + (level - 1) * 50
    }

    static func level(forXP xp: Int) -> Int {
        progress(forXP: xp).level
    }

    /// Level und Fortschritt innerhalb des aktuellen Levels.
    static func progress(forXP xp: Int) -> (level: Int, current: Int, needed: Int) {
        var level = 1
        var remaining = max(xp, 0)
        while remaining >= xpNeeded(toAdvanceFrom: level) {
            remaining -= xpNeeded(toAdvanceFrom: level)
            level += 1
        }
        return (level, remaining, xpNeeded(toAdvanceFrom: level))
    }

    static func title(for level: Int) -> String {
        let index = min(max(level - 1, 0), titles.count - 1)
        return titles[index]
    }
}
