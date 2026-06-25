# Handoff — Akt 4: Der Assistent erwacht

**Status:** abgeschlossen

---

## Was passiert ist

Das AssistantWidget ist vom statischen Demo-Text zum echten, signalgetriebenen Dolmetscher geworden. Es liest Projekt-Signale, erzeugt priorisierte Insights und bietet bestätigbare Aktionen an.

### Neue Dateien

| Datei | Zweck |
|---|---|
| `Sources/MykilosKit/Domain/AssistantInsight.swift` | Domain-Model: `AssistantInsight` mit Summary, Detail, Source, Priority, optionaler `SuggestedAction`. `InsightSource`, `InsightPriority` Enums. |
| `Sources/MykilosServices/AssistantEngine.swift` | Rein synchrone Engine: mappt `WidgetSignal` → `AssistantInsight`. Testbar ohne Netzwerk/UI. Sortiert nach Priorität (urgent > attention > info). |
| `Tests/MykilosServicesTests/AssistantEngineTests.swift` | 7 Tests: leerer Zustand, Review-Suggestion, Budget-Schwellen (attention vs. urgent), Deadline-Dringlichkeit, Projekt-Filterung, Sortierung. |

### Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosWidgets/Kinds/AssistantWidget.swift` | Komplett überarbeitet: rendert echte `AssistantInsight`-Liste statt hardcoded Text. `InsightRow` mit Priority-Dot, Detail-Text, Action-Buttons. `PriorityChip` (DRINGEND/HINWEIS). Bestätigung setzt visuelles Feedback. |

---

## Architektur-Entscheidungen

1. **`AssistantEngine` ist rein synchron** — Keine async-Calls, kein Netzwerk. Die Engine bekommt Signale als Input und gibt Insights als Output. Das macht sie perfekt testbar und unabhängig von der Datenquelle.

2. **Signal → Insight Mapping** — Jeder `WidgetSignal`-Typ wird zu einem `AssistantInsight` mit passender Priorität:
   - `reviewSuggested` → attention + SuggestedAction (Bieterspiegel)
   - `budgetThresholdCrossed` → attention (< 90%) oder urgent (≥ 90%)
   - `deadlineNear` → urgent (≤ 1 Tag) oder attention
   - `driveFileAdded` → info
   - `offerDetected` → attention

3. **Action-Cards mit Bestätigung** — SuggestedActions werden als weiße Buttons auf dem dunklen Widget dargestellt. Klick → visuelles "Bestätigt"-Feedback mit Checkmark. Die eigentliche Aktion (Audit-Eintrag schreiben) ist vorbereitet aber noch nicht verdrahtet — das kommt mit dem Audit-Store in Akt 5.

4. **Priority-Badge** — Das Widget zeigt oben rechts einen farbigen Chip wenn die höchste Insight-Priorität attention (Ocker) oder urgent (Rot) ist. Bei info: kein Badge.

5. **Fallback** — Ohne aktive Signale zeigt der Assistent "Alles ruhig bei {projectID}" statt einer leeren Liste.

---

## Tests

80 Tests grün, davon 7 neue:

- Leerer Zustand → ruhiger Info-Insight
- Review-Suggested → Attention + SuggestedAction
- Budget-Schwelle → richtige Priorität (72% = attention, 95% = urgent)
- Deadline 1 Tag → urgent + "morgen"
- Deadline 3 Tage → attention + "3 Tagen"
- Projekt-Filter → ignoriert fremde Signale
- Mehrere Signale → sortiert nach Priorität (urgent first)

---

## Offene Punkte

- **Audit-Store Verdrahtung** — Die Action-Bestätigung ist rein visuell. Der tatsächliche `AuditEntry`-Schreibvorgang muss mit einem persistenten `AuditStore` (analog zu `NoteStore`) verbunden werden.
- **Echte Datenquellen** — Die Engine arbeitet aktuell nur auf `WidgetSignal`. Für echte proaktive Insights müsste sie auch Clockodo-Zeitstatus, Kalender-Deadlines und Drive-Änderungen direkt abfragen.
- **LLM-Integration** — Der "ein-Satz-Dolmetscher" ist aktuell regelbasiert. Eine Claude API-Integration für natürlichsprachliche Zusammenfassungen wäre der nächste Schritt.
- **Home-Assistent** — Das Widget existiert nur im Projekt-Board. Ein projektübergreifender Assistent auf dem Home-Board (aggregiert über alle Projekte) fehlt noch.
