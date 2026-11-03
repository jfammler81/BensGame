import SwiftUI

/// Kleine Erfolgsmeldung, die oben eingeblendet wird.
struct ToastView: View {
    let emoji: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji).font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}

/// Leiste mit Sonderzeichen (é, ñ, ß …) zum schnellen Eintippen.
struct AccentBar: View {
    let languageCode: String
    var onInsert: (String) -> Void

    static func characters(for code: String) -> [String] {
        switch code.prefix(2) {
        case "fr": ["é", "è", "ê", "à", "â", "ç", "ô", "î", "ù", "û", "ë", "ï", "œ"]
        case "es": ["á", "é", "í", "ó", "ú", "ñ", "ü", "¿", "¡"]
        case "it": ["à", "è", "é", "ì", "ò", "ù"]
        case "nl": ["é", "ë", "ï", "ó", "ü"]
        case "de": ["ä", "ö", "ü", "ß"]
        default: []
        }
    }

    var body: some View {
        let characters = Self.characters(for: languageCode)
        if !characters.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(characters, id: \.self) { character in
                        Button {
                            onInsert(character)
                            Haptics.tap()
                        } label: {
                            Text(character)
                                .font(.title3.weight(.semibold))
                                .frame(minWidth: 40, minHeight: 40)
                                .background(Theme.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}
