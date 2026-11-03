import UIKit
import Vision

/// Ein erkannter Textblock mit Position (normalisiert, Ursprung unten links).
struct RecognizedText {
    let text: String
    let box: CGRect
}

/// Texterkennung auf Fotos mit Apples Vision-Framework (läuft komplett auf dem Gerät).
enum TextRecognizer {
    static func recognize(in image: UIImage, preferredLanguages: [String]) async throws -> [RecognizedText] {
        // Bild neu zeichnen, damit die Ausrichtung immer „oben“ ist.
        let normalized = image.resized(maxDimension: 2400)
        guard let cgImage = normalized.cgImage else { return [] }

        return try await Task.detached(priority: .userInitiated) { () throws -> [RecognizedText] in
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let supported = (try? request.supportedRecognitionLanguages()) ?? []
            var chosen: [String] = []
            for code in preferredLanguages {
                let prefix = String(code.prefix(2))
                let match = supported.first(where: { $0 == code })
                    ?? supported.first(where: { $0.hasPrefix(prefix) })
                if let match, !chosen.contains(match) {
                    chosen.append(match)
                }
            }
            if !chosen.isEmpty {
                request.recognitionLanguages = chosen
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            try handler.perform([request])

            let observations = request.results ?? []
            return observations.compactMap { observation -> RecognizedText? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return RecognizedText(text: candidate.string, box: observation.boundingBox)
            }
        }.value
    }
}
