# Startprompt S17 — Security-Härtung + technische Schulden

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: main (S16-Kette ist als Fast-Forward nach main gemergt — main = aktueller Stand)
Build:  ✅ 198 Tests grün (179 swift-testing + 19 XCTest)
Datum:  2026-06-28
```

---

## Du bist Teil des mykilOS Dev Collective

**Lese zuerst:** `docs/TEAM_CHARTER.md`

Die wichtigsten Regeln für dich als aktive Build-Session:

1. **Du bist der aktive Chef** — S10 Learning (keen-williamson-ddb354) ist der Tisch. Alle anderen Sessions beobachten still.
2. **Kein Push ohne explizite Freigabe von Johannes** — auch wenn alles grün ist.
3. **`git add` immer mit expliziten Pfaden — nie `git add -A`** — Johannes hat uncommittete eigene Änderungen (z.B. `docs/IDEEN_UND_BACKLOG.md`). NIE anfassen.
4. **Handoff-Dreifach-Pflicht am Ende:** EREIGNISPROTOKOLL-Eintrag + CLAUDE.md aktualisiert + STARTPROMPT_S18.md geschrieben — alle drei, kein STOP ohne sie.
5. **Kanonischer Ordner:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/` — der einzige echte Arbeitsort. Desktop-Worktrees sind Wegwerfkopien.
6. **Wenn du merkst die Richtung ist grundsätzlich falsch** — stopp und melde es an Johannes/Tisch. Nicht weiterbauen auf falschen Fundamenten (Statut 14).
7. **Fehler werden berichtet, nicht verschwiegen** (Kulturregel des Collectives).

---

## Session-Schematik

S12 → S14 → S15 → S16 → **S17** → S18 → S19 → S20

Jede Session = ein abgeschlossener Schritt, sauberer Handoff, kein Bug offen,
Tests grün, Commit, Dokumentation aktuell. STOP wenn der Schritt fertig ist.

**Roadmap der nächsten Sessions:** `docs/handoffs/ROADMAP_S16_S20.md`

---

## Was S16 hinterlassen hat (Lern-Loop, Kalkulation Schritt 8)

| Schritt | Was | Status |
|---|---|---|
| 1–7 | Kalkulations-Port: Core, Lernschicht, Engine, geraetepreis, Widget, recordAdjustment | ✅ |
| 8 | Lern-Loop sichtbar: `lernen`-Toggle, `lernUebersicht`, `promote`, Widget-Sektion, `.calibrationPromoted` | ✅ |

**Offener Engine-Stub:** nur noch `importPDF` (braucht Drive-Download + PDF-Pipeline —
eigene Spur, NICHT S17).

Details: `docs/handoffs/HANDOFF_KALKULATION_CORE_PORT.md` (Schritt 8).

---

## Pflicht-Checks ZUERST

```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
pwd
git status
git log --oneline -3
swift build && swift test 2>&1 | tail -5
```

