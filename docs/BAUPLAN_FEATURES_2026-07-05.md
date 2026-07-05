# Strenger Bauplan — Features & Tweaks (Stand 2026-07-05)

Quelle: Johannes' Ansage 2026-07-05 („bau die nächsten Widgets · Drag&Drop · die Tweaks ·
Mini-Mode ist noch nicht sauber · gründlich") + `docs/IDEEN_UND_BACKLOG.md` (Z. 1–568) +
`FEEDBACK DEV/_LOG.md`. **Kein aktiver Auftrag ohne Johannes' GO je Track.**

## Eiserne Guardrails (für JEDEN Track)
- Eigener Feature-Branch, nie direkt `main`, Merge nur auf GO.
- Widgets: alle **6 Renderstates** + Quellzeile · nur **Tokens** (`MykColor`/`MykSpace`/`Font.myk…`).
- Persistierter Zustand → **Cold-Start-Test** (schreiben→neue Instanz→lesen→identisch).
- Neue Daten-Weiche → Datenstrom-Handbuch (Airtable `tblaUVftka0GvXzeU`) + `BENUTZERHANDBUCH.md`.
- Interior-Build-Charter: nur innen; Airtable = Outer Limit; Daniels Base heilig; Drive read-only.
- „Fertig" = Hustadt-Live-Gate, nicht grüne Tests (Kamera/Drag = Live-Check bei Johannes).
- **UI-KONSISTENZ-GEBOT (Johannes 2026-07-05):** JEDE UI-Änderung wird auf **ALLEN Ansichten** auf
  **Konsistenz + einheitliche Abstände** geprüft — gleiche `MykSpace`-Stufen, gleiche Radien/Fonts/
  Token-Sprache überall, kein Abweichler-View. Gegen Screenshots (Layout-Drift-Regel).

---

## Die CHECK-IN-Systematik (das Rückgrat — Johannes-Erkenntnis 2026-07-05)
Alle Tracks sind Instanzen EINER Sache: der **CHECK-IN-Systematik** — der einzige disziplinierte Weg,
wie *irgendein* Datum in mykilOS eintritt oder sich ändert. Wie **Versionskontrolle für die Studio-Realität**:
> **ich hab was → was/wohin/warum → verifizierter Review (okay/nicht okay) → Audit** — append-only,
> versioniert, idempotent, **nie überschreiben/löschen**, `throws`+SaveState, Cold-Start-safe.

Jedes Feature = „**Check-in** von Typ X in Ziel Y":
| Feature | Check-in von… |
|---|---|
| Kamera „Verwendung wählen" (G8) | Scan-Ergebnis → Warenkorb/Artikel/Kontakt |
| Lager aus-/einbuchen (G9) | *wörtlich* Check-out / Check-in von Bestand |
| Visitenkarte → Kontakt / Selbstheilung (G5/G6) | Kontakt-Daten |
| Daniels-Base-Übersetzung/Fortschreiben (L) | externe Daten |
| Warenkorb → sevDesk-Postbox / DHL (K) | Positionen/Sendung |

**Code-Knochen existieren:** `CheckoutPort` (Wirbelsäule) + `ActionCard` (Vorschlag+Bestätigung) +
`AuditEntry` (Spur). → **einmal zu EINER `CheckIn`-Spine formalisieren**, dann ist jedes Feature nur noch
ein **Check-in-Adapter**. Crash-Safety + Nachvollziehbarkeit an EINER Stelle, nicht 12-mal verstreut.
= Kern des Master-Architektur-Docs.

---

## Track A — Kamera/Barcode-Widget  · Branch `feat/kamera-barcode-widget`
- **A1 ✅ Increment 1 (fertig, 962 Tests grün):** `WidgetKind.barcode`, `BarcodeWidget` (alle
  Renderstates, Quellzeile, Tokens), auf der Übersichtsseite (`homeLayout` + Migration
  `ensureWidgetOnce`), Selektor, SourceChip-Icon, Kamera-Berechtigung.
