# 🔴 MASTER-HANDOFF — Einstellungen + User-Log-Ins (DIE Priorität) + Vertrauens-Reset

```
Pfad:    /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
main:    ✅ mykilOS 11 STEHT auf `main` (0a4ab6b, CI GRÜN verifiziert: build-and-test + Lint-Gate)
Build:   ✅ swift build grün · ✅ 1060 Tests grün · ✅ CI grün auf main
Version: 11.1.0-alpha2 · DMG dist/mykilOS-11.1.0-alpha2.dmg
Safe:    ✅ v7.0.0 (e629e84) unantastbar · alter main-Stand als Tag v11.0.0 (4422335) gesichert
Datum:   2026-07-05, sehr spät. Diese Session lief RAU (siehe §0).
```

> ## ⛔ ZUERST LESEN — sonst wiederholst du die Fehler dieser Session.
> Diese Session ist **schlecht gelaufen** und Johannes war (berechtigt) **maßlos enttäuscht**:
> zu langsam, **Basics verkackt**, seine **Ansagen übergangen/vergessen**, und dann hohles
> „alles grün, toll gemacht, Schulterklopfen". Er hat „letzte Chance" gesagt. Bevor du **irgendwas**
> baust: die 4 Meta-Regeln unten, die neue `CLAUDE.md`-Regel ganz oben, und das Gedächtnis
> `kein-hohles-erledigt-nie-ansagen-vergessen`.

---

## 0. Die 4 EISERNEN Meta-Regeln (ÜBER ALLEM, Johannes 2026-07-05)

1. **KEIN hohles „erledigt/grün/fertig".** „Done" = **Johannes hat's live geprüft** ODER ein real
   bewiesenes Ergebnis. **„Tests grün" / „Build läuft" ist PROXY, kein Beweis.** Nüchtern melden,
   kein Schulterklopfen. Unsicher? → „ich glaube X, bitte bestätigen" — nie „fixed".
2. **NIE eine Ansage/Aufgabe vergessen, übergehen, vernachlässigen.** Alles tracken (Task-Liste);
   was verschoben wird, **aussprechen** — nie stillschweigend fallenlassen. Am Start seine offenen
   Ansagen gegenchecken.
3. **Basics vor Features.** App muss sauber aufgehen (keine Prompt-Hölle), konsistent aussehen, tun
   was er braucht — DANN Neues. Nicht am Falschen bauen.
