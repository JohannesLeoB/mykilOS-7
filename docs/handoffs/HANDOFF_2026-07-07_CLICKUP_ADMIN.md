# 🏁 Handoff — Session 2026-07-07 (sevDesk-Kunden · In-App-Hilfe · ClickUp-I/O · Admin-Ebene)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/multi-user-login (NICHT nach main gemergt — Johannes' Entscheidung)
Build:  ✅ swift build grün
Tests:  ✅ 1266 Tests grün (163 Suites)
Lint:   ✅ SwiftLint --strict (Baseline neu wg. Zeilen-Shift) sauber
DMG:    dist/mykilOS-11.1.0-alpha26.dmg (aktuell, an Johannes geschickt)
Datum:  2026-07-07
```

## ⚠️ ZUERST (Maxime #1)
`pwd` + `git remote get-url origin` MUSS `mykilOS-macOS` enthalten. Kein main-Push ohne GO; Feature-Branch-Push ok. Volle Regeln: KOORDINATEN.md + CLAUDE.md.

## Was diese Session gebaut/geklärt wurde (alle grün, committet, gepusht)

1. **sevDesk-Kunden** (alpha23): „Kunde (für sevDesk)"-Sektion am Postbox-Drop (Name/Kundennummer/Betreff) + „Aus Kontakten wählen". **Read-only verifiziert**, dass `Postbox-Beleg` (tbluQiYMVllkTS4jQ) genau diese Felder trägt → end-to-end verdrahtet.
2. **In-App-Handbuch** (alpha24/25): `HilfeView` rendert `docs/BENUTZERHANDBUCH.md` (Hilfe-Menü / ⌘?), Codeblöcke monospaced, Handbuch-Korrektur aus Code-Audit. Ersetzt „Help isn't available".
3. **ClickUp-I/O-Strang (Architektur + Grundwahrheit):** siehe die drei Plan-Docs unten. Kernbefund: mehr ist gebaut als gedacht (`createTask`/`setStatus`, List-/Member-Mapping, „Meine Aufgaben"-Join existieren). **mykilOS ist die Ursprungs-Instanz** (Nummer + Schema-Name + Fan-out nach Drive/ClickUp/Airtable — `ProjektProvisioningService`, gated `mode==.test`, `.prod` code-locked). Reale ClickUp-Struktur read-only geerntet (11 echte Listen-IDs, 36-Task-Phasen-/Abhängigkeits-Template, 10-Feld-Kontrakt mit `mykilos_project_id` als Join-Schlüssel).
4. **Admin-Ebene S1+S2 gebaut:**
   - **S1** `AdminAuthority` (Kit): `AllowlistAdminAuthority.istAdmin(identity, tokenPresent:)`/`assertAdmin` + `BerechtigungError.nurAdmin`. Admin **nur** aus verifizierter `googleEmail` **+ echtem Google-Token** (Token-Kopplung — adversariale Härtung, weil die Mail beim Start aus dem lokal beschreibbaren Keychain hydriert). Allowlist: `johannes@mykilos.com` + `dk@mykilos.com`. 8 Tests inkl. Eskalations- + Token-Negativtest.
   - **S2** `AppState.currentIdentity` (Lockout-sicherer Fallback), `currentAdminTokenPresent` (aus `googleAuth.status`, dem echten Token-Bündel), `istAktuellAdmin`. Diagnose-Zeile „Admin: ja/nein". **Read-only, noch kein Gate.**

## 📋 Die drei lebenden Plan-Docs (Grundlage für alles Weitere)
- **[CLICKUP_IO_ARCHITEKTUR_PLAN.md](CLICKUP_IO_ARCHITEKTUR_PLAN.md)** — I/O-Architektur, Abhängigkeitskarte, Stufenplan S0–S10. **S0 = Grounding-Sperre** (kein Faktum ohne Beleg — Assistent erfindet keine Adresse/`listID`; Auslöser: der Live-Bug, erfundene Mail-Adresse). Danach Verknüpfung/Read/Write-gated/Chat.
- **[CLICKUP_GRUNDWAHRHEIT_GEERNTET.md](CLICKUP_GRUNDWAHRHEIT_GEERNTET.md)** — die read-only geernteten ClickUp-Fakten (Listen-IDs → Airtable-E1, Lebenszyklus-Template, 10-Feld-Kontrakt). „Sauberes Vernetzen" mit der ClickUp-KI = ihre Struktur ernten, bevor sie beim Go-Live abgestellt wird.
- **[ADMIN_EBENE_BAUPLAN.md](ADMIN_EBENE_BAUPLAN.md)** — der adversarial gehärtete Admin-Bauplan (Gate-Punkte, Token-Kopplung, `.prod`≠Runtime-Recht, Assistent-unter-der-Linie, `.airtable`+Offline-Rekonziliation, Invite-Audit, ehrliche PAT-Grenze).

## 🔴 WEITERER BAUPLAN — genau hier weitermachen

**Reihenfolge = zwei Fundamente zuerst, dann die Features.**

### Nächster Schritt: S3+S4 — Admin-Enforcement (GEKOPPELT: Store-Gate + UI, nie UI zuerst)
- **Store-Gate** (`requireAdmin`/`assertAdmin` als ERSTE Zeile), Signaturen `+ ausgeloestVon identity:` `+ tokenPresent:`:
  - `NomenklaturStore.setzeSchema` (:115), `.setzeSchemaAufStandard` (:137) — Schema-Template.
  - **neuer** `NomenklaturStore.setzeAuthorityMode` (authorityMode ist heute `private(set)` :49 — von Geburt an gegatet).
  - `AppState.einladungErstellen` (:668) — Guard **VOR** dem Keychain-Read (:676!) + A.4 Live-Reverifikation (frisches `fetchUserInfo`, weil externe Aktion mit Team-PAT).
  - Aufrufer reichen `appState.currentIdentity` + `currentAdminTokenPresent` durch (UI: `OrdnerSchemaEditorView`, Invite-Erstellung).
- **`.prod` NICHT gaten** — ist Code-Lock (`ProvisioningModeStore.setMode`), kein Runtime-Recht; Go-Live bleibt Code-Änderung + Johannes-Abnahme.
- **UI-Trennung:** `AdminZoneSection` (nur `if istAktuellAdmin`): Schema-Editor, Invite-Erstellung, AuthorityMode-Umschalter. Invite-Split: „erstellen"=Admin, „öffnen"=alle. Lockout-Leerzustand („Admin braucht einmaligen Online-Login auf diesem Gerät").
- **Audit** `AuditEntry.Action.inviteCreated` (verifizierte `currentIdentity.googleEmail` als Actor, keine Keys loggen).
- **Eskalations-Negativtests (`AdminEnforcementTests`):** Nicht-Admin → setzeSchema/einladungErstellen wirft `.nurAdmin`, DB unverändert, Keychain NICHT gelesen. **Positiv-Gegenprobe:** Nicht-Admin legt Projekt DURCH an (Ledger geschrieben). Assistent-Whitelist-Cross-Check (kein Tool erreicht einen Admin-Store).

### Danach: S6 — `.airtable`-Nummern-Autorität + Offline-Rekonziliation
`AirtableAuthority` (erfüllt `NumberAuthority`, global-atomare Reservierung über `appuVMh3KDfKw4OoQ`) + Kollisions-Toleranz/Sync-Rekonziliation (zwei Offline-User → dieselbe Nummer ist NORMALFALL, nie überschreiben, provisorische archivieren). AuthorityMode-Umschaltung ist Admin-gated (S4). (S5 Airtable-Roster in V1 bewusst übersprungen — Team-PAT-Zirkelschluss.)

### Danach: ClickUp-I/O-Feature-Strang (CLICKUP_IO_ARCHITEKTUR_PLAN)
**S0 (Grounding-Sperre) ZUERST** — erst Mail-Entwurf, dann erben die ClickUp-Draft-Tools sie. Dann: E1 echte Listen-IDs → Airtable befüllen (geerntet, deterministisch), Read-Härtung, Write-gated (Testspace), v3-Chat-Spike, Chat-Read/Send (hinter GO).

## 🟡 Offene Entscheidungen für Johannes
1. **`promote(candidateID:)` (Kalkulations-Kalibrierung) — Admin oder User?** (verschiebt team-weite Kalkulationsbasis).
2. **Airtable-Roster in V1 streichen — bestätigt?** (Empfehlung: ja).
3. **Airtable-PAT-Scopes minimieren + Rotationsplan** (die reale externe Grenze — App-Admin begrenzt Airtable-Schreibrechte NICHT).
4. **A.4 Live-Reverifikation vor Invite-Erstellung** — ok, dass Invite-Erstellen einen Online-Login voraussetzt?
5. **`.airtable` als Default-Nummernmodus** — sobald Mehr-User live, nach Live-Abnahme des Kollisionstests.
6. **Chat senden (C2)** überhaupt gewünscht? (einziger Pfad mit echter Notifikation).

## Technische Fallstricke (bestätigt)
- **SourceKit-Diagnosen stale/falsch** — immer `swift build` glauben (mehrfach „Cannot find X" trotz grünem Build).
- **SwiftLint-Baseline-Zeilenshift** — Zeilen einfügen verschiebt baselined Alt-Verstöße → sehen „neu" aus. Fix: per `git diff` echte neue prüfen (Custom-Regeln wie `no_silent_try` treffen sogar das Wort `try?` IM KOMMENTAR → umformulieren), dann `--write-baseline …new && mv` + `--baseline` re-verifizieren.
- **Bash-Klassifizierung fiel mehrfach kurz aus** (Opus temporarily unavailable) — Read/Edit/Write laufen weiter; Bash-Aktionen einfach wiederholen.

## Kanonische Kommandos
```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
swift build && swift test 2>&1 | tail -3
swiftlint lint --strict --baseline swiftlint-baseline.json --quiet
MYKILOS_NO_LAUNCH=1 ./script/build_and_run.sh && ./script/create_dmg.sh
```
