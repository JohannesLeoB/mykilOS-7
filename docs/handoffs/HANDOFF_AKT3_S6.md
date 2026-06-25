# Handoff — Akt 3, Schritt 6: Mail-Widget live

**Status:** abgeschlossen

---

## Was passiert ist

Gmail als achtes Widget in mykilOS, readonly über die Gmail API v1.

### Neue Dateien

| Datei | Zweck |
|---|---|
| `Sources/MykilosServices/Google/GoogleGmailClient.swift` | API-Client: `messages.list` (Suche) + `messages.get` (Metadata-Format) pro Treffer. `GoogleGmailFetching`-Protokoll für Testbarkeit. |
| `Sources/MykilosWidgets/Kinds/MailWidget.swift` | Widget-UI: Absender, Betreff, Snippet, Zeitstempel. Alle Renderstates. Pflaume-Farbe. |
| `Tests/MykilosServicesTests/GoogleGmailClientTests.swift` | URL-Bau, JSON-Parsing (Headers, Snippet, Fallbacks), Sender-Extraktion, Fehlerfall — kein Netzwerk. |

### Geänderte Dateien

| Datei | Was |
|---|---|
| `Sources/MykilosKit/Domain/WidgetFoundation.swift` | Neuer `WidgetKind.mail` |
| `Sources/MykilosKit/Domain/Project.swift` | `ProjectLinks.mailQuery` hinzugefügt |
| `Sources/MykilosKit/Signals/WidgetSignal.swift` | Neuer `WidgetSource.mail` |
| `Sources/MykilosWidgets/SourceChip.swift` | Icon-Mapping `.mail → "envelope"` |
| `Sources/MykilosWidgets/WidgetContainer.swift` | Quellen-Mapping `.mail → .mail`, Farbe Pflaume |
| `Sources/MykilosWidgets/WidgetBoardView.swift` | Dispatch `.mail → MailWidget` |

---

## Architektur-Entscheidungen

1. **Gmail API v1 mit `gmail.readonly` Scope** — Scope war bereits in `GoogleOAuthScope.readOnlyDefaults` enthalten, kein OAuth-Umbau nötig.

2. **Sequenzielle Message-Fetches** — Gmail API hat kein Bulk-Get. `messages.list` liefert nur IDs, dann je ein `messages.get` mit `format=metadata`. Für 10 Mails = 11 HTTP-Requests. Für V1 akzeptabel, könnte in Zukunft durch Gmail Batch API optimiert werden.

3. **`mailQuery` als Freitext-Suche** — Gleiches Muster wie `calendarQuery` und `contactsQuery`: eine Gmail-Suchquery pro Projekt (z.B. "Meyer Küche"), keine eigene Mail-Liste.

4. **Pflaume als Farbe** — Mail teilt sich die Pflaume-Farbe mit Notes (persönlich/kommunikativ). Eigene `WidgetSource.mail` für saubere Trennung.

5. **Sender-Extraktion** — `"Max Müller <max@test.de>"` → `"Max Müller"`. Zeigt den lesbaren Namen statt der vollen RFC-Adresse.

---

## Tests

57 Tests grün, davon 9 neue:

- `GoogleGmailClientTests`: URL-Bau (List + Detail), Message-ID-Parsing, Message-Decoding mit Headers, Fallback ohne Headers, Sender-Extraktion, leere Liste, Fehlerfall

Kein echtes Netzwerk im Testlauf.

---

## Offene Punkte

- **N+1 Requests** — Pro Widget-Laden werden bis zu 11 HTTP-Calls gemacht (1 List + 10 Get). Falls das spürbar langsam wird, Gmail Batch HTTP API evaluieren.
- **Kein Click-to-Open** — Anders als DriveWidget (das Links zum Browser öffnet) gibt es hier keinen Deep-Link zur einzelnen Mail. Gmail Web-URLs folgen dem Pattern `https://mail.google.com/mail/u/0/#inbox/MESSAGE_ID`, könnte nachgerüstet werden.
- **HTML-Entities im Snippet** — Gmail Snippets können HTML-Entities enthalten (`&amp;`, `&#39;` etc.). Aktuell werden diese roh dargestellt.
