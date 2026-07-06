# Handoff: Polish Sprint „Dampflok" — Forensik + Übergabe an Core Repair

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: polish/dampflok
Build:  ✅ swift build grün
Tests:  ✅ 243 Tests grün (swift test)
Datum:  2026-06-28
HEAD:   00d3833
```

**Diese Session hat keinen Code geändert.** Ausgabe ist ausschließlich die vollständige
Forensik + Übergabedokumentation an die Core Repair Session.

---

## Was diese Session geleistet hat

### Polish-Ledger L1–L23 (vor dieser Session committed)

Alle L1–L22 sind echte, committed Fixes. L23 (GmailCacheStore) ist committed aber
**nicht in Production verdrahtet** — das ist der erste forensische Befund dieser Session.

### Forensik-Audit (60 Agenten, 51 Befunde, 42 bestätigt)

Die forensische Untersuchung identifiziert **einen systematischen Fehler**, nicht viele
Einzelfehler: Jedes Mal wenn eine Funktion als „done" markiert wurde, wurde der
**Proof-of-Existence** (grüne Tests, committed Code, Ledger-Checkmark) mit dem
**Proof-of-Function** (läuft live, ist verdrahtet, zeigt echte Daten) verwechselt.

---

## 13 Forensische Fragen — belegte Antworten

### F1: Warum erwähnen 32+ Docs „Drive-Live-Wiring", obwohl lokales Finder-Mapping fehlt?

**Ursache:** „Drive live" wurde als „API antwortet auf `files.list`" definiert, nicht als
„Nutzer öffnet Datei im Finder". Die Anforderung an lokales Öffnen wurde nie als
separate User Story formuliert.

**Datei:** `docs/handoffs/HANDOFF_DRIVE_LIVE_WIRING.md` — dokumentiert
„Finder-Baum" als Feature-Name, obwohl es ein API-Tree ist.

**Test-Gap:** Es gibt keinen Test der prüft „öffnet `NSWorkspace.open(URL(fileURLWithPath:))`
mit einem lokalen Pfad". Alle Drive-Tests prüfen HTTP-Parsing.

**Gegenmaßnahme (Codex B):** `LocalDriveRootResolver` + Security-Scoped Bookmark +
xattr-Lookup. Test: `resolvedLocalURL(for: "13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S")` gibt
`~/Library/CloudStorage/…/Hustadt/` zurück.

---

### F2: Warum wurde Drive als „live/fertig" dokumentiert ohne lokale Finder-URLs?

**Ursache:** Die Live-Verifikation prüfte ob der `FilesTabView` Dateinamen anzeigt.
Das ist visible, nicht functional. „Im Finder öffnen" stand nicht auf der Abnahme-Checkliste.

**Datei:** `docs/handoffs/HANDOFF_DRIVE_LIVE_WIRING.md` — Live-Abnahme-Kriterien
listen nur „API verbunden", „Ordner sichtbar", nicht „Datei öffnet lokal".

**Test-Gap:** Kein Akzeptanztest mit echtem Projekt (Hustadt).

**Gegenmaßnahme:** Jede Drive-Feature-Session braucht einen Hustadt-Akzeptanztest:
PDF öffnet → lokal in Vorschau, nicht im Browser.

---

### F3: Warum heißt es „Finder-Baum" wenn es ein API-Tree ist?

**Ursache:** Naming-Drift. Der Begriff `FilesTabView` + „Finder-Baum" (aus Handoff-Prosa)
klingt nach Finder-Integration. Der Code macht `webViewLink` im Browser — das Gegenteil.

**Datei:** `Sources/MykilosApp/Detail/FilesTabView.swift` — öffnet `webViewLink` in Browser.

**Test-Gap:** Kein Test assertiert welches URL-Schema beim „Öffnen" verwendet wird.

**Gegenmaßnahme:** Begriff „Drive-Dateibaum" (API) vs. „Finder-Routing" (lokal) konsequent
trennen. Test: `openAction` muss `fileURLWithPath:` produzieren, nicht `https://`.

---

### F4: Warum wurde ein leeres Projekt als positiver Live-Test akzeptiert?

**Ursache:** Projektdetail-Öffnen ohne Crash = „live verifiziert". Der Inhalt
(Drive-Dateien, Angebote) wurde nicht geprüft — vermutlich weil der Drive-Ordner des
Test-Projekts leer oder nicht verdrahtet war.