- **A2 ⬜ Cold-Start-Test** für die Home-Board-Migration (Barcode landet + überlebt Neustart) —
  Guardrail-Pflicht, mirror den Warenkorb-Migrations-Test.
- **A3 ⬜ Increment 2 — echte Kamera:** `AVCaptureSession` + `VNDetectBarcodesRequest` +
  Live-Preview-Sheet (`NSViewRepresentable`) + `NSCameraUsageDescription`/Entitlement im
  build-Skript. Scan → Code anzeigen/kopieren. **Live-Gate bei Johannes** (Kamera nicht testbar).
- **A4 ⬜ v2 (später):** Barcode → Artikel-Katalog-Lookup (`ArtikelKatalogStore`).

## Track B — Drag & Drop (Johannes-Kernthema)
- **B1 ⬜ Bug: Positions-Pick im globalen Angebote-Modul** — Positionen im „herauslösen"-Sheet
  lassen sich nicht in den Warenkorb ziehen. Kleiner, konkreter Fix. Fundament: Wirbelsäule
  (`Pick → WorkBasket → CheckoutPort`), `WorkBasketStore.fuegePositionHinzu`.
- **B2 ⬜ Globales Drag&Drop (groß, fundamentgestützt):** Items aus ALLEN Katalogen (Kontakte/
  Artikel/Lager/Zeichnungen/Positionen) per Ziehen in Checkout/Warenkorb. `.draggable`/
  `.dropDestination` gibt's schon im HomeBoard — hier über die `CatalogMatrix`-Typen ausrollen.
- **B3 ⬜ Datei-Drag&Drop:** Drive-Dateien (Dateien-Tab / `DriveWidget`) per Ziehen in Warenkorb/
  Projekt/Checkout — konkreter, oft gebrauchter Sonderfall von B2.

