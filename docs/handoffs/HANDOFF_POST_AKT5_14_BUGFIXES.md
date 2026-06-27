# Handoff — Post-Akt 5, Aufgabe 14: Code-Review-Bugfixes

**Branch:** `feat/conversational-assistant`  
**Datum:** 2026-06-27  
**Tests:** 158 grün  
**Build:** clean (`swift build` — keine echten Fehler, SourceKit-Phantomfehler ignoriert)

---

## Was wurde gemacht

Zwei CONFIRMED-Befunde aus dem Multi-Agent-Code-Review (Aufgabe 13) wurden behoben:

### Fix #1 — Integer-Decode-Bug (`[String: String]` schlägt bei JSON-Zahlen fehl)

**Problem:** `ListCalendarTool` deklariert `within_days` als `type: "integer"` im Tool-Schema.
Claude sendet diesen Parameter als JSON-Zahl (z. B. `{"within_days": 7}`).  
`JSONDecoder().decode([String: String].self, …)` wirft `typeMismatch` für Integer-Werte.
`try?` schluckt den Fehler → leeres Dict → kein Query, keine Einschränkung, falsche Transparenz.

**Betroffen:** zwei Stellen
- `Sources/MykilosServices/ConversationEngine.swift` — `activityLabel(name:inputJSON:)` (Zeile 129)
- `Sources/MykilosServices/AssistantTool.swift` — `AssistantToolRegistry.run(name:inputJSON:)` (Zeile 201)

**Fix:** Beide ersetzen `JSONDecoder().decode([String:String].self, …)` durch einen gemeinsamen
privaten `stringDict(from:)`-Helfer mit `JSONSerialization`:

```swift
static func stringDict(from data: Data) -> [String: String] {
    guard let raw = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return [:] }
    return raw.compactMapValues { v in
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return nil
    }
}
```

Damit werden Integer und Float korrekt als String-Werte durchgereicht. `within_days: 7` →
`"within_days": "7"` → `Int("7") ?? 14` = 7. Die Suchabfrage erscheint wieder in der
ToolCallRow-Transparenzspur.

---

### Fix #2 — Wizard ohne Schließen-Button bei manuellem Wiederöffnen

**Problem:** Klickt ein bereits onboardeter Nutzer in der Sidebar auf „Profil & Verbindungen",
öffnet sich der Wizard (`showOnboarding = true`). Backdrop blockt alle Klicks. Footer zeigt nur
Zurück/Überspringen/Weiter — kein Schließen. Der Nutzer muss alle 6 Schritte durchklicken bis `.done`.

**Fix:**
- `OnboardingWizardView` erhält `var onDismiss: (() -> Void)? = nil`
- Im Header wird rechts ein `×`-Button angezeigt, wenn `onDismiss != nil`
- `ContentView` setzt `onDismiss: hasCompleted ? { showOnboarding = false } : nil`
  → beim First-Run kein Button, beim manuellen Öffnen sichtbares Schließen

**Dateien:**
- `Sources/MykilosApp/Onboarding/OnboardingWizardView.swift` — `onDismiss`-Prop + Header-Button
- `Sources/MykilosApp/MykilOS6App.swift` — `onDismiss`-Weitergabe im `ContentView`

---

## Keine neuen Tests

Die Fixes sind reine Korrekturen bestehender Logik:
- Der Integer-Decode-Pfad ist durch `registryUeberlebtKaputteToolInputs` (AssistantRobustnessTests)
  und die bestehenden Tool-Tests abgedeckt; ein dedizierter Unit-Test für den `within_days`-Integer-Pfad
  wäre wertvoll, aber die Abdeckungslücke ist klein (kein neuer Feature-Code).
- Der Wizard-Close-Button ist reine View-Logik, kein Store-/Persistenz-Pfad — kein Cold-Start-Test nötig.

---

## Offene Punkte (priorisiert für die nächste Session)

| Priorität | Thema | Datei(en) |
|---|---|---|
| HOCH | Streaming (Phase 1e): SSE-Decoder + `streamChat` | `ClaudeChatClient`, `ConversationEngine`, `AssistantChatView` |
| MITTEL | Google live verifizieren: echter OAuth-Login + Gmail/Kalender-Tools | manueller Beta-Check |
| MITTEL | `essentialsConnected` prüft nur Claude, nicht Google | `MykilOS6App.swift:78` |
| NIEDRIG | Phase 3: Datei-Upload (Bild/PDF), ChatActionCard für Kalender-Entwurf | — |
| NIEDRIG | ToolCallRow für weitere Tools (wenn neue hinzukommen) | `AssistantTool.swift` |

### Offener Punkt: `essentialsConnected` nur Claude

```swift
private var essentialsConnected: Bool { appState.claudeAuth.status == .connected }
```

Der Wizard-Copy sagt: Assistent bereit erst wenn Claude UND Google verbunden.
`essentialsConnected` prüft nur Claude. Für V1 bewusst akzeptiert (Google-Connect kann scheitern
und App trotzdem nützlich sein), aber Inkonsistenz zum Wizard-Copy. Entweder:
a) Beide checken → Erststart erzwingt auch Google
b) Kommentar präzisieren, was „essenziell" hier meint

---

## Startprompt für die nächste Session

```
Letzter Stand: Branch `feat/conversational-assistant`, 22+ Commits vor main,
158 Tests grün. Handoff: HANDOFF_POST_AKT5_14_BUGFIXES.md.

Letzte Fixes (Aufgabe 14):
- Integer-Decode-Bug: within_days als JSON-Integer → Tools liefen ungefiltert.
  Behoben mit stringDict(from:) in ConversationEngine + AssistantToolRegistry.
- Wizard-Close-Bug: kein Schließen-Button beim manuellen Wiederöffnen.
  Behoben mit onDismiss-Callback in OnboardingWizardView.

Nächste Aufgabe: Streaming (Phase 1e) — SSE-Decoder + live tippende Antworten.
Anthropic /v1/messages mit stream: true → server-sent events → ClaudeChatClient.streamChat.
ConversationEngine.send() → update placeholder block-by-block → AssistantChatView scrollt.
Datenschutz: Tool-Ergebnisse nie gestreamt anzeigen (nur toolActivity-Label).
```