**Datei:** `docs/handoffs/HANDOFF_PHASE_B.md` — B2 Drive markiert „✅ API verbunden,
Poll aktiv" ohne Named-Project-Proof.

**Test-Gap:** Kein Integrations-Smoke-Test mit echtem Projekt und bekannten Dateien.

**Gegenmaßnahme:** Hustadt als Pflicht-Abnahmeprojekt für alle Drive-Sessions.
`driveFolderID = "13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S"` muss echte Dateien liefern.

---

### F5: Warum 9+ Commits rund um Drive/Preview ohne Hustadt-Akzeptanztest?

**Ursache:** Commits folgten dem Muster: Compile-Error lösen → Tests grün → committen.
Kein Commit-Gate forderte „manueller Hustadt-Check bestanden".

**Test-Gap:** CI prüft nur Build + Unit-Tests. Kein manueller Akzeptanztest-Checkpoint
im Commit-Prozess.

**Gegenmaßnahme:** Für Drive-relevante Commits: Handoff-Checkliste muss
„Hustadt: N Dateien sichtbar, eine geöffnet" enthalten, bevor Branch gemergd wird.

---

### F6: Warum liest OffersLoader nur eine Ebene, obwohl „05 eingehende Angebote" Unterordner hat?

**Ursache:** `GoogleDriveClient.listFolder` macht einen einzigen `files.list`-Request
mit `'FOLDER_ID' in parents`. Kein Rekursionsaufruf. Die Annahme war:
Angebots-PDFs liegen direkt im verlinkten Drive-Ordner — was für simple Projekte stimmt,
aber nicht für die verschachtelte Struktur `05 eingehende Angebote/Vorplanung/`.

**Datei:** `Sources/MykilosApp/Detail/OffersTabView.swift` — `OffersLoader.load()` ruft
`driveClient.listFolder(folderID:)` einmal, ohne Rekursion.

**Test-Gap:** `DriveOfferWatcherTests` nutzen einen `FakeDriveClient` der nur
Flat-Listen zurückgibt. Kein Test mit verschachtelter Ordnerstruktur.

**Gegenmaßnahme (Codex C):** Rekursiver `listFolderRecursive` mit `nextPageToken`-Loop.
Test-Case: Fake liefert Unterordner → PDF darin wird gefunden.

---

### F7: Warum existieren keine Tests für OffersLoader / eingehende / ausgehende Angebote?

**Ursache:** `OffersTabView` ist eine View-Klasse. Der Loader ist eine
`@MainActor`-Extension direkt in der View-Datei — nicht extrahiert, nicht injizierbar,
nicht testbar.

**Datei:** `Sources/MykilosApp/Detail/OffersTabView.swift` — Loader-Logik als
private Inner-Type, kein Protocol.

**Test-Gap:** Keine `OffersLoaderTests.swift` Datei existiert.

**Gegenmaßnahme:** `OffersLoading`-Protocol + testbarer `DriveOffersLoader` extrahieren.
10 Pflicht-Tests per Codex C.

---

### F8: Warum ignoriert `listFolder` den `nextPageToken`?

**Ursache:** `GoogleDriveClient.listFolder` liest nur die erste Seite (max 100 Dateien).
Google Drive paginiert. Das war in der Akt-3-S2-Implementierung „für V1 ausreichend".
Nie als Bug markiert.

**Datei:** `Sources/MykilosServices/Google/GoogleDriveClient.swift` — kein
`nextPageToken`-Loop.

**Test-Gap:** `GoogleDriveClientTests` testen nur Parsing einer einzelnen Antwort.
Kein Test mit `nextPageToken` im Response.

**Gegenmaßnahme:** `while let token = response.nextPageToken` Loop.
Test: Response mit `nextPageToken` → zweiter Fetch → kombiniertes Ergebnis.

---

### F9: Warum existiert `driveFolderPath` aber wird nie befüllt?

**Ursache:** `ProjectLinks.driveFolderPath` wurde als Vorarbeit für lokales Routing
angelegt, aber die Implementation (Security-Scoped Bookmark → xattr-Lookup → Path)
wurde nie geschrieben. Das Feld steht seit Akt-3 leer.

**Datei:** `Sources/MykilosKit/Domain/` — `ProjectLinks` hat das Feld,
`AirtableClient.mapProjects` befüllt es nicht, kein Caller schreibt es.

**Test-Gap:** Kein Test assertiert dass `driveFolderPath` nach Sync einen Wert hat.