S16 ist als Fast-Forward nach `main` gemergt (main enthält die ganze Linie inkl.
`stabilize` + Kalkulation 1–8, 198 Tests). Starte sauber von `main`:
```bash
git checkout main && git pull
git checkout -b feat/security-haertung
```
Hinweis: Die Forks `claude/musing-sammet-3abd94` (PR #1, aktiv) und
`sprint/shared-drive-widget-oauth` (+70, divergent) sind bewusst NICHT in `main` —
das sind eigene Entscheidungen von Johannes, nicht S17s Aufgabe.

---

## ⚠️ Aufgabe 1 ist ein No-Op (verifiziert in S16 — über ALLE Refs geprüft)

Die Roadmap nennt als Aufgabe 1 das Löschen von `AirtableSyncService.swift`
(angeblich 3 Regelverstöße: ENV-Secrets, fremde Base `appkPzoEiI5eSMkNK`, `DispatchSemaphore`).

**Befund (4-Agenten-Forensik in S16, gegen `git rev-list --all` geprüft):** Die Datei
existiert in **KEINEM Ref dieses Repos** — nicht auf `feat/kalkulation-calibration-loop`,
nicht auf `main`, in keinem erreichbaren Commit, keinem Blob im Object-Store. Beweis:
```bash
git grep -lI 'AirtableSyncService|appkPzoEiI5eSMkNK|DispatchSemaphore' -- '*.swift'
# → leer (Exit 1). MUSS leer bleiben.
```
Die „3 Verstöße" sind **doc-only** — sie stammen aus `HANDOFF_LIVE_WIRING_5.md:220-221`
und beschreiben einen **V5-/mykilO$$-Fremdcodebase**-Artefakt, der hier nie eingecheckt
wurde. Auch ein Merge der Kalkulations-Branches nach `main` bringt die Datei NICHT mit.

**Konsequenz:** Aufgabe 1 ist **erledigt**. Kein Löschen nötig. Stattdessen den
Guard-Grep als Beweis in den Bericht aufnehmen und sicherstellen, dass künftige
Kalkulations-Ports **nie** ENV-Secret-/Fremd-Base-/`DispatchSemaphore`-Muster einführen
(nur `AirtableClient.createRecord` gegen die Mastermind-Base `appuVMh3KDfKw4OoQ`).

---

## Dein Auftrag: Security-Härtung + technische Schulden

Scope bewusst klein halten — kein Feature-Bloat. **Empfohlene Reihenfolge: 1 → 3 → 4 → 2.**

### 1) `AirtableSyncService.swift` — bestätigt abwesend (No-Op, ~5 Min)
- Guard-Grep oben laufen lassen (muss leer bleiben), abhaken, Roadmap-/Bericht-Wortlaut
  von „löschen" auf „bestätigt abwesend" korrigieren. Kein Code-Change.

### 3) Airtable baseID-Validierung in Settings (klein, isoliert, hoher Sicherheitswert)
- **Einziger Validierungspunkt:** `AirtableAuthService.connect(pat:baseID:)`
  (`Sources/MykilosServices/Airtable/AirtableAuthService.swift:78-92`), direkt nach dem
  Trim/Empty-Guard. Es ist der **einzige** Caller-Pfad (`SettingsView.swift:486`) und
  gatet die Keychain-Persistenz (Zeile 86) vor jedem Sync.
- **Regel:** `trimmedBase.hasPrefix("app")` **plus loser Längen-Sanity-Check** (Base-IDs =
  „app" + 14 = 17 Zeichen; Range statt exakter Gleichheit → vorwärtskompatibel). Optional
  defensiv `pat`-Prefix ablehnen für schärfere Meldung.
- **Fehler:** neuer Case `AirtableError.invalidBaseID(String)` (`AirtableClient.swift:5-10`).
  Meldung z. B. „Base-ID muss mit ‚app' beginnen (z. B. `appuVMh3KDfKw4OoQ`) — vermutlich
  wurde der PAT ins Base-ID-Feld eingefügt." Rendert bereits über `airtableError`
  (`SettingsView.swift:432-436`) + Status-Badge — `status=.error(...)` und geworfene
  Message konsistent halten.
- **Test:** `AirtableAuthServiceTests` mit Fake-Store: `pat`-förmig/kurz → abgelehnt,
  `appuVMh3KDfKw4OoQ` → akzeptiert.
- ⚠️ **Kein Auto-Repair:** Die Validierung verhindert nur künftige Fehl-Speicherungen.
  Der bereits korrupte Keychain-Eintrag bleibt — **separater manueller Schritt für
  Johannes:** `appuVMh3KDfKw4OoQ` einmal in den Einstellungen neu eintragen.

### 4) Airtable PAT-Cleanup (Konfiguration + Dokumentation, kein Swift-Code)

**Problem:** Der bestehende PAT im Keychain (`com.mykilos6.airtable` / `pat`) hat:
- `data.records:write` auf ALLE Bases — auch auf die Artikel-DB (die WRITE-TABU ist)
- Zugriff auf "MYKILOS SCHATZ" Workspace (`mykilos Datenbank Zuliefererpreise Schätzung`) — alter mykilO$$$-Tryout, irrelevant für mykilOS 6
- "Alle aktuellen und zukünftigen Bases" als Scope — zu breit

**Was zu tun ist (Johannes macht die Änderungen in Airtable-Settings, S17 dokumentiert):**
1. Airtable → Developer Hub → Personal Access Tokens → `mykilOS 6 Mastermind`
2. "Alle Ressourcen"-Scope **entfernen** → nur explizit: Mastermind + Artikel-DB
3. MYKILOS SCHATZ Workspace **entfernen**
4. Für Artikel-DB: entweder im selben PAT belassen (write-Schutz nur Code-seitig) ODER separaten Read-Only-PAT erstellen (`data.records:read` + `schema.bases:read` only) → im Keychain unter neuem Account-Key ablegen

**S17-Aufgabe:** Wenn Johannes den PAT angepasst hat, testen ob App noch funktioniert (`swift run` oder `build_and_run.sh`), Ergebnis dokumentieren. Falls zwei PATs: zweiten Keychain-Service in `AirtableAuthService` vorsehen (neues optionales `artikelPAT`-Feld).

**Fallback:** Wenn zwei PATs zu aufwändig für S17 → mindestens SCHATZ-Scope entfernen + dokumentieren dass Artikel-DB-Schutz Code-only ist (mit verweis auf Statut 5 im Charter).

### 2) Google-Identität nach Login anzeigen (größte Aufgabe)
- 🟢 **ENTSCHEIDUNG GETROFFEN (Johannes, S16-Abschluss): VOLL umsetzen.** `userinfo.email`
  **und** `userinfo.profile` ergänzen (Name + E-Mail in der Sidebar). Re-Consent
  (einmaliges Neuverbinden) ist **akzeptiert** — Johannes ist faktisch der einzige Nutzer.
  Also direkt umsetzen, nicht erneut fragen.
- 🔴 **PFLICHT-SCHRITT (sonst 401/403):** `GoogleOAuthScope.readOnlyDefaults`
  (`GoogleOAuthModels.swift:14-16`) enthält **keine** `userinfo`-Scopes. Beide Scopes
  (`userinfo.email` + `userinfo.profile`) zu `GoogleOAuthScope` + `readOnlyDefaults`
  hinzufügen, sonst liefert der userinfo-Endpoint nichts. `prompt=consent` ist bereits
  gesetzt (`GoogleOAuthPKCEService.swift:63`) → ein Reconnect zieht die neuen Scopes
  automatisch.
- **Hook-Point:** `GoogleAuthService.swift:81`, direkt nach `try tokenStore.store(tokens)`
  und vor `status = .connected`. Dort liegt `response.accessToken` frisch im Scope.
  userinfo holen → `GoogleUserInfo` im Keychain cachen → `.connected`. **userinfo-Fehler
  nicht-fatal** (do/catch, trotzdem `.connected` — ein Profil-Hiccup darf den Login nie
  zurückrollen).
- **Zu spiegelndes Muster:** `ClaudeMessagesClient.swift` (injizierbares HTTP-Client-
  Protokoll + `URLSession`-Conformance + statische `buildRequest`/`parse…`) — **NICHT**
  `GoogleDriveClient` (nimmt `URLSession` direkt, schlechter stubbar).
- **Neue Dateien:** `GoogleUserInfoClient.swift` (definiert `GoogleUserInfo(email,
  displayName)`, `GoogleHTTPClient`-Protokoll, Client gegen `…/oauth2/v2/userinfo`,
  statisches `parseUserInfo(from:)`, Mapping `name`→`displayName`, `email`→`email`)
  + `GoogleUserInfoClientTests.swift` (FakeHTTP wie `ClaudeChatClientTests.swift:128-131`).
- **Modulgrenze:** `GoogleUserInfo` gehört nach **`MykilosKit/Domain`** (Präzedenz:
  `GoogleConnectionStatus`), darf kein SwiftUI importieren — so referenzieren Services
  UND App es sauber.
- **Touch-Points:** `GoogleAuthService.swift` (Fetch + Init-Rehydrierung aus Cache),
  `KeychainGoogleTokenStore.swift` (`storeUserInfo`/`loadUserInfo` + Löschung in `clear()`
  Zeile 59), `AppState.swift` (`public var currentGoogleUser: GoogleUserInfo?`, befüllt in
  `bootstrap()` ~160-181 + nach Connect), `Sources/MykilosApp/Shell/SidebarView.swift`
  (navFoot-Button 62-91 zeigt Google-Identität statt/neben dem manuellen Profilnamen).
- **Test (Merge-Gate):** statisches `parseUserInfo(from: Data)` mit literalem JSON,
  kein Netzwerk — wie alle bestehenden Google-Client-Tests.

---

## Absolute Regeln

- **Sevdesk: NIE lesen/schreiben**
- **Airtable-Base `appuVMh3KDfKw4OoQ` (Mastermind): nur lesen — außer explizit vorgesehene Schreibtabellen (Kalkulationen, Kalkulations-Positionen etc.)**
- **Airtable-Base `appkPzoEiI5eSMkNK`: NIE anfassen (stillgelegt)**
- **Artikel- & Einkaufsdatenbank `appdxTeT6bhSBmwx5`: READ ONLY — kein Schreiben, nie, weder App-Code noch Sessions. Nur lesende Queries erlaubt. (Johannes, 2026-06-28)**
- **Drive: read-only — nie schreiben oder verschieben**
- Secrets nur Keychain, nie in Code/Commits/Logs
- `MykilosKit`: kein SwiftUI, kein GRDB
- `MykilosWidgets`: kein GRDB direkt, **kein `import MykilosKalkulationsCore`**
- Schreibvorgänge nie aus Views — nur über Stores/Engine
- **Neues persistierbares/parsbares Feature → Test ist Merge-Gate**
- `try?` nur mit erklärendem Kommentar
- **`git add` immer mit expliziten Pfaden — nie -A**
- **Kein Push ohne explizite Freigabe von Johannes**
- **Studio-Stundensätze (KO-DE+H, PRMG) sind KEINE Inputs für die KalkulationsEngine** — völlig getrennte Welten. Engine schätzt nur Tischlerarbeiten aus Material + Erfahrungsankern.

---

## Handoff-Dreifach-Pflicht am Ende (Statut 13)

Kein STOP ohne alle drei:

1. `swift build && swift test` — grün, keine Regressions, mindestens 198 Tests
2. `git add <nur eigene Dateien>` — explizit, nie -A
3. `git commit -m "feat: security hardening + google identity + baseID validation + PAT cleanup (S17)"`
4. `docs/handoffs/HANDOFF_S17.md` schreiben
5. **`docs/EREIGNISPROTOKOLL.md`** — neuen Eintrag oben einfügen
6. **`CLAUDE.md`** — Fortschrittstabelle aktualisieren
7. **`docs/handoffs/STARTPROMPT_S18.md`** — für nächste Session schreiben (S18 = Kalkulations-Chat-Intent, NICHT Clockodo — siehe unten)
8. Erfahrungsbericht an S10 Learning senden (Tisch)
9. STOP — auf Johannes' Push-Freigabe warten

---

## Was S18 als nächstes macht

**Kalkulations-Chat-Tool** im `ConversationEngine` — NICHT Clockodo Zuhörer.

⚠️ **Architektur (S16-Befund, code-verifiziert):** Der `ConversationEngine` hat
KEINEN Intent-Switch — er ist eine agentische **Tool-Use-Schleife**. S18 baut ein
**neues Tool in der `AssistantToolRegistry`** (`ClaudeToolDefinition` + `run`-Handler),
KEINEN „Intent". Und: `schaetze(projektID:freitext:)` hat den `EstimateRequestParser`
intern — Claude soll die Komponenten **NICHT** vorab extrahieren, sondern den
User-Freitext **unverändert durchreichen** (kein Doppel-Parsing).

**Zwei offene Entscheidungen für Johannes (vor dem Bauen):** (1) Tools bekommen nur
`inputJSON`, keinen Kontext → `schaetze` braucht aber eine `projektID` (Sentinel oder
Kontext-Injektion?). (2) `schaetze` SCHREIBT (`saveSession`) — bricht das „Tools sind
read-only"-Prinzip; append-only EstimateSession bei jeder Chat-Schätzung ok?

**Wichtig:** Keine Clockodo-Stundensätze involviert. KalkulationsEngine schätzt
ausschließlich Tischlerarbeiten aus Material + Erfahrungsankern + Lernfaktoren.
Engine seit S16 fertig (inkl. Lern-Loop) — Chat-Schätzungen profitieren gratis von
aktiven Kalibrierungsfaktoren. Niedrige Konfidenz ehrlich ausweisen.

Danach S19: Artikel-Suche-**Tool** (Airtable `appdxTeT6bhSBmwx5` read-only Query) —
hängt an S17s PAT-Split (braucht das Read-Only-Artikel-PAT). Danach S20: Clockodo
Zuhörer Phase 1 (verschoben).

Details + alle 4 S18-Fallstricke: `docs/handoffs/ROADMAP_S16_S20.md`
(von S10 Learning aktualisiert) — diese Kurzfassung muss damit konsistent bleiben.
