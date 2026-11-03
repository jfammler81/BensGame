# VokabelHeld 🦊

Eine iOS-App für **iPhone und iPad**, mit der man Vokabeln in verschiedenen Sprachen spielerisch lernt.
Die Vokabeln werden einfach **abfotografiert** – die App erkennt den Text automatisch und macht daraus eine Vokabelliste.

## Funktionen

### 📸 Vokabeln per Foto hinzufügen
- Foto mit der Kamera aufnehmen oder aus der Fotomediathek wählen
- Automatische Texterkennung direkt auf dem Gerät (Apple Vision, keine Cloud)
- Erkennt zweispaltige Listen (z. B. `dog | Hund`), Listen mit Lautschrift und Zeilen mit Trennzeichen (`dog - Hund`, `chien = Hund`, `perro: Hund`)
- Erkennt automatisch, welche Spalte Deutsch ist; „Spalten tauschen“ per Knopfdruck
- Alle erkannten Wörter können vor dem Speichern bearbeitet werden; manuelle Eingabe ist ebenfalls möglich
- Sprachen: Englisch, Französisch, Spanisch, Italienisch, Latein, Niederländisch
- Bei Nicht-Englisch-Listen kann zusätzlich die englische Bedeutung gespeichert werden

### 🎯 Übungsarten
| Modus | Beschreibung |
|---|---|
| **Auswählen** | Richtige Übersetzung aus 4 Antworten wählen (in beide Richtungen) |
| **Vokabeln schreiben** | Deutsches Wort wird angezeigt, die Vokabel in der Fremdsprache eintippen |
| **Was heißt das auf Deutsch?** | Fremdwort wird angezeigt, deutsche Bedeutung eintippen |
| **Was heißt das auf Englisch?** | Englische Bedeutung eintippen |
| **Mix-Challenge** | Alle Übungsarten gemischt |
| **Blitzrunde** | 60 Sekunden – so viele richtige Antworten wie möglich |

Tolerante Auswertung: Groß-/Kleinschreibung, Artikel (`der/die/das`, `the`, `to`, `le/la` …), Alternativen (`laufen, rennen`) und kleine Tippfehler oder fehlende Akzente werden als „fast richtig“ gewertet.
Eine Sonderzeichen-Leiste (é, ñ, ß …) hilft beim Tippen, und jedes Wort kann man sich vorlesen lassen 🔊.

### 🎮 Gamification
- **XP & Level** mit Titeln vom „Wort-Neuling“ bis zur „Sprach-Legende“
- **Combos** 🔥 – Bonus-XP für richtige Antworten am Stück
- **Tagesziel** & **Serie (Streak)** – jeden Tag üben lohnt sich
- **18 Abzeichen** (z. B. „Fehlerlos“, „Combo-König“, „Blitzschnell“, „Vokabel-Meister“)
- **Joker** 🪄 – bei Schreibaufgaben Antwortmöglichkeiten anzeigen (halbe XP)
- **Sterne-Bewertung**, Konfetti, Haptik-Feedback und Maskottchen „Fuchsi“ 🦊
- **Karteikasten-Prinzip**: Jedes Wort hat eine Lernstufe (0–5). Schwierige Wörter kommen öfter dran, die „Tägliche Übung“ fragt gezielt die schwächsten Wörter ab

## Projekt öffnen

Voraussetzungen: **Xcode 16** oder neuer, iOS 17+.

1. `VokabelHeld.xcodeproj` in Xcode öffnen
2. Unter *Signing & Capabilities* das eigene Team auswählen (ggf. Bundle-ID `com.bensgame.vokabelheld` anpassen)
3. iPhone- oder iPad-Simulator bzw. eigenes Gerät wählen und starten (⌘R)

Beim ersten Start werden zwei Beispiel-Listen angelegt, damit man direkt loslegen kann.
Die Kamera funktioniert nur auf einem echten Gerät – im Simulator kann man Fotos aus der Mediathek verwenden.

## Architektur

```
VokabelHeld/
├── App/            App-Einstieg und Tab-Navigation
├── Models/         SwiftData-Modelle (VocabularySet, VocabularyItem, PlayerProfile), Subject, Language
├── Quiz/           Fachunabhängige Quiz-Engine: QuizMode, QuizQuestion, QuestionProvider, QuizSession, AnswerChecker
├── Gamification/   Level-System, Abzeichen, Belohnungen
├── Services/       Texterkennung (Vision), Vokabel-Parser, Sprachausgabe, Haptik, Beispieldaten
└── Views/          SwiftUI-Oberflächen (Start, Vokabeln, Quiz, Erfolge, Komponenten)
```

- **SwiftUI + SwiftData**, keine externen Abhängigkeiten
- Alle Daten bleiben lokal auf dem Gerät
- Layouts passen sich an iPhone (Hochformat) und iPad (alle Ausrichtungen) an

## Erweiterung um weitere Fächer (z. B. Deutsch, Mathematik)

Die App ist so aufgebaut, dass neue Fächer in einem späteren Release ohne Umbau ergänzt werden können:

1. **`Subject`** (`Models/Subject.swift`) enthält bereits `german` und `math` – sie werden auf dem Startbildschirm als „Bald verfügbar“ angezeigt. Zum Freischalten `isAvailable` anpassen.
2. **`QuestionProvider`** (`Quiz/QuestionProvider.swift`) ist das Protokoll, über das ein Fach seine Aufgaben liefert. Ein neues Fach implementiert einfach einen eigenen Provider, z. B.:

   ```swift
   struct MathQuestionProvider: QuestionProvider {
       func makeQuestions(mode: QuizMode, count: Int?) -> [QuizQuestion] {
           (0..<(count ?? 10)).map { _ in
               let a = Int.random(in: 2...10), b = Int.random(in: 2...10)
               return QuizQuestion(item: nil,
                                   instruction: "Rechne aus",
                                   prompt: "\(a) × \(b)",
                                   promptSpeechCode: nil,
                                   correctAnswer: "\(a * b)",
                                   acceptedAnswers: ["\(a * b)"],
                                   options: [],
                                   style: .typing,
                                   answerLanguageCode: "de-DE")
           }
       }
   }
   ```
3. **Quiz-Ablauf, XP, Combos, Serien und Abzeichen** (`QuizSession`, `RewardService`) sind fachunabhängig und funktionieren automatisch mit.
4. `VocabularySet` speichert bereits ein `subjectCode`, sodass Listen später einem Fach zugeordnet werden können.

## Build-Prüfung

Bei jedem Push baut ein GitHub-Actions-Workflow (`.github/workflows/ios-build.yml`) die App für den iOS-Simulator.
