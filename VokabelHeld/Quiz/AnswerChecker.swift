import Foundation

enum AnswerVerdict: Equatable {
    case correct
    /// Fast richtig (Tippfehler oder fehlender Akzent) – zählt als richtig.
    case almost
    case wrong
}

/// Vergleicht getippte Antworten tolerant mit der Lösung.
enum AnswerChecker {
    /// Artikel und „to“, die beim Vergleich ignoriert werden dürfen.
    static let articles: Set<String> = [
        "der", "die", "das", "den", "dem", "des", "ein", "eine", "einen",
        "the", "a", "an", "to",
        "le", "la", "les", "un", "une",
        "el", "los", "las", "una",
        "il", "lo", "gli",
        "het", "de", "een",
    ]

    static func verdict(for input: String, accepted: [String]) -> AnswerVerdict {
        let given = normalize(input)
        guard !given.isEmpty else { return .wrong }

        var best = AnswerVerdict.wrong
        for candidate in accepted.flatMap({ variants(of: $0) }) {
            let target = normalize(candidate)
            guard !target.isEmpty else { continue }

            if given == target || stripArticle(given) == stripArticle(target) {
                return .correct
            }

            let g = fold(stripArticle(given))
            let t = fold(stripArticle(target))
            if g == t {
                best = .almost
                continue
            }
            let tolerance = t.count >= 8 ? 2 : (t.count >= 4 ? 1 : 0)
            if tolerance > 0 && levenshtein(g, t) <= tolerance {
                best = .almost
            }
        }
        return best
    }

    /// Kleinbuchstaben, ohne überflüssige Leerzeichen und Satzzeichen am Rand.
    static func normalize(_ text: String) -> String {
        let lowered = text.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return lowered.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Alternativen: „laufen, rennen“ → [„laufen, rennen“, „laufen“, „rennen“]; Klammern sind optional.
    static func variants(of answer: String) -> [String] {
        var result = [answer]
        let withoutParentheses = answer.replacingOccurrences(of: "\\s*\\([^)]*\\)",
                                                             with: "",
                                                             options: .regularExpression)
        if withoutParentheses != answer {
            result.append(withoutParentheses)
        }
        let parts = withoutParentheses
            .split(whereSeparator: { ",;/".contains($0) })
            .map { String($0).trimmed }
            .filter { !$0.isEmpty }
        if parts.count > 1 {
            result += parts
        }
        return result
    }

    static func stripArticle(_ text: String) -> String {
        var result = text
        if result.hasPrefix("l'") {
            result = String(result.dropFirst(2))
        }
        let parts = result.split(separator: " ", maxSplits: 1).map(String.init)
        if parts.count == 2, articles.contains(parts[0]) {
            result = parts[1]
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Ignoriert Akzente und ß/ss.
    static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .replacingOccurrences(of: "ß", with: "ss")
    }

    static func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }
}
