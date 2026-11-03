import Foundation
import CoreGraphics

/// Ein erkanntes Vokabelpaar, das vor dem Speichern noch bearbeitet werden kann.
struct ParsedPair: Identifiable, Equatable {
    var id = UUID()
    var term: String
    var german: String
    var english: String = ""

    var isComplete: Bool { !term.trimmed.isEmpty && !german.trimmed.isEmpty }
}

/// Macht aus erkannten Textblöcken Vokabelpaare.
///
/// Unterstützt die üblichen Layouts:
/// - zwei Spalten (Fremdsprache | Deutsch), auch mit Lautschrift in der Mitte
/// - eine Zeile mit Trennzeichen, z. B. „dog - Hund“, „chien = Hund“, „perro: Hund“
enum VocabularyParser {
    static let separators = [" - ", " – ", " — ", " ‒ ", "->", "→", "=", ":", "\t", ";"]

    static func parse(_ texts: [RecognizedText]) -> [ParsedPair] {
        var pairs: [ParsedPair] = []
        for row in groupIntoRows(texts) {
            let cells = row.map { clean($0.text) }.filter { !$0.isEmpty && !isNoise($0) }
            guard !cells.isEmpty else { continue }

            if cells.count == 1 {
                if let pair = split(cells[0]) {
                    pairs.append(pair)
                } else {
                    pairs.append(ParsedPair(term: cells[0], german: ""))
                }
                continue
            }

            // Lautschrift wie [dɒg] oder /dɒg/ überspringen.
            let meaningful = cells.filter { !isPhonetic($0) }
            if meaningful.count >= 2 {
                pairs.append(ParsedPair(term: meaningful[0], german: meaningful[meaningful.count - 1]))
            } else if let only = meaningful.first {
                if let pair = split(only) {
                    pairs.append(pair)
                } else {
                    pairs.append(ParsedPair(term: only, german: ""))
                }
            }
        }
        return orient(pairs)
    }

    /// Gruppiert Textblöcke, die auf gleicher Höhe liegen, zu Zeilen (von oben nach unten, links nach rechts).
    static func groupIntoRows(_ texts: [RecognizedText]) -> [[RecognizedText]] {
        let sorted = texts.sorted { $0.box.midY > $1.box.midY }
        let heights = sorted.map(\.box.height).sorted()
        let median = heights.isEmpty ? 0.02 : heights[heights.count / 2]
        let threshold = max(median * 0.6, 0.005)

        var rows: [[RecognizedText]] = []
        var rowCenters: [CGFloat] = []
        for text in sorted {
            if let lastCenter = rowCenters.last, abs(lastCenter - text.box.midY) < threshold {
                rows[rows.count - 1].append(text)
                let row = rows[rows.count - 1]
                rowCenters[rowCenters.count - 1] = row.map(\.box.midY).reduce(0, +) / CGFloat(row.count)
            } else {
                rows.append([text])
                rowCenters.append(text.box.midY)
            }
        }
        return rows.map { $0.sorted { $0.box.minX < $1.box.minX } }
    }

    static func split(_ text: String) -> ParsedPair? {
        for separator in separators where text.contains(separator) {
            let parts = text.components(separatedBy: separator)
            let left = parts[0].trimmed
            let right = parts.dropFirst().joined(separator: separator).trimmed
            if !left.isEmpty && !right.isEmpty {
                return ParsedPair(term: left, german: right)
            }
        }
        return nil
    }

    /// Entfernt Aufzählungszeichen und Nummerierungen am Zeilenanfang.
    static func clean(_ text: String) -> String {
        let withoutBullets = text.replacingOccurrences(of: "^\\s*(\\d{1,3}[\\.\\)]|[•·*▪■□–-])\\s*",
                                                       with: "",
                                                       options: .regularExpression)
        return withoutBullets.split(whereSeparator: \.isWhitespace).joined(separator: " ").trimmed
    }

    /// Seitenzahlen, einzelne Zeichen usw.
    static func isNoise(_ text: String) -> Bool {
        if text.count <= 1 { return true }
        return text.allSatisfy { $0.isNumber || $0.isPunctuation || $0.isWhitespace }
    }

    static func isPhonetic(_ text: String) -> Bool {
        (text.hasPrefix("[") && text.hasSuffix("]")) || (text.hasPrefix("/") && text.hasSuffix("/"))
    }

    /// Sorgt dafür, dass die deutsche Spalte in `german` landet.
    static func orient(_ pairs: [ParsedPair]) -> [ParsedPair] {
        let termScore = pairs.reduce(0) { $0 + germanScore($1.term) }
        let germanColumnScore = pairs.reduce(0) { $0 + germanScore($1.german) }
        guard termScore > germanColumnScore else { return pairs }
        return pairs.map { ParsedPair(id: $0.id, term: $0.german, german: $0.term, english: $0.english) }
    }

    static func germanScore(_ text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        let lower = text.lowercased()
        var score = 0
        if lower.contains(where: { "äöüß".contains($0) }) { score += 3 }
        let firstWord = lower.split(separator: " ").first.map(String.init) ?? ""
        if ["der", "die", "das", "ein", "eine", "sich"].contains(firstWord) { score += 3 }
        if lower.hasSuffix("en") || lower.hasSuffix("ung") || lower.hasSuffix("keit") { score += 1 }
        return score
    }
}