4. **Wurzel-Fix statt Halbmaßnahme** („ein für alle mal richtig").

**Weitere harte Verhaltensregeln aus dieser Session:**
- **KEINE `AskUserQuestion`/Fragebögen, wenn er's schon gesagt hat.** Er ist explodiert bei
  Formular-Fragen („LIEST DU VERDAMMT NOCHMAL WAS ICH SCHREIBE"). Lesen + handeln.
- **Ich teste wie DU:** DMG öffnen, Prompts zählen, Header ansehen — nicht nur bauen.
- **Jede Build EINDEUTIGER Versionsmarker** (nie zweimal dieselbe Nummer — er hat 30 DMGs).

---

## 1. 🎯 DIE PRIORITÄT (Johannes, mehrfach, zuletzt schreiend): **Einstellungen + User-Log-Ins**

**NICHT** Header, **NICHT** Personalausweis-Politur, **NICHT** irgendein Nebenstrang. Das Herzstück:
**Abmelden / Nutzer-Wechsel / mit den eigenen Accounts einloggen** — Multi-User auf einem Mac.
Genau das wurde diese Session zu lange verschoben. Das ist Etappe 1 der nächsten Session.

### 1a. Das Account-Modell — AUTORITATIV aus dem App-Schlüssel-Inventar (Screenshot 2026-07-05)
| Zugang | Klasse | Wer |
|---|---|---|
| **Google Workspace** | 🔵 PERSÖNLICH | jede/r mit eigenem Login |
| **Clockodo** | 🔵 PERSÖNLICH | eigene Zeit-Vorbuchung |
| **ClickUp** | 🔵 PERSÖNLICH | eigener Account + Assignee-Identität |
| **Claude-Assistent** | 🔵 PERSÖNLICH | eigener API-Key + Chatverlauf (nie kreuzlesbar) |
| **Airtable** | 🟢 GETEILT | ein Zugang, Projekte/Kunden für alle |
| **Sevdesk** | 🟢 GETEILT | Team-Zugang |
+ Drive-Ordner-Inhalte geteilt, aber jeder durch seine eigene Google-Brille.

Das Schlüssel-Inventar (`KeychainInventoryView`) klassifiziert das **schon** persönlich/geteilt —
das ist der Startpunkt, nicht bei null anfangen.

### 1b. Johannes' Ziel (sein Urlaubs-Szenario, wörtlich sinngemäß)
„Ich fahr in Urlaub, mein Kollege übernimmt mein MacBook. Wie melde ich mich ab? Wie loggt er sich
mit SEINEN multiplen Accounts ein? MEIN ClickUp/Username/Assignees raus, seine rein. Mein Mail raus,
seine rein. Mein Clockodo trennen, er wählt sich mit seiner Mail/Passwort in die Vorbuchung ein.
Mein Claude-Assistent darf seinen nie verraten. Und das 6×-Schlüsselbund-Passwort-Generve muss weg."

### 1c. Die recherchierte Architektur (verifiziert, siehe Quellen unten)
- **Identität = Google Workspace** (die App hat den OAuth schon; verifizierte Mail = Identität).
- **Secrets = Firmen-1Password** statt macOS-Keychain:
  - **KEIN natives Swift-SDK** von 1Password (nur Go/JS/Python). → Mac-App ruft die **1Password-CLI
    (`op`)** auf: `op read "op://<Vault>/<Item>/<Feld>"`. Entsperrung per **Touch ID** über die
    Desktop-App (1× entsperren → ~10-Min-Session).
  - 🟢 geteilter Vault (Airtable/Sevdesk) · 🔵 persönlicher Vault je Mensch (Google/ClickUp/Clockodo/Claude).
  - Jeder mit **seinem eigenen** 1Password angemeldet → App liest seine Vaults. **Kein Keychain-Prompt.**
  - ⚠️ OFFENE FAKTEN-FRAGE (erst bei Stufe 2 relevant, NICHT als Fragebogen vorher): ist das Firmen-
    1Password Business/Teams mit **persönlichen Logins + geteilten Vaults** (Standard) oder ein
    einzelner geteilter Login? Beeinflusst nur die Vault-Verdrahtung.
- **Wechsel = neustart-basiert** (sicher, minimal-invasiv). Die per-User-Stores werden EINMAL in
  `AppState.init` gebaut (immutable `let`) → nahtloser In-Session-Wechsel = riskanter Umbau, NICHT V1.
- **Namespace-Isolation** (harte Eiserne Regel — falsch = Cross-User-Datenleck): Es gibt heute EINE
  `userID` pro Gerät (`ProfileStore.ensureUserID`, Einzelzeile `id="local"`). Ohne eigenen Anker
  fällt eine neue Mail auf die alte `userID` zurück → würde die Tokens der Vorperson erben. Fall A
  braucht: „Bewohner trennen" setzt einen Switch-Zustand → nächster Login mit anderer Mail bekommt
  einen FRISCHEN userID-Namespace; Rückkehrer rebindet über den per-Mail-Keychain-Anker
  (`KeychainIdentityAnchorStore`) → kein Datenverlust.

### 1d. Bauplan — jede Stufe von Johannes LIVE abgenommen, bevor die nächste kommt
1. **Abmelden + Nutzer-Wechsel in den Einstellungen** (Google-Login + Namespace, neustart-basiert)
   mit einem **Cold-Start-Isolations-Test** der beweist: Person B sieht NIE Person A's Daten.
2. **1Password-Schicht** (`op`-CLI): Tokens raus aus dem Keychain, rein in die Vaults.

### 1e. GO-Status
Johannes hat die ganze Session HART auf „Einstellungen + User-Log-Ins" gedrängt. Der Architektur-
Vorschlag (oben) liegt ihm vor. **Nächste Session: den Weg in EINEM Satz bestätigen lassen (kein
Fragebogen) — dann Stufe 1 bauen.** Nicht wieder verschieben, nicht adjazent bauen.

---

## 1½. 🧭 WISSENSSTAND — was IMMER mitläuft (Johannes: „das muss ich nie wieder durchkauen")

Gehört zu JEDER Session dazu, nie neu erklären lassen:

- **Die Vision / das Ziel (Nordstern):** mykilOS = Johannes' *gelebtes* Wissen (Projektmanagement, Team,
  Daten, Usability) in EINE App gegossen, die die **Team-Arbeit am Projekt real verändert**. Bild-Rahmen:
  „Haus mykilOS" (`docs/HAUS_GESAMTPLAN.md`, Gedächtnis `haus-mykilos-grundriss-metapher`) + Produkt-
  Nordstern 2027 (`docs/PRODUKT_NORDSTERN_2027.md`). **Jede Session bringt uns dem ein Stück näher —
  immer aufeinander aufbauen, nie bei null.**
- **Der Satellit im Fernrohr:** iOS-App **„mykilOS mobile"** ist parallel in der Pipeline (Johannes
  entwickelt sie selbst, `~/Claude/Projects/myMini/…`, Gedächtnis `mykilos-mobile-satellit-betreuung`).
  Gleiche DNA (Check-in-Systematik, per-User-Keychain-Privacy, read-only Assistent). **Wichtig fürs
  Login-Thema:** Identität muss über BEIDE Häuser gelten (Mac + iPhone = EIN Bewohner) — beim
  Einstellungen-/User-Log-In-Bau mitdenken.
