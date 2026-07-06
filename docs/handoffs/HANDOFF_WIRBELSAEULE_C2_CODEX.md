# HANDOFF — Wirbelsäule C2: Erste native Ports (für Codex)

**Für Codex-Sessions.** Folge zusätzlich `docs/codex/WORKFLOW.md` (verbindlich: Persistenz,
Token-Disziplin, Architektur-Schichtgrenzen, Session-Ablauf, Handoff-Pflicht).

## 0. ⛔ REALITY CHECK — ZUERST, VOR JEDER ANDEREN AKTION

**Ignoriere jeden mykilOS-Kontext aus früheren Gesprächen in dieser Codex-Umgebung.** Nur was du
JETZT unten mit den Befehlen tatsächlich siehst, zählt. Führe diese vier Befehle aus und
vergleiche das Ergebnis Zeile für Zeile mit dem Soll-Block:

```bash
pwd
git branch --show-current
git status --short
git log --oneline -1
```

**Soll:**
```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac
Branch: feat/mykilos8-block-d-provisioning
Status: (leer — clean)
Head:   0a31fef docs(codex): C2-Handoff — erste native Ports (...)   [oder neuer]
```

**Wenn IRGENDEINE Zeile abweicht (falscher Pfad, falscher Branch, unsauberer Status, anderer
Head als erwartet oder älter): STOPP. Nicht weiterarbeiten, nicht raten, nicht "wahrscheinlich
meint er trotzdem..." — Abweichung in eigenen Worten benennen und auf Anweisung warten.** Ein
falscher Ordner oder Branch bedeutet: diese Session baut auf einer anderen Realität als der, die
dieser Handoff beschreibt — jede Zeile Code danach wäre wertlos oder schädlich.

Erst wenn alle vier Zeilen übereinstimmen, weiter mit Schritt 1.

---

## 1. Vor dem Start — Pflichtlektüre

1. `docs/S10_WIRBELSAEULE.md` — der volle Blueprint (§1–§12). **Autoritativ.** Diese Session baut
   §4 „Erste native Ports" (C2) auf dem in C1 gelegten Fundament.
2. `Sources/MykilosKit/Domain/Wirbelsaeule/WirbelsaeuleFoundation.swift` — das C1-Fundament, das
   du hier konsumierst: `Pick`, `BasicPick`, `WorkBasket`, `CheckoutPort` (Protokoll!),
   `PortRegistry`, `CatalogObjectID`, `InhaltsArt`, `PortZiel`, `CheckoutPreview`, `CheckoutResult`.
3. `Tests/MykilosKitTests/WirbelsaeuleFoundationTests.swift` — zeigt das erwartete Nutzungsmuster
   (`TestPort: MykilosKit.CheckoutPort`, `PortRegistry.ports(fuer:userID:rechte:)`).

**⚠️ Namens-Falle:** das Checkout-Protokoll heißt `CheckoutPort`, NICHT `Port` — `Port` kollidiert
mit Foundations `NSPort`-Typealias. Immer `CheckoutPort` verwenden, nirgends `Port` neu einführen.

---

## 2. Scope dieser Session (C2, NICHT mehr)

Baue **genau diese drei nativen Ports** als `CheckoutPort`-Konformer in
`Sources/MykilosApp/Wirbelsaeule/Ports/` (neuer Ordner, App-Ebene — Ports dürfen SwiftUI/PDFKit
nutzen, MykilosKit selbst bleibt unangetastet):

### 2a. `DokumentPort` — Briefpapier/Geräteliste → PDF
- Nutzt **`MykPDFRenderer`** (`Sources/MykilosApp/Export/MykPDFRenderer.swift`, bereits vorhanden
  — `MykPDFRenderer.render(title:sections:table:totals:) -> Data`).
- `erlaubteInhaltsArten()` → `[.dokumente, .artikel]` (Geräteliste ist ein Artikel-Export als Dokument).
- `preview(basket:ziel:)`: baut eine `CheckoutPreview` (Zusammenfassung: wie viele Picks, welcher
  Titel) — rendert NICHT, nur Text-Vorschau.
- `execute(basket:ziel:)`: löst die Picks auf (`resolve()`), mappt sie auf `MykPDFRenderer`-Tabellen
  (Bezeichnung/Menge/EK/VK aus `PickSnapshot`), rendert die PDF-`Data`, schreibt sie NICHT selbst
  weg — das ist Aufgabe der aufrufenden Stelle (Port bleibt reine Rendering-Logik + liefert die
  `Data` im `CheckoutResult` — nutze dafür ein neues Feld oder kapsle es sinnvoll in `meldung`/
  eine neue Result-Erweiterung, dein Ermessen, aber **nicht** in `MykilosKit` selbst ändern ohne
  Not — wenn `CheckoutResult` einen Payload-Slot braucht, erweitere es additiv, nicht brechend).