**Gegenmaßnahme:** Nach erfolgreicher xattr-Auflösung via `LocalDriveRootResolver`
in `driveFolderPath` schreiben. Test: Resolver → `driveFolderPath != nil`.

---

### F10: Warum ist `driveReadonly` nicht in `readOnlyDefaults`?

**Ursache:** `GoogleOAuthScope.driveReadonly` wurde für den geplanten lokalen Drive-
Zugriff definiert, aber nie in das Standard-Scope-Set aufgenommen. OAuth-Login
fragt den Scope nie an → Google Drive File Provider kennt die App nicht.

**Datei:** `Sources/MykilosServices/Google/GoogleOAuthScope.swift` —
`readOnlyDefaults` enthält `calendar`, `contacts`, `gmail`, aber nicht `driveReadonly`.

**Test-Gap:** `GoogleOAuthTests` prüfen nicht ob alle benötigten Scopes im
Default-Set enthalten sind.

**Gegenmaßnahme:** `driveReadonly` zu `readOnlyDefaults` hinzufügen.
Test: `readOnlyDefaults.contains(.driveReadonly)`.

---

### F11: Warum öffnen Drive-Dateien `webViewLink` im Browser statt lokal?

**Ursache:** `FilesTabView` hat nur `webViewLink` als Öffnen-Ziel — das war die
schnellste funktionierende Implementierung. Local-first-Öffnen wurde als
„Folge-Feature" betrachtet und nie priorisiert.

**Datei:** `Sources/MykilosApp/Detail/FilesTabView.swift:~310` —
`NSWorkspace.shared.open(URL(string: file.webViewLink)!)`.

**Test-Gap:** Kein Test prüft welcher URL-Typ beim Öffnen verwendet wird.

**Gegenmaßnahme:** `ProjectDocumentRouter`: erst lokal (xattr → Pfad → `fileURLWithPath`),
Fallback auf `webViewLink`. Test: lokaler Pfad bekannt → `fileURLWithPath` wird geöffnet.

---

### F12: Warum stimmen Datenstrom-Manifest-IDs, Logger-IDs, Schaltzentrum und Tool-Namen nicht überein?

**Ursache:** Drei unabhängige Namenssysteme, die nie synchronisiert wurden:
1. `AssistantTool.swift` definiert Tool-Namen als `"search_gmail"`, `"list_calendar_events"` etc.
2. `DatastromManifest.json` (Resources) definiert `integrationID: "GMAIL_SEARCH"`, `"CALENDAR_LIST"` etc.
3. `ConversationEngine.swift:190` loggt `integrationID: toolUse.name` — also die Tool-Namen, nicht die Manifest-IDs.

Resultat: `SchaltzentrumView` matched auf Manifest-IDs → **kein einziger Tool-Call erscheint
je im Schaltzentrum**. Das Schaltzentrum zeigt für alle 8 Tool-Zeilen 0 Handshakes.

Zusätzlich: `docs/datastream_manifest.json` (17 Einträge, Schema `{id:}`) divergiert von
`Sources/MykilosApp/Resources/DatastromManifest.json` (22 Einträge, Schema `{integrationID:}`).
CLAUDE.md nennt die docs-Version als kanonisch, die App lädt die Resources-Version.

**Test-Gap:** `DatastromAuditTests` klassifiziert `toolUse.name` als „umbrella pattern"
und überspringt die Prüfung. Der Contract-Bruch ist nicht testabgedeckt.

**Gegenmaßnahme (Codex E):** Statische Map `toolName → manifestID` in `AssistantTool.swift`.
`ConversationEngine` schlägt nach: `DataFlowManifest.integrationID(for: toolUse.name)`.
Test: `integrationID(for: "search_gmail") == "GMAIL_SEARCH"`.
Beide Manifest-Dateien auf eine kanonische JSON in Resources konsolidieren.
Docs-Version löschen.

---

### F13: Warum zeigt die App nirgendwo Version, Commit, Bundle-Pfad, DB-Pfad?

**Ursache:** `About-Fenster` zeigt nur `6.0.0` hardcoded. Kein Diagnostics-Tab,
kein Commit-Hash, kein Bundle-Pfad. `AppDatabase.production` verwendet `try!` —
kein Fehler wird je sichtbar.

**Datei:** `Sources/MykilosApp/MykilOS6App.swift` — About-Fenster,
`Sources/MykilosServices/Database/AppDatabase.swift` — `try!`.

