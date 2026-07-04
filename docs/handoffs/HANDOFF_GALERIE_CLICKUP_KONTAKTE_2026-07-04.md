## Handoff — Galerie-Flug, ClickUp-Ausbau, Kontakte-Migration Schritt 1, Positions-Picker

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/plaene-katalog
Build:  ✅ swift build grün
Tests:  ✅ 940 Tests grün (swift test) — 913 vor dieser Session
Datum:  2026-07-04
```

### Was in dieser Session gebaut wurde

**1. Galerie-Flug (komplett, alle 8 Teilpunkte):**
- Liste ⇄ Galerie-Umschalter in Dateien-Tab + Material-Tab, echte Mini-Thumbnails
  (`ThumbnailStore`: `QLThumbnailGenerator` lokal, Drive-`thumbnailLink` remote, dynamisch
  auf Zielgröße hochskaliert statt fix `=s220`).
- Finder-Slider für Kachelgröße, Hover-Anheben (MykMotion), Einfachklick-Anwahl +
  Leertaste/Doppelklick-Vollvorschau.
- **Blättern + Diashow:** `DocumentViewerView` nimmt jetzt Sammlung+Index
  (`DocumentViewerItem`) statt nur einer Datei — ←/→ blättert, Leertaste startet/pausiert
  Auto-Advance (3,5 s, wrapt am Ende).
- Hero-Bild-Konsistenz: Favoriten-Mini-Karten zeigen jetzt das echte Projekt-Hero-Bild
  (vorher nur Archetyp-Gradient).

**2. PDF-Positions — Discoverability-Fix + echter Bug + Art.-Nr.:**
- „Positionen herauslösen" war nur im Rechtsklick-Menü versteckt → jetzt sichtbarer Button.
- **Bugfix:** globale „Alle Angebote"-Ansicht schrieb herausgelöste Positionen in einen
  flüchtigen, session-lokalen `WarenkorbState` statt in den echten, persistenten
  `WorkBasketStore` — sie verschwanden beim Neustart. Jetzt schreiben beide Ansichten in
  denselben echten Korb.
- **Art.-Nr.-Extraktion** (`OfferPositionExtractor.artikelnummer(in:)`, Muster am echten
  Alt-Korpus verifiziert: „Art.-Nr. 155.01.595" etc.).
- „In Warenkorb" trägt jetzt ALLE Infos: Art.-Nr., voller Original-Positionstext, Quelldatei,
  Seite, Richtung (`PickSnapshot.attribute`, gemeinsamer Helper `positionsAttribute(...)`).
- **Offen/ehrlich benannt:** sevDesk-Postbox-`CheckoutPort` existiert technisch noch nicht
  (nur `CheckoutPort`-Protokoll + Dokument-/Moodboard-/Firefly-Prompt-Port). Positions-Daten
  liegen jetzt vollständig bereit, der eigentliche „Drop in den Briefkasten" ist ein eigener,
  noch zu bauender Strang — braucht zuerst einen Blick auf das reale sevDesk-Postbox-
  Airtable-Schema (nicht recherchiert).

**3. ClickUp-Ausbau:**
- `ClickUpTaskWriting` (Aufgabe anlegen mit `content`, Status setzen) + isolierte
  **Test-Werkbank** (`ClickUpTestWerkbankView`, Settings → ClickUp) — schreibt AUSSCHLIESSLICH
  in die Sandbox-Liste „KUE-2026-014 Küche Müller TEST" (`901218940344`) im Testspace
  `90128024109`. Ghost-Kürzel nur als Text-Marker, nie natives Assignee-Feld.
- **ClickUp-Phasen-Abgleich:** Lebenszyklus-Stepper zeigt dezenten Hinweis „ClickUp sagt:
  Ausführung" bei Divergenz zum Custom Field `project_phase` (7 Stufen → 5 mykilOS-Stufen
  gemappt) — kein Auto-Write in beide Richtungen.
- **Noch offen:** interaktive Write-Basics in der ECHTEN, projektgebundenen `TasksWidget`
  (aktuell nur die isolierte Test-Werkbank) — Ghost→echt-Wiring braucht Johannes' Freigabe.

**4. Kontakte-Airtable-Migration, Schritt 1:**
- `GoogleContactsClient.listAllContacts()` (neu, paginiert über `people.connections.list`,
  anders als das Query-basierte `searchContacts`).
- `ContactImportPlanner` (rein, 7 Tests): dedup über Mail/Telefon, verwirft Kontakte ohne
  Mail UND Telefon.
- **`ContactsImportView`** (Settings → Google, nur bei Google+Airtable verbunden): Vorschau
  laden → Zahlen ansehen → „N Kontakte anlegen" bestätigen. Schreibt über bestehenden
  `AppState.writeAirtableContact(.create)`-Pfad.
- **Warum nicht automatisch von mir ausgeführt:** braucht Johannes' echte Google-OAuth-Session
  in der laufenden App — dazu habe ich keinen Zugriff.
- **Noch offen (Schritt 2):** `ContactsWidget` (Projektseite) liest weiterhin live von Google;
  Umstellung auf die kuratierte `Kundenkontakte`-Airtable-Tabelle kommt erst NACH dem Import.
- Kontakte-Widget: Mail-Adresse jetzt klickbar → öffnet `ComposeMailView` vorbefüllt.

**5. Rainbow Mode 🌈:** Easter-Egg-Toggle in Settings → Darstellung, Hue-Shift auf jeden
`MykColor`-Token, `.id(rainbowMode)` erzwingt sofortigen Redraw.

**6. Free-Climber-Anker-Sweep:** zwei veraltete Backlog-Behauptungen korrigiert, die
tatsächlich schon gefixt waren (toter „Wiederherstellen"-Button, „Mail Senden fehlt").

### Datenstrom-Handbuch (Airtable + lokales Manifest)
Neuer Eintrag `GOOGLE_CONTACTS_TO_AIRTABLE_IMPORT` in beiden Quellen (Airtable
`tblaUVftka0GvXzeU` + `Sources/MykilosApp/Resources/DatastromManifest.json`) —
`DatastromAuditTests` erzwingt das automatisch (Test schlägt fehl, wenn eine neue
integrationID nicht im Manifest steht).

### Docs aktuell gehalten
`docs/IDEEN_UND_BACKLOG.md`, `docs/BENUTZERHANDBUCH.md`, `docs/CLICKUP_PROJEKT_MAPPING.md` —
alle Punkte oben sind dort mit Status markiert (✅/🚧).

### Nächste Session — konkrete Einstiegspunkte
1. **sevDesk-Postbox-CheckoutPort bauen** — Johannes' Motivation: Position vom
   Tischler-Angebot „schnappen" + mit allen Infos in den Airtable-Briefkasten droppen
   (NIE direkt nach sevDesk schreiben). Braucht zuerst das reale Postbox-Airtable-Schema.
2. **ClickUp-Write-Basics ins echte TasksWidget wiring** (nach Verifikation der
   Test-Werkbank durch Johannes, Ghost→echt-Freigabe).
3. **Kontakte-Migration Schritt 2** — nachdem Johannes den Import einmal live laufen lassen
   hat: `ContactsWidget` auf `Kundenkontakte`-Tabelle umstellen (klick/zuweis/editier).
4. Galerie-Flug auf Zeichnungs-Katalog + globales Angebote-Modul ausrollen (bisher nur
   Dateien-Tab + Material-Tab).

### DMG
`dist/mykilOS-10.0.0-alpha13.dmg` (13M) — frisch aus dieser Session, inkl. aller obigen
Features.
