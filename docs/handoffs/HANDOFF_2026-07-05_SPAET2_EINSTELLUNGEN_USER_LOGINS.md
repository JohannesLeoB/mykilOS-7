# 🔴 MASTER-HANDOFF — Einstellungen + User-Log-Ins (DIE Priorität) + Vertrauens-Reset

```
Pfad:    /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch:  feat/bewohner-oberflaeche  (6 Commits vor origin/main, NICHT gepusht — kein GO)
Build:   ✅ swift build grün · ✅ 1052→1060 Tests grün  (ABER: „Tests grün" ≠ verifiziert!)
Version: 11.1.0-alpha2 · DMG dist/mykilOS-11.1.0-alpha2.dmg
Safe:    ✅ Tag v7.0.0 (e629e84) unantastbar
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

## 5. Repo-/Sicherungs-Stand
- Branch `feat/bewohner-oberflaeche`, 6 Commits vor `origin/main`, **NICHT gepusht** (kein GO — Push/PR
  brauchen Johannes' GO). `main` = 11.0.0 (origin, PR #4). Safe State `v7.0.0`=`e629e84` intakt.
- DMGs: `dist/mykilOS-11.1.0-alpha2.dmg` (aktuell), `-alpha1.dmg`.
- Durable gesetzt: `CLAUDE.md`-Meta-Regel (`fc98c36`), Gedächtnis `kein-hohles-erledigt-nie-ansagen-vergessen`.

---

## 6. STARTPROMPT für die nächste Session
> Moin. Lies `MEMORY.md` (v. a. `kein-hohles-erledigt-nie-ansagen-vergessen`), die neue `CLAUDE.md`-
> Regel ganz oben, und DIESEN Handoff komplett. Pflichtprüfung `pwd`/`git status`/`swift build && swift
> test`. **Dann ZUERST:** Johannes fragen, ob in alpha2 die 6×-Keychain-Prompts weg sind (eine Zahl).
> **Danach DAS Thema, nichts anderes:** Einstellungen + User-Log-Ins — Stufe 1 (Abmelden + Nutzer-
> Wechsel, neustart-basiert, per-User-Namespace, Cold-Start-Isolations-Test der beweist: Kollege sieht
> nie fremde Daten). Architektur + Modell stehen in §1. Regeln: kein hohles „erledigt" (done =
> Johannes-verifiziert), keine Ansage vergessen, keine Fragebögen, Basics vor Features, jede Build
> eindeutig markiert, nichts auf main/extern ohne GO. Header (Item B) nur „wenn free minute".

*Quellen 1Password: [SDKs](https://developer.1password.com/docs/sdks/) · [CLI-Desktop-Biometrie](https://developer.1password.com/docs/cli/about-biometric-unlock/) · [Secrets laden](https://developer.1password.com/docs/sdks/load-secrets/).*

*Ehrlich zum Schluss: diese Session hat zu wenig gelandet und zu viel Vertrauen gekostet. Die nächste
macht's besser, indem sie EINE Sache — Einstellungen + User-Log-Ins — sauber, verifiziert, ohne Theater
zu Ende bringt. 🌳*