### 2b. `MoodboardPort` — Bild-Picks → Board-PDF/PNG
- Nutzt SwiftUI `ImageRenderer` (macOS 13+) — einfaches Grid-Layout der aufgelösten Bild-Picks.
- `erlaubteInhaltsArten()` → `[.bilder, .material, .zeichnungen]`.
- `preview`: Zusammenfassung „N Bilder, Layout X".
- `execute`: rendert ein `SwiftUI View` (einfaches Grid) via `ImageRenderer` zu PNG-`Data`.

### 2c. `FireflyPromptPort` — Material/Moodboard-Picks → Prompt-Text (Copy, KEIN Bild)
- Nutzt den bestehenden **Claude-Client** (`Sources/MykilosServices/.../Claude*.swift` — finde die
  bestehende `ClaudeMessagesClient`/`ClaudeChatClient`-Anbindung, NICHT neu erfinden).
- `erlaubteInhaltsArten()` → `[.bilder, .material, .zeichnungen]`.
- `preview`: Zusammenfassung „Prompt wird aus N Picks + Kontext generiert".
- `execute`: baut aus den Pick-Snapshots + Kundenname/Kontext einen Claude-Aufruf, der NUR
  **Text zurückgibt** (den Firefly-Prompt) — **KEINE Bilderzeugung, KEIN Adobe-Call.** Ergebnis
  landet im `CheckoutResult` (Text im `meldung`-Feld oder äquivalent).

**Nativ zuerst, kein Adobe-Pro-Weg in dieser Session** (§5h im Blueprint — Adobe ist spätere
Ausbaustufe, hier NICHT bauen).

---

## 3. Was NICHT in dieser Session passiert (harte Grenze)

- **Keine UI-Verdrahtung** (kein Checkout-Sheet, kein Menü-Eintrag, keine Views) — reine
  `CheckoutPort`-Implementierungen + Tests. UI kommt in einer späteren Session.
- **Keine Postbox-Writes** (kein Airtable, kein Drive-Upload in dieser Session) — `execute()`
  liefert `Data`/Text zurück, schreibt nichts selbst extern. Die eigentliche Ablage (Drive-Ordner,
  Postbox) ist ein separater Schritt.
- **Kein `CartStore`-Umbau** — das ist C3, nicht C2.
- **Kein sevDesk-Bezug** — das ist C4.
- **`MykilosKit` nicht anfassen**, außer eine additive, nicht-brechende Erweiterung von
  `CheckoutResult` ist zwingend nötig (dokumentiere das explizit im Handoff, falls du es tust).

## 4. Rails (unverändert, aus CLAUDE.md + WORKFLOW.md)

- `MykilosApp` darf SwiftUI/PDFKit/AppKit; `MykilosKit` bleibt Foundation-only.
- Keine `.font(.system(...))`, kein `Color(red:...)` — nur `MykilosDesign`-Tokens.
- Kein stiller `try?` bei neuen Schreibvorgängen (hier: keine externen Writes, also meist
  unkritisch — aber wo `MykPDFRenderer`/`ImageRenderer` fehlschlagen können, sauber `throws`).
- Jeder Port braucht mindestens einen Test: `preview()` liefert sinnvolle Zusammenfassung,
  `execute()` liefert nicht-leere `Data`/Text bei validem Input.
- Tests in `Tests/MykilosAppTests/` (neue Datei je Port oder eine gebündelte
  `WirbelsaeulePortsTests.swift`) — kein echtes Netzwerk im automatisierten Testlauf für den
  Claude-Port (Test-Double/injizierbarer Client, siehe bestehendes Muster in
  `ClaudeMessagesClientTests` falls vorhanden).

## 5. Finish-Kriterium

`swift build` UND `swift test` grün (Ziel: 812 + neue Port-Tests, keine Regression). Commit auf
`feat/mykilos8-block-d-provisioning` (oder einem eigenen Feature-Branch, falls dein Codex-Setup
das so vorsieht — dann klar im Commit/Handoff vermerken, damit die nächste Session weiß, wo es liegt).

**Handoff schreiben:** `docs/handoffs/HANDOFF_WIRBELSAEULE_C2_ERGEBNIS.md` — was gebaut wurde,
Testnamen, jede Abweichung vom Blueprint, offene Punkte für C3 (WorkBasket-Ausbau) und die
UI-Verdrahtung (folgt separat).

**`CLAUDE.md` NICHT selbst umschreiben** — das macht Claude (Orchestrator) beim nächsten
Zusammenführen, um Konflikte mit paralleler Arbeit zu vermeiden. Nur den Handoff hinterlassen.
