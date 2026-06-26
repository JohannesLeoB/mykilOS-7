# Handoff — Post-Akt 5, Aufgabe 5: Claude-LLM-Integration im Assistenten

**Status:** abgeschlossen

---

## Was gebaut wurde

Der mykilOS-Assistent kann jetzt optional eine natürliche Zusammenfassung aus
Projekt-Signalen und den bestehenden regelbasierten Insights erzeugen.

Ohne verbundene Claude-Konfiguration bleibt das bisherige Verhalten unverändert:
Der Assistent zeigt die lokalen Insights sofort und schreibt weiterhin nichts
ohne Bestätigung. Mit verbundener Claude-Konfiguration lädt das Widget zusätzlich
eine kurze deutschsprachige Zusammenfassung.

## Architektur

| Datei | Was |
|---|---|
| `Sources/MykilosServices/Claude/ClaudeAuthService.swift` | Anthropic API-Key + Modell im Keychain, sichtbarer Verbindungsstatus |
| `Sources/MykilosServices/Claude/ClaudeMessagesClient.swift` | Testbarer Messages-API-Client mit injizierbarem HTTP-Client |
| `Sources/MykilosApp/Data/AppState.swift` | Gemeinsame Claude-Auth und LLM-Provider-Instanz |
| `Sources/MykilosApp/Settings/SettingsView.swift` | Settings-Sektion zum Verbinden/Trennen des Claude-Assistenten |
| `Sources/MykilosWidgets/Kinds/AssistantWidget.swift` | Optionaler LLM-Summary-Zustand neben den bestehenden Action-Cards |
| `Sources/MykilosApp/Detail/ProjectDetailView.swift` | Projekt-Assistent erhält LLM-Provider nur bei verbundener Konfiguration |
| `Sources/MykilosApp/MykilOS6App.swift` | Home-Assistent erhält LLM-Provider nur bei verbundener Konfiguration |

## Sicherheitsgrenzen

- Secrets bleiben im Keychain; es gibt keine API-Keys in Code, Dateien,
  Tests, Logs oder Handoff.
- Automatisierte Tests nutzen keinen echten Keychain und kein echtes Netzwerk.
- Der LLM-Text ist nur Zusammenfassung. Schreibaktionen bleiben weiter:
  Vorschlag → Nutzerbestätigung → `AuditStore`.

## Modell/API-Annahme

- Default-Modell: `claude-sonnet-4-6`.
- API: Anthropic Messages API (`POST /v1/messages`) mit `x-api-key`,
  `anthropic-version: 2023-06-01` und `max_tokens`.
- Stand geprüft gegen die offiziellen Anthropic-Dokumente am 2026-06-26.

## Tests

Neu:

- `ClaudeAuthServiceTests`
- `ClaudeMessagesClientTests`

Abgedeckt:

- Verbindungsstatus ohne/mit gespeicherten Credentials
- Trimmen und Default-Modell
- Fehler bei fehlendem API-Key
- Disconnect löscht Credentials im Store
- Request-Header und JSON-Body für die Messages API
- Beschreibung von Signalen/Insights im Prompt
- Textblock-Parsing, leere Antwort, kaputtes JSON

## Verifikation

- `swift build` — erfolgreich
- `swift test` — 92 Tests grün
- Live-API-Check — erfolgreich: Keychain-Credentials vorhanden, Anthropic
  Messages API antwortet mit `claude-sonnet-4-6`
- App-Bundle neu gestartet — erfolgreich, Codesign-Check gültig

Bekannte bestehende Warnungen, nicht durch diese Aufgabe eingeführt:

- `NotesWidget.swift`: Timer-Closure ruft `noteStore.save()` aus nichtisoliertem Kontext
- `FocusWidget.swift`: ungenutztes Pattern-Binding `pid`

## Bewusst offen

- Wenn Anthropic später ein anderes Standardmodell bevorzugt, reicht die
  Anpassung von `ClaudeAuthService.defaultModel`.
- Der visuelle UI-Check im laufenden Fenster bleibt manuell: Assistent öffnen
  und prüfen, ob die Zusammenfassung neben den lokalen Insights erscheint.

## Nächster Schritt

Manueller Beta-UI-Check im laufenden App-Fenster: Assistant-Seite öffnen und
prüfen, ob die Claude-Zusammenfassung neben den lokalen Insights erscheint.