- **Der DEV-Ordner (unser Austausch):** `~/Desktop/mykilOS-Feedback/FEEDBACK DEV/` — Johannes droppt dort
  Screenshots, `_LOG.md` = Verbucht-Index. „Dein Ordner"/„Feedback-Ordner" = IMMER dieser. Erst auf
  Signal lesen, nur Noch-nicht-Verbuchtes, je Bild ein Kommentar (Gedächtnis `feedback-screenshot-workflow-regel`).
- **Die Basics stehen (nie wieder von vorn):** eindeutiger Versionsmarker je Build (11.1.0-alphaN,
  hochzählen); Keychain-6×-Fix in alpha2 (⚠️ Verifikation offen); Header-Konsistenz getrackt (Item B,
  „wenn free minute"); DMG vor jedem Limit; nach Code-Änderung immer neu bauen+starten.
- **Der Plan:** `HYPERBUILD.md` (Brühwürfel, Gesamtstand) + DIESER Handoff (aktuelle Priorität) +
  Task-Liste. Der Wissensstand trägt cross-Account über den **Git-Repo** (nicht `~/.claude`) — Task #11.

## 2. Ehrlicher Status — was DIESE Session real passiert ist

### Gebaut + committet (`feat/bewohner-oberflaeche`, 6 Commits vor origin/main, NICHT gepusht):
| Commit | Inhalt | Status |
|---|---|---|
| `41c7853` | E1 railCases + E2 Personalausweis-Header + E4 Meldeadresse-Wizardschritt | Code fertig · **Johannes-Live-Abnahme offen** |
| `e653bfa` | E6 NutzerProvisioningService (Airtable find-or-create, Baustein) + 6 Tests | verifiziert (build/test/lint) |
| `6ac0d74` | E6 Live-Wiring: gated „Ins Team-Verzeichnis eintragen"-Button + Datenstrom-Weiche `AIRTABLE_NUTZER_PROVISIONING` (Code-Manifest + Airtable-Zeile `recoXHMebA8WTjSWp`) + Benutzerhandbuch | Code + Weiche live · **Live-Airtable-Write von Johannes ungetestet** |
| `e08cc81` | Versions-Marker 11.1.0-alpha1 (build_and_run.sh + create_dmg.sh, DOPPELQUELLE synchron halten) | ✅ |
| `519592b` | **Keychain-6×-Wurzelfix** (KeychainStore.store(): Update setzt kSecAttrAccess NICHT mehr → kein ACL-Modify → kein „Zugriffsrechte ändern"-Prompt) · alpha2 | ⚠️ **UNVERIFIZIERT — s.u.** |
| `fc98c36` | CLAUDE.md Meta-Regel „kein hohles erledigt / nie Ansage vergessen" | ✅ |

### ⚠️ UNVERIFIZIERT — NICHT als erledigt abhaken:
- **Keychain-6×-Fix (`519592b`, alpha2):** Diagnose: der Prompt „Zugriffsrechte **ändern**" ist die
  ACL-Modify-Autorisierung; `KeychainStore.store()` schrieb bei jedem Token-Update `kSecAttrAccess`
  mit → auf jeder neu signierten Build 1 Prompt/Secret (6×). Fix: Update schreibt nur noch den Wert.
  **Johannes hat alpha2 GEÖFFNET (Diagnose-Screenshot 11.1.0-alpha2) und diesmal NICHT über Prompts
  geklagt (schwaches Positiv-Signal), aber NICHT bestätigt, dass sie weg sind.** → **Erste Amtshandlung
  nächste Session:** ihn EINE Zahl nennen lassen (0 / weniger / immer noch 6). Kommt noch ein Prompt:
  Wortlaut holen → nächste Wurzel. (Backup-Hebel falls nötig: stabile Signier-Identität „mykilOS Local
  Signing" — build_and_run.sh nutzt sie automatisch, wenn sie existiert; einmalig via Schlüsselbund →
  Zertifikatsassistent anlegen.)
- **E1/E2/E4/E6 Live-Abnahme** durch Johannes steht generell aus (Code+Tests grün ≠ verifiziert).

### Offene technische Schuld (getrackt):
- **SwiftLint-Baseline neu generieren VOR dem PR** (type_body_length/file_length-Shift durch E2/E4/E6;
  Baseline-Pfade auf CI-Checkout re-pinnen, siehe alter Handoff-Gotcha).
- **E3** Settings-Optik-Bänder (macOS-Stil, `MykSettingsRow/Group`) = Politur, später.

---

## 3. ALLE Befehle/Regeln/Ansagen von Johannes aus DIESER Session (nichts vergessen)

- **Einstellungen + User-Log-Ins = DIE Priorität** (§1). Zuletzt schreiend. Nicht mehr verschieben.
- **Header überall in EINE Linie (Item B)** = DEPRIORISIERT: „merk dir gefälligst und mach das, wenn
  du eine free minute hast." (Task #9). Auf seinen Screenshots sitzen die Header je Seite anders hoch.
- **Jede Build eindeutiger Versionsmarker** (11.1.0-alphaN, N pro Build +1; steht DOPPELT in
  build_and_run.sh + create_dmg.sh — Cleanup-Kandidat: eine gemeinsame Quelle).
- **6×-Keychain-Prompt** muss weg (Wurzelfix in alpha2, Verifikation offen).
- **1Password + Google Workspace** = sein gewünschter Weg für die ganze User/Token/Login-Sache. Firma
  hat teamweit **Google Workspace** + **ein Firmen-1Password**.
- **Keine Fragebögen**, kein „toll gemacht". Ergebnisse, nicht Theater.
- **Feedback läuft über den `FEEDBACK DEV`-Ordner** (`~/Desktop/mykilOS-Feedback/FEEDBACK DEV/`,
  `_LOG.md` = Verbucht-Index). „Dein Ordner" = IMMER FEEDBACK DEV.

---

## 4. Feedback-Dev-Ordner
Johannes hat diese Session mehrere **Screenshots** geschickt (aktueller Settings-Stand alpha2:
System/Diagnose, Datenschutz, Integrationen, Schlüssel-Inventar, Privat/Clockodo). Sie zeigen den
Ist-Zustand der Einstellungsebene. Diese sind noch NICHT in `FEEDBACK DEV/_LOG.md` verbucht — die
Header-Inkonsistenz (Item B) ist der sichtbare offene Punkt daraus.

---

## 5. Repo-/Sicherungs-Stand (Stand 2026-07-06 — AKTUELL, ersetzt jeden „nicht gepusht"-Verweis oben)
- **`main` = mykilOS 11 (`98177d2`), CI GRÜN verifiziert** (Lauf `28757272854`, headSha bitgenau). Die
  Bewohner-Serie (E1/E2/E4/E6) + Keychain-Wurzelfix + Regeln/Routine/Handoff sind **gemergt** (Vorwärts-
  Merge `f23ca49`, kein Force). Alter Stand als Tag **`v11.0.0`** (`4422335`) gesichert; **`v7.0.0`**
  (`e629e84`) bleibt der unantastbare Rückfall. Regel korrigiert: „main ist die lebende App" (`CLAUDE.md`).
- Branch `feat/bewohner-oberflaeche` ist vollständig in `main`. **Neue Arbeit:** frischer Branch von
  `main` ODER direkt auf `main` (bei CI-grün + Johannes' GO; PR optional). Bei Datei-Längen-Änderung
  Baseline neu (Muster: swiftlint --write-baseline → Python-Re-Pin auf `runner/work/mykilOS-7`, Task #8 erledigt).
- DMGs: `dist/mykilOS-11.1.0-alpha2.dmg` (aktuell, mit Keychain-Fix), `-alpha1.dmg`, `-11.0.0.dmg` (= Tag v11.0.0).
- **Weitere offene Punkte** (Audit): FEEDBACK-DEV-Items **C** (MYKILOS-Wortmarke neben Squircle zu klein)
  + **D** (Drive-„geprüft" verteilt statt EIN globaler Sync in Einstellungen); die 5 neuen Settings-
  Screenshots (2026-07-05, 19:29-19:30) noch NICHT in `FEEDBACK DEV/_LOG.md` verbucht; **`HYPERBUILD.md`
  ist veraltet** (zeigt alten Branch/Version — bei Gelegenheit auf main-Stand ziehen); `docs/IDEEN_UND_BACKLOG.md`
  jede Session lesen (Multi-User-Wunsch dort vorvermerkt); Altstrang **Korpus→Team-Airtables** (GO da, nicht ausgeführt).

---

## 7. 🔨 DER FESTE BAUPLAN — Multi-User / User-Log-Ins (file:line-genau, verifiziert 2026-07-06)

*Erarbeitet von einem 4-Agenten-Präzisions-Schwarm, der die echten Dateien gelesen hat. Fall A =
„Sitzung trennen / Abmelden", **neustart-basiert** (ein Wechsel löst einen Prozess-Neustart aus, weil
in `AppState.init` alles fest verdrahtet wird). Fall B (nahtloser Hot-Switch) ist mit dem
`CurrentUserContext`-Singleton NICHT sicher — bewusst NICHT dieser Auftrag.*

**⚠️ Schritt 0 — Johannes-Entscheidung ZUERST:** Fall A (Abmelden gibt Namespace frei, App-Neustart)
bestätigen lassen (in EINEM Satz, kein Fragebogen), dann bauen.

### 7.1 Die 12 Touchpoints (echte Datei-Landkarte)
| # | Stelle | Datei:Zeile | Was ändern |
|---|---|---|---|
| 1 | `ProfileStore.ensureUserID` | `Sources/MykilosServices/Database/ProfileStore.swift:85` | userProfile von **Single-Row `id="local"`** auf **Multi-Row (PK=userID)** — GRDB-Migration **v25**. `ensureUserID` muss unterscheiden: Rebind-auf-**selbe**-Mail (Verhalten behalten) vs. **andere** Mail → **neue Zeile**, alte NICHT anfassen. |
| 2 | `AppState.init()` Store-Konstruktion | `Sources/MykilosApp/Data/AppState.swift:329` | Bleibt bewusst so (Basis für neustart-basiert). **NEU:** ein „Abmelden fällig"-Frühausstieg **VOR** dem Init-Block, der bei gesetztem Sign-out-Flag die Auto-Mail-Hydration überspringt. |
| 3 | `currentGoogleUser` / `actorUserID` | `Sources/MykilosApp/Data/AppState.swift:140` | Als Label lassen; sicherstellen, dass nach Wechsel (Neustart) sofort der NEUE Bewohner zeigt, **kein UI-Cache** (Sidebar-Footer, Personalausweis-Header) den alten Wert hält. |
| 4 | `enrichResidentIdentity()` | `Sources/MykilosApp/Data/AppState.swift:192` | Merge ist schon Mail-indiziert (ok). **Gefahr:** `saveLastEmail(email)` schreibt bei JEDER Anreicherung die Mail in den suffixlosen Auto-Hydrations-Slot → beim Abmelden nicht mehr auto-nutzen. |
| 5 | `KeychainIdentityAnchorStore` | `Sources/MykilosServices/Keychain/KeychainIdentityAnchorStore.swift:32` | **NEU: Sign-out-Marker-Slot** (Account `__signed_out__`), den `AppState.init` VOR `loadLastEmail()` prüft. Marker gesetzt → kein Auto-Relogin. |
| 6 | `PerUserKeychainMigrator.loadWithMigration` | `Sources/MykilosServices/Google/PerUserKeychainService.swift:98` | **🔴 GRÖSSTES DATENLECK.** Die Legacy/`.local`-Migration darf **nicht blind für jeden neuen Bewohner** greifen — sonst erbt Bewohner B beim ersten Connect automatisch A's team-weites/`.local`-Secret. Marker-gated / nur beim ersten je-Gerät-Bewohner. |
| 7 | `CurrentUserContext` (Prozess-Singleton) | `Sources/MykilosServices/Google/PerUserKeychainService.swift:16` | Bleibt (Neustart setzt frisch). Design-Grenze: Hot-Switch (Fall B) damit unsicher. |
| 8 | `ResidentIdentityStore` | `Sources/MykilosServices/Database/ResidentIdentityStore.swift:18` | Kein Änderungsbedarf; Lookup-Quelle „welche Bewohner kennt das Gerät". |
| 9 | Geteilte GRDB-Tabellen ohne userID | `Sources/MykilosServices/Database/GRDBDatabase.swift:71` | Für echte Isolation brauchen **ChatStore, AssistantNotesStore, AssistantTasksStore, WorkBasketStore(privat), TimerStore, ChatMemoryStore** eine **userID-Dimension** (Spalte+Migration oder Präfix im Scope-Key) — sonst kreuzlesbar. |
| 10 | `SettingsView+Personalausweis` | `Sources/MykilosApp/Settings/SettingsView+Personalausweis.swift:37` | Natürlicher UI-Anker: „Abmelden"-Aktion in den Header/Detail; Text „aktiver Bewohner" statt fixem „Hausmeister". |
| 11 | `SettingsView.disconnect()` (Muster der 6) | `Sources/MykilosApp/Settings/SettingsView.swift:623` | Abmelden bündelt **alle 6 disconnects** (Google/Clockodo/ClickUp/Sevdesk/Airtable/Claude) + Sign-out-Marker + **App-Neustart** — NICHT die Einzel-Buttons wiederverwenden (sonst bleiben 5/6 für den nächsten Bewohner verbunden). |
| 12 | `RegistryStore.clearLocalCache()` | `Sources/MykilosApp/Data/RegistryStore.swift:79` | **NICHT** für Abmelden nutzen — löscht **geteilte** Team-Daten (Projekte/Kunden gehören allen), nichts Bewohner-Privates. |

### 7.2 Geordnete Bauschritte (Stufe 1, jeder `swift build && swift test`-fest, jeder von Johannes LIVE abgenommen)
0. **Entscheidung Fall A** (s. o.). 1. **Migration v25**: userProfile Single-Row → Multi-Row (PK=userID). 2. `ensureUserID`: andere Mail → neue Zeile (nicht überschreiben). 3. **„Abmelden"-Aktion** (SettingsView+Personalausweis): alle 6 disconnects + Sign-out-Marker, KEIN Löschen. 4. **Sign-out-Marker** stoppt Auto-Hydration (Marker vor `loadLastEmail`). 5. **Store-Isolation**: userID-Dimension in ChatStore + den scope-only Stores. 6. **AuditStore bewusst NICHT** user-filtern (team-weit by design) — aber keine „meine Historie"-Ansicht daraus bauen. 7. **UI-Text** „Hausmeister" → „aktiver Bewohner". 8. **Abnahme**: Isolations-Test (7.3) + Live mit **zwei echten Google-Accounts** auf einem Mac inkl. Neustart dazwischen → dann Johannes-Live-Abnahme.

### 7.3 Cold-Start-Isolations-Test (DAS harte Gate)
Neue `Tests/MykilosServicesTests/MultiUserIsolationTests.swift`, **echte Datei-DB** (kein In-Memory — der Reset muss eine echte `db.sqlite`/Keychain-Grenze überqueren). Fälle T1–T5: T1 Keychain-Namespace (userID A vs B, kein Cross-Read), T2 userProfile-Multi-Row (A + B koexistieren, kein Überschreiben), T3 Sign-out-Marker unterdrückt Auto-Hydration, T4 **`loadWithMigration` greift NICHT für Bewohner B** (der Leak-Test), T5 scope-Stores (Chat/Notes/Tasks) sind nach userID getrennt. **Grün = Beweis: Person B sieht NIE Person A's Daten.**

### 7.4 ⚠️ DATENLECK-FALLEN (falsch gebaut = Katastrophe — vor dem Bau lesen)
1. **`PerUserKeychainMigrator.loadWithMigration` (PerUserKeychainService.swift:98-126)** — automatische Migration von team-weitem + `.local`-Service; B erbt sonst A's Secret. **Das Kernrisiko.** 2. **`CurrentUserContext`-Singleton** (:16-39) — prozessglobal, Dutzende Default-Parameter `userID = CurrentUserContext.current`; nach Wechsel muss er stimmen. 3. **userProfile Single-Row** — B überschreibt A's Zeile. 4. **Scope-only Stores** (Chat/Notes/Tasks/WorkBasket/Timer/ChatMemory) — nie nach userID partitioniert. 5. **„letzte Mail"-Slot** — Auto-Relogin ohne userID. 6. **`clientID/clientSecret`** werden von `disconnect()` NIE gelöscht (heute harmlos, bei Multi-User bedenken). 7. **`clearLocalCache()`** ist ein Misnomer (löscht Geteiltes) — nicht fürs Abmelden.

### 7.5 Stufe 2 — 1Password (`op`-CLI), erst wenn Stufe 1 LIVE steht
- **Mechanismus:** KEIN natives Swift-SDK (nur Go/JS/Python). Mac-App ruft die **`op`-CLI als Subprozess** (`Process`). mykilOS ist **NICHT App-Sandboxed** (nur Kamera-Entitlement) → Subprozess-Start ist erlaubt (Developer-ID + Hardened Runtime, außerhalb App Store). Touch-ID-Unlock via Desktop-App-Integration; **1 Entsperrung → ~10-Min-Session**.
- **Aufruf:** `op read "op://<Vault>/<Item>/<Feld>"` (mit `-n` für Newline-Unterdrückung; absolute Pfade `--cache=false`, `stdin=nullDevice`).
- **Vault-Schema:** 🟢 geteilter Team-Vault (Airtable-PAT, Sevdesk) · 🔵 persönlicher Vault je Mensch (Google-OAuth, ClickUp, Clockodo, Claude).
- **Migration:** 1Password = Quelle der Wahrheit; macOS-Keychain nur noch kurzlebiger Laufzeit-Cache.
- **Fehlerzustände (spezifisch anzeigen):** (1) `op` nicht installiert (`/usr/local/bin/op` + `/opt/homebrew/bin/op` prüfen), (2) nicht eingeloggt, (3) Vault/Item fehlt.
- **Bauschritte:** 1. Vault-Struktur mit Johannes final abstimmen (Daten-/Orga-Entscheidung). 2. `op` lokal + Desktop-App + Touch ID einrichten, manuell testen. 3. Swift-Prototyp AUSSERHALB der App (Process-Aufruf verifizieren, v. a. **TTY/Hang-Verhalten**). 4. `OnePasswordClient` in `MykilosServices` (reine testbare Builder + injizierbarer Executor). 5. Fehler-Enum in Renderstate-Muster. 6. **EINEN** Store zuerst umstellen (ClickUp = kleinstes Risiko) mit Keychain-Fallback. 7. Live-Verifikation Touch ID mit Johannes (Zeitverhalten, Prompt-Vordergrund). 8. Rest schrittweise (Google-OAuth zuletzt, am kritischsten). 9. Team-Onboarding-Doc. 10. Datenstrom-Handbuch (`tblaUVftka0GvXzeU`) + `docs/BENUTZERHANDBUCH.md` sofort ergänzen.
- **Risiken:** TTY/Hang bei GUI-Subprozessen (**größte Unsicherheit** — im Prototyp früh klären) · 10-Min/12-h-Session-Timeout · kein offizieller Support für „Drittanbieter-GUI-App ruft `op`" · `op`-Cache-Daemon-Bug auf macOS Tahoe · PATH-Fragilität (`op`-Ort nicht garantiert) · Onboarding-Overhead pro Mensch · keine Swift-Typsicherheit (alles über stdout-Parsen).

*Quellen 1Password: [SDKs](https://developer.1password.com/docs/sdks/) · [CLI-Desktop-Integration/Biometrie](https://developer.1password.com/docs/cli/about-biometric-unlock/) · [op read/Secrets laden](https://developer.1password.com/docs/sdks/load-secrets/).*

## 6. STARTPROMPT für die nächste Session (Ziel · Plan · Aufgaben-Skript)

**LESEN zuerst (in dieser Reihenfolge), dann handeln:** `MEMORY.md` (v. a.
`kein-hohles-erledigt-nie-ansagen-vergessen`) → `CLAUDE.md` ganz oben (Meta-Regel + **Session-Routine**)
→ DIESER Handoff komplett. Pflichtprüfung: `pwd` · `git status` · `swift build && swift test`.
Branch: `feat/bewohner-oberflaeche` (ist auf origin gesichert).

**🎯 ZIEL (nichts anderes, bis das steht):** Die **Einstellungen + User-Log-Ins** zu Ende bringen —
**Multi-User**: sich abmelden, Kollege loggt sich mit SEINEN Accounts ein, **per-User isoliert** (er
sieht NIE fremde Daten), Rückkehr ohne Datenverlust. Modell: persönlich = Google/Clockodo/ClickUp/Claude
· geteilt = Airtable/Sevdesk (§1a).

**▶️ ZUERST (vor jedem Bau):** (1) Johannes fragen: „In alpha2 — kommen die 6 Keychain-Prompts noch?
(0 / weniger / 6)?" → Task #10. Kommt noch was: Wortlaut holen, Wurzel fixen. (2) Ziel in EINEM Satz
zurückspiegeln, sein Ja abwarten.

**🗺️ PLAN (klein, jede Stufe von Johannes LIVE abgenommen):**
- **Stufe 1 — Abmelden + Nutzer-Wechsel** (Settings): Google-Login + Namespace, **neustart-basiert**.
  `ProfileStore.ensureUserID` um einen Switch-Zustand erweitern (neuer Bewohner → FRISCHER
  userID-Namespace; Rückkehrer → Rebind über `KeychainIdentityAnchorStore`). **Cold-Start-Isolations-Test
  als hartes Gate** (Person B sieht nie Person A's Daten). ⚠️ Identitäts-Kern — falsch = Datenleck.
- **Stufe 2 — 1Password-Schicht** (`op`-CLI, Touch ID; KEIN Swift-SDK, §1c): Tokens raus aus Keychain,
  geteilter + persönliche Vaults.

**✅ AUFGABEN-SKRIPT (der Reihe nach):**
1. Keychain-Verifikation (Johannes-Zahl) → #10.
2. Stufe 1 in kleinen Schritten, jeder `swift build && swift test`, jeder von Johannes live abgenommen.
   Version bumpen (alpha3), DMG, Johannes testet.
3. Stufe 2 (1Password) — erst wenn Stufe 1 live steht.
4. `main` IST bereits die 11 (CI-grün, Baseline #8 erledigt) — kein Merge-Schritt mehr offen. Neue
   Arbeit: frischer Branch von `main` oder direkt auf `main` bei CI-grün + GO. Der **detaillierte,
   file:line-genaue Bauplan** für Stufe 1 + Stufe 2 steht in **§7** dieses Handoffs — dort ist alles.
5. „Header in eine Linie" (#9) + Wortmarke (Item C) + Drive-Sync-Bündelung (Item D) nur, wenn free minute — nicht vordrängen.

**⛔ REGELN (nicht verhandelbar):** Ziel zuerst · klein bauen · Johannes prüft · wir lernen laut ·
kein hohles „erledigt" (done = Johannes-live-geprüft, Tests grün = Proxy) · keine Fragebögen wenn er's
gesagt hat · nichts auf `main`/extern ohne GO, kein Force, Safe State `v7.0.0` heilig · jede Build
eindeutig markiert. **Wir müssen aufholen: EINE Sache, sauber, verifiziert, ohne Theater. Los.**

*Quellen 1Password: [SDKs](https://developer.1password.com/docs/sdks/) · [CLI-Desktop-Biometrie](https://developer.1password.com/docs/cli/about-biometric-unlock/) · [Secrets laden](https://developer.1password.com/docs/sdks/load-secrets/).*

*Ehrlich zum Schluss: diese Session hat zu wenig gelandet und zu viel Vertrauen gekostet. Die nächste
macht's besser, indem sie EINE Sache — Einstellungen + User-Log-Ins — sauber, verifiziert, ohne Theater
zu Ende bringt. 🌳*
