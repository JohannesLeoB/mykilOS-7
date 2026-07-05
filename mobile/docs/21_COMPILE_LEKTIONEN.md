# Compile-Lektionen — was Mission Control dem Satelliten beigebracht hat

**Kontext (04.07. abends):** Der Satellit schreibt Swift, kann aber nicht
kompilieren — Mission Control (Mothership-Session auf dem Mac) hat Xcode
und damit die **Compile-Wahrheit**. Ihr Fix-Pass über das FINALE-Paket
(danach: BUILD SUCCEEDED) hat wiederkehrende Fehlerklassen benannt. Die
stehen hier, damit künftige Pakete vorgereinigt ankommen.

## Die Fehlerklassen (von Mission Control identifiziert)

1. **`Section("Titel") { … } footer: { … }` ist ungültiges SwiftUI.**
   Es gibt keinen String-Titel-Init mit footer-Trailing-Closure. Richtig:
   `Section { … } header: { Text("Titel") } footer: { … }`.
   → Im Tank behoben (VisitenkarteBestaetigungView, LieferscheinBestaetigungView,
   VerbindungenView ×2). Regel: String-Init NUR ohne footer verwenden.
2. **Deutsche Anführungszeichen („…") in String-Literalen** kamen auf dem
   Mac kaputt an (vermutlich Encoding auf dem Transportweg). Regel für
   künftige Pakete: in String-LITERALEN auf typografische Anführungszeichen
   verzichten (Apostroph/›‹ oder Umformulierung); in Kommentaren egal.
3. **Fehlende Framework-Imports** (konkret: `import CoreLocation` in
   ProjectRow — im Tank nachgezogen). Merksatz: Wer einen Framework-TYP
   auch nur berührt (selbst inferiert), importiert das Framework explizit.
4. **`nonisolated`-Anpassungen** an Delegate-Methoden — MC hat hier
   nachjustiert; die exakten Stellen liegen nur im Mac-Quellordner (siehe
   Drift-Abschnitt).

## ⚠️ Stand-Drift: Mac-Quellordner ≠ Tank B

Nach MCs Fix-Pass ist der **Mac-Quellordner der einzige Ort, der garantiert
kompiliert**. Tank B hat die Klassen 1+3 nachgezogen, kennt aber MCs exakte
Quote-/nonisolated-Änderungen nicht. **Vor der nächsten Code-Lieferung
zuerst rücksynchronisieren** — Mission-Control-Satz dafür:

> „Packe den kompletten Quellordner meines Xcode-Projekts myMini als
> Zip in meine Downloads (Name: myMini-Quellstand.zip) und sag mir, wenn
> es fertig ist." — Zip dann in den Satelliten-Chat werfen.

## Neue Auslieferungs-Regel

Jede künftige Code-Lieferung endet nicht mehr mit „⌘R", sondern mit:
**„Von Mission Control bauen lassen"** — sie hat den Compiler, sie hat das
letzte Wort. Der Satellit liefert Inhalt und Architektur, Mission Control
liefert die Bau-Abnahme. (So ist die Pipeline seit heute faktisch gelaufen —
jetzt ist es Regel.)