## Track C — Mini-Mode V1.1 „sauber machen"  (Spec verriegelt, Backlog Z. 124–178)
Der gebaute Mini-Mode (`9ce2b9b`) hat noch die **alte Hover-Summary** verdrahtet.
- **C1 ⬜ Hover-Summary-Karte entfernen** (im Live-Test „nervt eher", gestrichen).
- **C2 ⬜ Klick-zur-brennenden-Stelle verdrahten:** normaler Klick aufs pulsende Modul-Icon →
  öffnet App **direkt an der pulsenden Quelle** (Klick-Handler muss die Signal-Quelle auflösen
  und gezielt dorthin navigieren, statt nur die App zu öffnen). Logo-Klick → letzte große Ansicht.
- **C3 ⬜ Mini liegt NICHT über der Großversion (Feedback 2026-07-05, verriegelte Spec):** Mini-Mode =
  App geschrumpft auf **NUR die Icon-Sidebar (kein Inhaltsfenster)**. Aktuell schwebt der Mini-Streifen
  ÜBER dem offenen Heute-Fenster → **Bug**. Fix: beim Aktivieren Hauptfenster **ausblenden/minimieren**
  (`orderOut`), beim Verlassen wiederherstellen. Der Streifen steht allein (Use-Case: über FREMD-Vollbild
  wie Vectorworks, nicht über der eigenen Großansicht).
- Leitplanken: Puls abschaltbar pro Quelle, LEAN (keine neuen Polls), WindowGuard-Panel-Handling.

## Track D — View-Konsolidierung (Sammlungs-Ansicht-Standard ÜBERALL)
- **D1 ⬜ Warenkörbe** auf den Sammlungs-Standard (Liste⇄Galerie/Kachel + Zoom + Vorschau +
  Suche/Filter/Sortierung/Quellzeile/Renderstates) — wie Dateien/Angebote.
- **D2 ⬜ Kontakte als Kachel/Galerie + Kontaktbild** (Toggle lokal/Google-Foto/Icon-Default).
- **D3 ⬜ Dateien-Ansicht: Parent-Ordner-Herkunft sichtbar (Feedback 2026-07-05):** die flache
  „alle Dateien"-Galerie zeigt nicht, aus welchem Ordner eine Datei kommt. Vorschlag: **Farb-Herkunfts-
  Marke** (kleiner Farbpunkt je Ordner-Kategorie aus `MykColor` + Ordnername als muted Mono-Chip pro
  Kachel — „Farbe ist Sprache") + Umschalter **flach ⇄ nach Ordner gruppiert** + Ordner-Filter-Chips.
  Farbmarke immer an, Gruppieren/Filter als Sammlungs-Standard-Werkzeug.

## Track E — Tweaks & kleine Bugs
- **E1 ⬜ Layout-Drift-Polish:** uneinheitliche Ausrichtung/Abstände (Kataloge/Angebote/
  Alle-Angebote nicht bündig) — Sweep, gegen Screenshots prüfen.
- **E2 ⬜ Mail-Toggle-Aktivton:** Pflaume (aktuell) vs. Terrakotta — 1-Token-Tausch, deine Wahl.
- **E3 ⬜ Laufende Klein-Bugs** aus dem Screenshot-Feedback-Loop (Bild→Kommentar→verbucht).
- **E4 ⬜ Skalierungs-Review überall (Johannes 2026-07-05):** ALLE Bild-/PDF-/Fenster-Skalierungen
  durchgehen — großes Bild/Dokument passt sich sauber dem Rahmen an (DocumentViewerView-Fix global,
  Hero-Bild, Viewer, Widgets). UI-Polish „wie überall besprochen", gegen Screenshots geprüft.

## Track F — Große Stränge (eigene Sessions, Entscheidung nötig — NICHT jetzt)
Aufgaben-Widget-Katalog · Visitenkarten-Scan→Kontakt · Theme-System (Standard/Editorial) ·
Ordner-Schema-Editor · Dokumenten-Template-Katalog · universeller Checkout (alles pickbar).

## Track G — Kamera als „Erfassen"-Subsystem (Johannes 2026-07-05, Vision)
Der Kamera-Widget ist der **Erfassen-Verb** des Studio-Graphs: Knoten reinholen → Kontext
vorschlagen → **bestätigen** → in den Graph. Ausbau in Increments (jeder: Vorschlag→Bestätigung→
Audit→SoR, nie destruktiv, Airtable = Outer Limit, Daniels Base heilig):
- **G1 ✅ Bestätigungsdialog vor Kamerazugriff** (commit `5c8aa32`) — `confirmationDialog` vor der Kamera. Erledigt.
- **G2 Barcode → Artikel-Lookup → verbuchen:** gescannter Code → `ArtikelKatalogStore`-Lookup →
  per Bestätigungskarte **in den Checkout/Warenkorb** (WorkBasket) ODER **im Katalog verbuchen**.
  = volles System-I/O.
- **G3 Foto → smarte Kontext-Zuordnung:** Foto machen → Tool **schlägt Zuordnung vor** (Projekt
  ODER Datenkategorie) → Bestätigung → Ablage. „Kamera → Kataloge → Content → Projekt-Switch + Vorschlag."
- **G4 Universelle Ingest-Naht:** jede Erfassung (Barcode/Foto/Scan) durch dasselbe Muster —
  verbindet Fundament ① (Checkout) + Visitenkarten-Scan. Der „Erfassen"-Verb einmal für alle.
- **G5 Visitenkarten-Scan → Kontakt** (Zwilling vom Barcode): Kamera + **OCR** (`VNRecognizeTextRequest`)
  → **Erkennung** der Felder (Name/Firma/Mail/Tel/Adresse) → **Edit-Mode-Sheet** (erkannte Felder
  review + korrigieren) + **Dubletten-Check** → **Bestätigung** → schreibt in **Google Contacts UND
  Airtable-Kontakte** (nie destruktiv). Teilt die Kamera-Pipeline mit Barcode (③).
  ⚠️ Airtable-Kontakt-Write existiert schon (`ContactActionCard`/`AirtableContactActionCard`, S19, gated);
  **Google-Contacts-Write ist NEU** — braucht People-API-Write-Scope + Re-Consent (Johannes).
- **G6 Kontaktselbstheilung** (Handeln-Verb auf Kontakt-Knoten): Kontakte heilen sich aus jeder Quelle
  (Visitenkarte/Mail-Signatur/PDF-Picker) — Lücken füllen, Dubletten mergen, Veraltetes aktualisieren.
  Immer Vorschlag→Bestätigung→Audit, **nie destruktiv**. = der „selbstheilende Graph" (bündelt die
  Kontakt-Alerts + „universelles Zuordnen/Kontextualisieren" aus dem Backlog).
  - ⛔ **EISERN (Johannes 2026-07-05): Kontakte in Airtable NIEMALS löschen.** Merge/Dedup = den
    unterlegenen Record per `updateRecord` auf `Status = Archiviert/Old` **flaggen** + auf den Sieger
    verweisen. NIE DELETE. Der Code erzwingt es bereits: `deleteRecord` wirft außer der (leeren)
    `testDeletableMap`. G6 nutzt ausschließlich `updateRecord`.
- **G7 Über Übersichts-Widget aufrufbar:** Kamera-Ingest (Barcode ✅, Visitenkarten-Scan G5) lebt als
  **eigenes Widget auf der Übersichtsseite** (wie das Barcode-Widget) — der Erfassen-Verb im Cockpit-Überblick.
- **G8 „Verwendung wählen" nach JEDEM Scan (Kernidee Johannes 2026-07-05):** jeder Scan öffnet ein
  kontextuelles Aktions-Menü — *was willst du damit tun?* Kandidaten je nach Erkennung: „In Warenkorb" ·
  „Artikel anlegen" · „Lager ein-/ausbuchen" · „Kontakt anlegen/heilen". **Ein Scanner, viele Ziele**
  (= G4 Ingest-Naht konkret). Scanner erkennt Barcode vs. QR vs. Text/Karte und bietet passende Verwendungen.
- **G9 Artikel-/Lager-Ingest per Kamera:** unzählige Kleinteile/Modularteile per Barcode/Foto sauber in die
  Lagerliste einsortieren, mit Daten anreichern + sortieren; neue Artikel anlegen; Bestand aus-/einbuchen.
  ⛔ **GOVERNANCE-WEICHE (Johannes/Daniel, VOR dem Bau):** Artikel+Lager liegen in **Daniels Base
  `appdxTeT6bhSBmwx5` — heilig, bestehende Records NIE ändern/überschreiben/löschen.** „Aus-/einbuchen"
  *ändert* bestehende Mengen = genau das Verbotene. → Schreib-Ziel = **mykilOS-eigene Lager-/Artikel-Base**
  (Abnabelung §8b, `docs/AIRTABLE_ARCHITEKTUR.md`), Daniels Base nur read-only Spiegel; Bestand als
  **append-only Bewegungen** (Ein-/Ausbuchen = neuer Datensatz, Stand = Summe), nie in-place. Erst Entscheidung, dann Bau.

### Airtable-I/O-Routen für G5/G6 (Ist-Code, Sweep 2026-07-05 — andocken statt neu bauen)
**Kontakte:**
- Lesen Airtable: `AirtableContactsLoader` → `AirtableClient.mapContacts` (Tabelle `Kontakte`, Mastermind).
- Lesen Google: `GoogleContactsClient.searchContacts` (People API, read-only).
- Schreiben Airtable: `AppState.createRecord/updateRecord` → `Kontakte` (gated, S19) + Dedup via
  `ContactImportPlanner` / `ContactsImportView`. Draft-Typ: `AirtableContactDraft`.
- **Schreiben Google: FEHLT** — `GoogleContactsClient` read-only → neue `createContact`/`updateContact`
  + People-API-Write-Scope + Re-Consent (Johannes).

**Ganze Airtable-Schreib-Fläche (Kontext):** `AppState` (Kontakte/Intake-Kunde+Projekt/Fragebogen-Routing) ·
`CartStore` (Warenkörbe/Projektartikel) · `SevdeskPostboxCheckoutPort` (Postbox) · `ProjektProvisioningService` ·
`KalkulationsEngine` · `ClockodoAdapterWriter` (Zeit) · `WriteShadowRecorder` (Backup) · `DataFlowLogger` (Log).
DELETE nur `TestSandboxCleaner` (TEST-Whitelist). Alle gated über `AirtableClient.writableMap`.

## Track H — Widget-Katalog & Spielwiese (Fun-Widgets + Toggles, Johannes 2026-07-05)
Neue Übersichts-Widgets + spielerische Toggles. **Design-Nordstern: minimal/schön/smart** —
Anregung, nicht Maximal-Ausbau; kleinste sinnvolle schöne Lösung, kein Gimmick-Overload.
- **H1 Taschenrechner-Widget** ✅ (gebaut, Braun-Look, alpha16). **Offen (Feedback 2026-07-05):**
  Hardware-**Num-Block-Eingabe** (`.onKeyPress`, macOS 14+, mit dezentem „aktiv"-Fokus-Rahmen).
- **H2 Heuler** — opt-in „Brüllbrief"-Alert (laut, wenn's brennt), abschaltbar pro Quelle (Alerts-dezent-Regel).
- **H3 Boss-Button** 🥹 — schwebender Satellit-Button (Feierabend-Ritual / Chef-Moment), eigenes
  `NSWindow` über Spaces (groß, eigener Strang — siehe Backlog).
- **H4 Rainbow/Freaky-Friday-Mode** — Rainbow Mode existiert schon (Easter Egg); ausbaubar als wählbarer Fun-Toggle.
- **H5 Widget-/Toggle-Katalog** — weitere Übersichts-Widgets (ClickUp-Aufgaben/Termine+Aufgaben/Memos)
  + Settings-Toggles, tasteful.

## Track I — Personal Colour Picker (Johannes 2026-07-05)
Farb-Werkzeug fürs Studio (Moodboard: Datacolor ColorReader) — Farben wählen/erfassen → Paletten,
für Material-/Interior-Farbwelten. **Design-Nordstern: minimal.**
- **I1 In-App Colour Picker** (nativer `ColorPicker` / Palette-Auswahl), pro User, persistiert.
- **I2 Palette-Speicher** — eigene Farbpaletten anlegen/benennen (lokal).
- **I3 Datacolor-Import** (Shared Palette / Gerät) — externes I/O, eigener Strang, Zukunft.

## Track J — Tiefere User-/Benutzerebenen + Einstellungen (Johannes 2026-07-05)
Rollen/Rechte/„sichtbare Bereiche" + Settings-Tiefe. Verbindet D1-Rechte-Schicht (S10 §9) + Datenschutz-UI.
- **J1 Settings-Tiefe** — alle nutzer-persönlichen Optionen sauber strukturiert (Private Area ausbauen).
- **J2 Datenschutz-Abschnitt** + „KI komplett aus"-Master-Switch + „Meine Daten exportieren"
  (DSGVO Art. 15/20). ⚠️ braucht Johannes' Wording/Freigabe (Rechtstexte nie selbst formulieren).
- **J3 Rollen/Rechte/sichtbare Bereiche** (D1) — größerer Strang, Team-Entscheidung.
Per-User-Isolation (Mail/Memos/Chat nie kreuzlesbar) + Alerts-dezent + Toggle je Quelle bleiben eisern.

## Track K — Versand-/DHL-Widget (Johannes 2026-07-05)
**Aus Kontakten + Artikeln + sonstigen Listen-Items direkt in DHL (oder andere Anbieter) ziehen**
→ Sendung anlegen → **Sendungsnummer zurück in mykilOS** → Versand verbuchen. Das ist ein
**Checkout-Port auf Fundament ①** (Pick/Drag&Drop) — Versand-Ziel statt Warenkorb. Increments:
- **K1 VersandPort** (analog `SevdeskPostboxCheckoutPort`): Pick/WorkBasket (Empfänger-Kontakt +
  Artikel/Paketinhalt) → Versand-Auftrag. Drag&Drop aus allen Katalogen (Fundament ① / Track B) als Eingang.
- **K2 Sendungsnummer-Rückweg (Erfassen):** Tracking-Nr. kommt zurück → in den Graph, am Projekt sichtbar.
- **K3 Versand verbuchen (Handeln):** Sendungs-Record (Empfänger/Inhalt/Tracking/Datum) → Airtable/Projekt,
  Vorschlag→Bestätigung→Audit, **nie destruktiv**; Timeline-Marker „versendet".
⚠️ **Externe I/O (Interior-Build-Charter):** DHL-Geschäftskundenportal-API (+ andere Carrier) = **Outer
Limit** → sauberer **Adapter/Port + Credentials im Keychain** (nie roh, nie im Repo), Postbox-/
Preview→Confirm-Disziplin wie sevDesk. **Carrier-neutral** ziehen (Nordstern: fremde Anbieter andockbar).
Eigener größerer Integrations-Strang.

## Track L — Abnabelung von Daniels Base + eigene Bases (Johannes bestätigt 2026-07-05)
Richtung **ENTSCHIEDEN** (= §8b in `docs/AIRTABLE_ARCHITEKTUR.md`, jetzt von Johannes bekräftigt): die App
hängt künftig **nur an mykilOS-eigenen Bases.** Zwei Phasen:
- **L1 Einmal sauber spiegeln (Copy-in):** Daniels Artikel/Lager/Kunden/Projekte EINMAL in eine
  mykilOS-eigene Base kopieren + re-sortieren. Daniels Base = **read-only Upstream**, nie mehr direkt beschrieben.
- **L2 Fortschreiben für uns:** ab da schreibt/reichert mykilOS in der EIGENEN Base an. Ein **Feeder** hält
  Daniels sevDesk/Make-Pipeline über den **Business-Key** (Kundennummer/Projektnummer) gefüttert (er merkt nichts).
- **L1b Übersetzungs-Schicht + laufende, idempotente Einschleusung (Johannes 2026-07-05):** zwischen
  Daniels Base und unserer liegt eine **Mapping-Schicht**, die seine Systematik in UNSERE übersetzt
  (Seed: `ExternalMappingRegistry` / „Archiv-Übersetzung", nicht Greenfield). Der Copy-in ist **kein
  Einmal-Akt**, sondern ein **wiederholbarer, idempotenter Sync**: neuer Schwung bei Daniel (z. B. 2000
  Artikel) → nur **neue/geänderte** übersetzt + **fortgeschrieben**, Rest unangetastet. **Dedup** per
  Artikelnummer/SHA256 (Muster existiert, Eingehende-Angebote). **NIE überschreiben:** Änderung = neue
  **Version** (append-only, Historie bleibt), „aktuell" = jüngste. Zweimal einschleusen = harmlos.
- **Schreibgesetz überall:** jedes Anreichern/Fortschreiben durch **„ich hab was → was/wohin/warum →
  okay/nicht okay → Audit"** (Handeln-Verb: Vorschlag→Bestätigung→Audit, nie destruktiv, verifizierter User-Review).
- **Schaltet frei:** G9 (Artikel/Lager-Ingest schreibt in die eigene Base). **Braucht Daniel am Tisch**
  (Schreib-Übergabe/Business-Keys). Voller Strangler-Migrationsplan: `docs/AIRTABLE_ARCHITEKTUR.md` §4/§6/§8b.

---

## Empfohlene Reihenfolge (step by step — du steuerst)
1. **A2+A3** Barcode fertig machen (Stein liegt schon halb — Test + echte Kamera).
2. **C1+C2** Mini-Mode V1.1 (du hast „nicht sauber" genannt — konkret + verriegelt).
3. **B1** Positions-Pick-Bug (kleiner Fix, echter Schmerz).
4. **D1 + E1** Warenkörbe-Sammlungsansicht + Layout-Drift.
5. **B2** Globales Drag&Drop (der große, fundamentgestützte).
Danach Track F nach deiner Ansage. Klein-Bugs (E3) laufen parallel über den Feedback-Loop.