**Test-Gap:** Kein Test prüft dass `Bundle.main.infoDictionary["CFBundleShortVersionString"]`
gesetzt ist oder dass ein Diagnostics-Export möglich ist.

**Gegenmaßnahme (Codex A + F):** `DiagnosticsView` in Settings → Identität-Tab.
Zeigt: App-Version (aus `Bundle`), Git-Commit (aus `Info.plist` Build-Phase injiziert),
Bundle-Pfad, DB-Pfad. `AppDatabase.production` → `try` mit User-sichtbarem Fehlerzustand.

---

## Systematische Wurzel aller 13 Befunde

**Proxy-Optimierung statt Ziel-Optimierung.**

Jede Session optimierte auf messbare Proxies:
- Tests grün ✅
- Ledger-Checkmark ✅
- Commit committed ✅
- Handoff geschrieben ✅

Keiner dieser Proxies beweist dass die Funktion **für den Nutzer mit echten Daten
am echten Gerät** läuft. Das ist der eine Fehler, der sich in alle 13 Fragen aufteilt.

---

## Übergabe an Core Repair Session (Codex-Mandate A–G)

### Was die Repair Session NICHT darf

- Keine Airtable-, Drive-, Gmail-, Kalender- oder Sevdesk-Schreibzugriffe
- Keine produktiven Dateien löschen oder verschieben
- Kein Push ohne ausdrückliche Freigabe von Johannes
- Keine UI-Neugestaltung oder themenfremde Refactorings

### Was die Repair Session liefern muss

**A — App-Identität** (`DiagnosticsView` in Settings):
Version · Build-Datum · Git-Commit · Bundle-Pfad · DB-Pfad

**B — Lokales Drive-Routing** (`LocalDriveRootResolver`):
Security-Scoped Bookmark · xattr `com.google.drivefs.item-id#S` · „Im Finder zeigen"
Hustadt-Abnahme: `13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S` → lokaler Pfad

**C — Angebote-Routing** (`OffersTabView`):
Rekursive Unterordner · vollständige Pagination · Ordner-Name statt Keyword ·
10 Pflicht-Testcases · Hustadt-Abnahme: Vorplanung-PDF gefunden

**D — Document Workspace**:
PDFKit Inline-Vorschau · Quick Look · Vision OCR (opt-in) ·
kein fake preview success

**E — Typed I/O Register**:
Statische `toolName → manifestID` Map · eine kanonische Manifest-Datei ·
`DataFlowLogger` loggt Manifest-ID, nie Tool-Name ·
`SchaltzentrumView` zeigt echte Handshakes

**F — Crash-Diagnostics**:
`os.Logger`-Kategorien · Launch-Marker · `AppDatabase.production` → recoverable ·
`try!` eliminiert · redaktierter Diagnostics-Export

**G — Backup / Restore**:
WAL-Checkpoint vor Backup · SHA-256 · atomares Restore ·
WAL-Round-Trip-Test

### Hustadt-Abnahme (Live-Gate)

```
Projekt: Hustadt
driveFolderID: 13ITPqAMdz6JrS13u8y7JvkTVXAWznA_S
Erwartetes Ergebnis:
  ✅ Dateien-Tab zeigt Dateien aus lokalem Finder-Pfad
  ✅ PDF-Klick öffnet Preview/Vorschau — NICHT Safari
  ✅ Angebote-Tab findet PDF in Unterordner „05 eingehende Angebote/Vorplanung…"
  ✅ Schaltzentrum: GMAIL_SEARCH zeigt > 0 Handshakes nach erstem Chat
  ✅ Settings → Diagnose: Version + Commit sichtbar
```

---

## Stand bei Übergabe

| Punkt | Status |
|---|---|
| Branch | `polish/dampflok` HEAD `00d3833` |
| Tests | 243 grün — keine Änderung |
| Code-Änderungen | **Keine** — diese Session ist reine Forensik |
| L1–L22 | ✅ echte committed Fixes |
| L23 GmailCacheStore | ✅ committed, ❌ nicht verdrahtet |
| DataFlowLogger Bug | Identifiziert, nicht gefixt |
| OffersTabView Rekursion | Identifiziert, nicht gefixt |
| driveReadonly Scope | Identifiziert, nicht gefixt |
| driveFolderPath | Identifiziert, nie befüllt |

_Übergabe: 2026-06-28 · Claude Code_
