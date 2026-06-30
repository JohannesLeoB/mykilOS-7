# HANDOFF — Assistant Hub: Kontakte · Mail · Datei-Drop (3 Sessions)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Basis:  main = 721ba53 (v7.5.x) — Fundament verifiziert (s. u.)
Datum:  2026-06-30
Modell: Sonnet 4.6 (alle drei)
```

> ⚠️ Der veralteten `CLAUDE.md` NICHT trauen. Lebender Stand: HYPERBUILD + Memory + dieser Handoff.
> Alle Annahmen gegen den echten Code verifizieren.

## Auftragslage (alle Wünsche von Johannes, konsolidiert 2026-06-30)

1. **Kontakte-Seite** soll die **komplette Airtable-Kontakt-DB** führen (scroll/sortier/filter/kategorisierbar) statt nur Google-Directory.
2. **Assistent über die ganze Kontaktbasis:** komplett **auslesen**, Kontakte **an Mails hängen**, **ergänzen + editieren nach Aufforderung** (gated, nie Delete).
3. **Voller Mail-Client im Assistenten:** lesen (Threads/Volltext/Anhänge), verfassen, Anhänge (Finder + Drive), **senden** (hartes Gate).
4. **Datei-Drop in den Assistenten:** PDF/Bild/Datei droppen → mit Assistent entscheiden: **(A)** in Drive ablegen (Kunde/Projekt/Ordner vorgeschlagen) oder **(B)** per Mail senden.

### Schon erledigt (2026-06-30, dieser Tag)
- **KEIN CSV-Import:** `contacts.csv` (828 echte) ist zu ~99 % schon in Airtable `Kontakte` (914 Records). Massenimport hätte 811 Dubletten erzeugt → unterlassen.
- **Tabelle `Kundenkontakte`** (tblN7RKglX15dmLYe) angelegt: verknüpft auf `Kontakte`, mit den 24 Projektkunden befüllt.

## Fundament auf main (verifiziert)
- `GoogleGmailClient` (searchMessages, fetchBody, GmailAttachment, createDraft), `GoogleOAuthScope.gmailCompose` vorhanden; `gmail.send` FEHLT noch.
- `AirtableClient`: `fetchRecords`, `createRecord`, `mapContacts → StudioContact` (read). **`updateRecord` (PATCH) FEHLT** → für „editieren" ergänzen.
- `AssistantTool.swift` / `AssistantToolManifest.swift` / `ConversationEngine.swift` = Tool-Registry. `AssistantChatView` (MykilosWidgets) = Chat-UI. `DocumentViewerView` (public) = PDF/Bild-Viewer.
- Airtable-IDs: Base `appuVMh3KDfKw4OoQ` · Kontakte `tblncfQzQa8TzCZQC` · Kundenkontakte `tblN7RKglX15dmLYe` · Projekte `tblGJR13OliFt6Ewi` (Feld `Drive-Ordner-ID`).

---

## SESSION A — Kontakte (autonom, Sonnet) · Branch `feat/kontakte-airtable` von main
**Kein neuer Scope, reversibel.**
- `AirtableContactsLoader` (alle 914 laden, `@Observable`, SaveState, alle Renderstates).
- Kontakte-Tab (Kataloge): scroll-/sortier-/filterbare Tabelle (Name/Org/Mail/Tel/Kategorie), Filter nach Kategorie.
- **Assistent-Tools** in der Registry:
  - `list_kontakte` / `search_kontakt` — Vollabruf/Suche (read).
  - `create_kontakt` — neuer Kontakt, **gated** (Bestätigungs-Card → Audit).
  - `update_kontakt` — Feld ändern, **gated**; dafür **`AirtableClient.updateRecord` (PATCH)** neu bauen. **NIE Delete.**
- Tests: Loader-Parse, Tool-URL/Payload, Cold-Start wo persistent. Build + Tests grün.
- **Committen (signiert), NICHT pushen.** Am Ende „Geändert + warum"-Liste.

## SESSION B — Mail lesen/verfassen (autonom, Sonnet) · Branch `feat/mail-client` von main
**Kein neuer Scope (nur readonly + compose-Draft), reversibel.** (Alten `feat/mail-client`-Branch von v7.0.0 ignorieren — neu von main.)
- **Phase 1 Lesen:** 3-Spalten-Mail-UI im Assistenten (Thread-Liste │ Lesefenster │ Verfassen). `searchMessages`+`fetchBody` (VOLLTEXT). Anhänge listen + via `DocumentViewerView` vorschauen. Alle Renderstates, Quellzeile.
- **Phase 2 Verfassen:** Verfassen-UI → `createDraft`. Anhänge: Finder-Drop (`.dropDestination(for: URL.self)`) + Drive (verlinkte Projektdateien → `downloadContent`). `EmailDraft` um Anhänge erweitern (MIME multipart/mixed, base64url).
- **Kontakt→Mail-Brücke:** Empfänger aus Airtable-Kontakten wählbar (nutzt Session-A-Loader wenn gemerged, sonst eigener Light-Fetch).
- **KEIN Senden** (das ist Session C). Tests grün. **Committen (signiert), NICHT pushen.**

## SESSION C — Schreib-/Sende-Stufe (NICHT autonom — braucht Johannes) · Branch `feat/assistant-write-tier`
**Braucht 2 manuelle Re-Consents (Johannes, OAuth — Claude klickt das NIE):** `gmail.send` + `drive.file`.
- **Mail senden:** `GoogleOAuthScope.gmailSend`, `GoogleGmailClient.sendMessage` (messages.send, RFC822 raw, multipart). Senden-Bestätigungs-Card (Empfänger/Betreff/Anhänge) → erst Klick feuert → Audit. Kein Auto-Send.
- **Datei-Drop → Drive:** `GoogleDriveClient.uploadFile` (multipart, neu), Chat-Dropzone, Ordner-Vorschlag-Resolver (Projekt→`Drive-Ordner-ID` + Unterordner), Action-Cards „In Drive ablegen" / „Per Mail senden".
- **Harte Grenze:** Upload nur in PROJEKTE-Arbeitsbaum, NIE NO-GO-Ordner `0AOeReQBQKkKBUk9PVA` / Base `appkPzoEiI5eSMkNK`.
- Code autonom vorbaubar; live scharfschalten erst nach Re-Consent + Test durch Johannes.

## Eiserne Regeln (alle Sessions)
- Token-Disziplin (MykSpace/MykColor/Font.myk…). Schreibvorgänge `throws`, SaveState sichtbar, Cold-Start-Test je persistentem Feature.
- Airtable: nur CREATE/PATCH auf `appuVMh3KDfKw4OoQ`, **NIE Delete/Overwrite**, nie fremde Bases. Mutationen immer hinter Bestätigungs-Card → Audit.
- Signierte Commits, Conventional Commits + Co-Authored-By. **Nicht pushen/mergen.** Visueller Abgleich + Live-Verifikation durch Johannes.
- Neue Daten-Weiche → Datenstrom-Handbuch + BENUTZERHANDBUCH (eiserne Regeln).
