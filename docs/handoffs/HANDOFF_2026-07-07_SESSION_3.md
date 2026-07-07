# 🏁 Handoff — Session 2026-07-07 (Tag/Abend, Non-Stop-Fortsetzung)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/multi-user-login (NICHT nach main gemergt — Johannes' Entscheidung)
Build:  ✅ swift build grün
Tests:  ✅ 1258 Tests grün (162 Suites)
Lint:   ✅ 0 Verstöße gegen swiftlint-baseline.json (neu erzeugt wg. file_length-Zeilenshift)
DMG:    dist/mykilOS-11.1.0-alpha25.dmg (aktueller Stand, an Johannes geschickt)
Datum:  2026-07-07
```

## ⚠️ ZUERST LESEN (Maxime #1, unverändert)
1. `pwd` + `git remote get-url origin` MUSS `mykilOS-macOS` enthalten — sonst SOFORT STOP.
2. Nur absoluter Pfad, nie cwd-relativ.
3. Volle Regeln: `KOORDINATEN.md` + `CLAUDE.md`. Kein main-Push/-Merge ohne Johannes' GO;
   Feature-Branch-Push auf denselben Branch ist ok.

## Was diese Session gebaut wurde (alle grün+getestet+gelintet+gepusht)

1. **Bugfix: herausgelöste Positionen → Warenkorb (per-Projekt-Zweig)** (`160337f`, alpha22).
   Ursache: der Einzelprojekt-Zweig des globalen Angebote-Moduls (`GlobalOffersView` →
   `OffersTabView`) bekam keinen Korb durchgereicht. Fix: `WarenkorbState` durch
   `OffersTabView`→`OfferColumn`→`OfferRow` + `positionsUebernahme` → sichtbarer Korb.
2. **sevDesk: Kundendaten am Postbox-Drop erfassbar** (`26a02b5`+`f917022`, alpha23).
   Kernbefund: `SevdeskPostboxCheckoutPort` schrieb `Kunde`/`Kundennummer`/`Betreff` längst,
   aber `SevdeskPostboxDropSheet.ziel` füllte diese `parameter` NIE → gingen leer raus. Jetzt
   Sektion „Kunde (für sevDesk)" (3 optionale Felder) + „Aus Kontakten wählen" (read-only
   `AirtableContactsLoader`, prefillt Name/Firma).
   **VERIFIZIERT (read-only Airtable-Schema):** `Postbox-Beleg` (tbluQiYMVllkTS4jQ) hat exakt
   `Kunde` (fldxDXYs1Sak2kpw1), `Kundennummer` (flds3oexbiYPrcsVV), `Betreff` (fldFH45pyUSJmNW66)
   → end-to-end verdrahtet.
3. **In-App-Handbuch** (`d04946f`, alpha24) + **Politur** (`5ef669f`, alpha25). `HilfeView`
   rendert `docs/BENUTZERHANDBUCH.md` als durchsuchbares Zwei-Spalten-Handbuch, ersetzt
   „Help isn't available for mykilOS" (Menü Hilfe → „mykilOS Handbuch", ⌘?). Kein Invent-Risiko
   (zeigt nur die verifizierte Pflichtdoku), kein Drift (`build_and_run.sh` spiegelt docs→Resources
   bei jedem Bundle-Build). Politur: ```-Codeblöcke monospaced; Handbuch-Genauigkeit korrigiert
   (Warenkorb-Export ist EIN „Export"-Menü, nicht zwei Knöpfe — per Code-Audit gefunden).
   +8 Tests (`HilfeViewParseTests`: parse-Sektionen + bloecke-Codefences).

## 🔴 Ehrlich offen — braucht Johannes' Entscheidung/Input, nicht mehr Code

1. **Live-Abnahme** aller vier Punkte (Build/Test/Lint = Proxy, kein Beweis). Besonders:
   feuert der sevDesk-Drop mit gefüllten Kundenfeldern die Airtable-Felder korrekt? Öffnet
   das Hilfe-Menü das Handbuch-Fenster sauber?
2. **„Kunden in Warenkorb" auch im Kataloge-Modul?** (offene Frage c). Der Kataloge-Session-Korb
   (`WarenkorbState` in `KatalogeView`) erreicht sevDesk NIE — nur der Projekt-`WorkBasket`.
   Deshalb wurde die Kundenerfassung am sevDesk-Drop gebaut (wo sie sevDesk wirklich erreicht).
   Ein zusätzlicher „In Warenkorb"-Knopf an den Kontakt-Zeilen wäre ein separater Weg ohne
   sevDesk-Wirkung — nur bauen, wenn Johannes ihn ausdrücklich will.
3. **Aufgaben-Spalte 3 (ClickUp schreiben/zuweisen)** — weiterhin bewusst NICHT gebaut
   (Ghost-Persona-Regel, „KI weist NIE zu", braucht Johannes' Blick). Kein Automode-Kandidat.
4. Restliche Backlog-Punkte (Datenschutz-Onboarding-Rechtstexte, Vectorworks-Referenz-Screenshot,
   Handy-Push-Weg, Dubletten-Urteil, Screenshot-Vision) — alle Johannes-geblockt, siehe
   `HANDOFF_2026-07-07_NACHT_UEBERGABE_2.md`.

## Technische Fallstricke (bestätigt)
- **SourceKit-Diagnosen stale/falsch** — „Cannot find HilfeView in scope" trotz erfolgreichem
  `swift build`. Immer `swift build` glauben, nicht die Editor-Diagnose.
- **SwiftLint-Baseline-Zeilenshift** trat wieder auf (file_length von MykilOS6App.swift). Fix wie
  dokumentiert: `--write-baseline …new --quiet`, Eintragszahl gegen alt prüfen (unverändert = nur
  Shift), `mv`, mit `--baseline` re-verifizieren.
- **`no_silent_try`-Custom-Rule** verbietet `try?` — stattdessen `do/catch` mit sichtbarem
  Fehler (`ladeFehler`), wie in `HilfeView.ladeHandbuch`/`inlineMarkdown`.

## Kanonische Kommandos
```bash
cd "/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac"
swift build && swift test 2>&1 | tail -6
swiftlint lint --strict --baseline swiftlint-baseline.json --quiet
MYKILOS_NO_LAUNCH=1 ./script/build_and_run.sh && ./script/create_dmg.sh
```

## Vibe
Johannes' konkreten Zwei-Teiler exakt geliefert + end-to-end verifiziert (inkl. Airtable-Schema
read-only), danach ein unblockiertes Sanktions-Feature (In-App-Hilfe) sauber gebaut und poliert.
Kernlektion: der Wert lag im Erkennen, dass die sevDesk-Pipeline (Port) schon fertig war und nur
der UI-Draht fehlte — sichtbar erst durch Lesen statt Vermuten. Kein hohles „erledigt": die
Live-Abnahme bleibt ausdrücklich Johannes' Sache.
