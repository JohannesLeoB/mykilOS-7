# Erstflug-Checkliste — mykilOS mobile

Geordnetes Testprotokoll für den ersten echten Lauf. Reihenfolge ist bewusst:
erst das Risikolose im Simulator, dann Gerät, dann Sensorik, dann AR, dann
Verbindungen. **Bei jedem Roten: Foto in den Chat — der Satellit fixt.**

## Phase 1 — Simulator (kein iPhone nötig)

- [ ] App startet, „Moin Johannes" + Begrüßung erscheint
- [ ] Puls zeigt **31 Projekte** (nicht 0 — sonst fehlt `projekte.json` im Target)
- [ ] Fang-Karte: „4h CAD für Heinz" tippen → Karte versteht Zeit → Bestätigen → Postbox-Kachel zählt hoch
- [ ] Fang-Karte: „Idee: Messing für die Bar" → Idee-Karte → Bestätigen
- [ ] App beenden, neu starten → Postbox-Einträge noch da (Neustart-Fest-Beweis)
- [ ] Projektliste: Projekt antippen → Drive-Link-Knopf sichtbar
- [ ] Morgen-Brief-Knopf (Lautsprecher): liest Zahlen vor (Simulator hat Ton)
- [ ] Werkzeuge → Abnahmeprotokoll: Projekt wählen, Mangel **tippen** (Diktat braucht Gerät), hinzufügen, „Als PDF teilen" → PDF-Vorschau erscheint
- [ ] Kamera-/AR-/Scanner-Werkzeuge zeigen im Simulator ehrliche „nicht verfügbar"-Zustände — **das ist korrekt, kein Bug**

## Phase 2 — echtes iPhone, Basis (nach Kopplung + Vertrauen)

- [ ] App startet auf dem iPhone, Icon ist orange mit MY + Orbit-Punkt
- [ ] Fang-Karte → Kamera → **Feld-Foto**: iOS fragt Kamera-Berechtigung → Foto → Projekt suchen/wählen → Kanon-Ziel → „Ja, ab in die Drive damit" → Fotos-Kachel zählt
- [ ] Fang-Karte → Mikro: iOS fragt Mikrofon + Spracherkennung → sprechen → Text erscheint → Bestätigen
- [ ] Kamera → **Visitenkarte**: OCR schlägt Felder vor → „Als Kontakt anlegen" → iOS fragt Kontakte-Berechtigung → Kontakt in iOS-Kontakte prüfen
- [ ] Kamera → **Lieferschein**: Paketlabel (oder irgendein Etikett) → Tracking/Absender-Vorschlag → Projekt → loggen → Pakete-Kachel

## Phase 3 — Werkzeuge-Sensorik (iPhone)

- [ ] Wasserwaage: Handy flach → Punkt zentriert sich, „EBEN" bei ruhiger Lage
- [ ] Beleuchtungs-Check + Farbtemperatur-Check: je ein Foto → plausible Kategorie
- [ ] Raumakustik-Check: 3 s still sein → „Ruhig"; danach mal laut → höhere Stufe
- [ ] Barcode-Scanner: EAN von irgendeiner Verpackung → erscheint im Log

## Phase 4 — AR + RoomPlan (iPhone, die ungetestetsten Bausteine)

- [ ] AR-Maßband: bekannte Strecke messen (z. B. 1 m Zollstock daneben) → Abweichung notieren — **cm-Bereich ist erwartbar, kein Fehler**
- [ ] AR-Anker: Wasser-Marker auf eine Steckdose tippen → „Foto mit Markierungen speichern" → landet in Feld-Fotos
- [ ] RoomPlan: kleinen Raum scannen → speichern → Raumscans → 3D-Vorschau
- [ ] Selber Scan: „Als PDF-Grundriss" → Wände + Maße plausibel? (Spiegelungen/Drehungen bitte fotografieren — das wäre ein bekannter, kleiner Achsen-Fix)
- [ ] „Als DXF" → per AirDrop an den Mac → in VectorWorks importieren (Einheit: Meter)

## Phase 5 — Verbindungen & Toggles (iPhone)

- [ ] Claude-Assistent: API-Key eintragen → Frage stellen → Antwort streamt
- [ ] Airtable-Postbox: PAT eintragen → Zeit-Eintrag syncen → in Airtable prüfen
- [ ] Standort-Wächter: Toggle EIN → iOS fragt „Immer"-Standort → bei einem Projekt „Diesen Ort merken" → **Langzeit-Test:** Ort verlassen/wiederkommen → Vorschlagskarte?
- [ ] Bluetooth-Laser: Toggle EIN → „Gerät koppeln" → sucht (ohne Laser: leere Liste ist korrekt)
- [ ] **Google Drive: wartet auf deine iOS-Client-ID (Nachmittags-Termin)** — dann: Verbinden → Feld-Foto syncen → erster echter Test der `drive.file`-Annahme. Ein 403 hier ist ein *Befund*, kein Bug.

## Merkzettel

- 7-Tage-Regel: freie Apple-ID → App nach einer Woche neu bauen (⌘R)
- Alles Rote/Komische: Foto reicht. Der Satellit sitzt auf Empfang.
