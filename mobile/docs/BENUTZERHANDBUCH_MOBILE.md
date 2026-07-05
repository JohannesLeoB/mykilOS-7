# Benutzerhandbuch — mykilOS mobile

Die Mothership-Doktrin gilt auch im Orbit: **jede Funktion dokumentiert**,
je mit *Was es tut · Wo zu finden · Voraussetzungen · Einschränkungen*.
Entfernte Funktionen werden hier gelöscht, nicht als „deprecated" geparkt.
Zielgruppe: Johannes + Team. Stand: 04.07. (9 Batches).

---

## Herzschlag-Bildschirm (Start)

**Begrüßung + Morgen-Brief** · Liest auf Knopfdruck (Lautsprecher-Symbol)
Projektanzahl, offene Postbox und offene Feld-Fotos laut vor. · Oben rechts
neben der Begrüßung. · Keine. · Reine Sprachausgabe, kein Mikrofon.

**Fang-Karte („Sprich oder tippe")** · Ein Moment rein — „4h CAD für Heinz"
wird als Zeit verstanden, „Idee: …" als Idee; Karte→Bestätigen→Postbox,
nie automatisch. · Direkt unter der Begrüßung. · Mikrofon+Spracherkennung
fürs Diktat. · Versteht bewusst nur Dauer-Muster (h/Std) — nie raten.

**Kamera-Fang (3 Wege)** · Kamera-Knopf fragt: **Feld-Foto** (Projekt-Doku
mit EXIF-Zeit/Ort, Kanon-Zielschublade), **Visitenkarte** (OCR → editierbar
→ iOS-Kontakt), **Lieferschein** (OCR → Tracking/Absender → Wareneingangs-
Log). · Fang-Karte. · Kamera; Kontakte nur für Visitenkarten; Standort
optional. · OCR ist Vorschlag, nie Fakt; Wareneingang ohne Bestelllisten-
Abgleich (kein WorkBasket-Sync auf mobile).

**Puls-Kacheln** · Projekte/Küchen/Studio-Zahlen plus tippbare Einstiege:
Postbox, Fotos, Pakete. · Unter der Fang-Karte, horizontal scrollbar. ·
Keine. · Zählt lokale Daten, kein Server.

**Standort-Wächter-Karten** · Nach erkanntem Aufenthalt bei gemerktem
Projekt-Ort: „Du warst bei X — 1h 45min. Als Zeit in die Postbox?" ·
Erscheint oben im Herzschlag. · Standort-Wächter-Toggle EIN + gemerkter
Ort. · Nur Vorschlag, nie automatisch gebucht.

**Projektliste** · Alle 31 Projekte, Suche nach Name/Nummer, aufklappen →
Drive-Ordner-Sprung; bei aktivem Wächter: „Diesen Ort merken". · Unten im
Herzschlag. · projekte.json im App-Bundle. · Liste ist Snapshot, kein
Live-Sync mit der Mothership-Registry.

## Postbox & Sync

**Postbox** · Alle bestätigten Fänge, neustart-fest; Zeit-Einträge einzeln
in die Airtable-Adapter-Base syncbar; Ideen teilbar (Ziel-Heimat noch
offen); Löschen nur unsynchronisiert. · Puls-Kachel „Postbox". · Airtable-
PAT für Sync. · Sync ist bewusst ein eigener Knopf — nie automatisch
(Downlink-Doktrin).

**Feld-Fotos** · Liste aller Projekt-Fotos, Drive-Sync je Foto,
„Förderrelevant"-Markierung (Kontextmenü), Förder-Beweispakete (Roh-Bündel
oder PDF-Bericht mit Deckblatt + datierten Seiten). · Puls-Kachel „Fotos";
Beweispakete über das Rosetten-Symbol. · Google-Verbindung für Sync. ·
Drive-Schreiben in vorhandene Ordner ist die eine ungetestete
★3-Annahme (403 = Befund).

**Wareneingang** · Log aller Lieferschein-Fänge (Projekt, Tracking,
Absender, Zeit). · Puls-Kachel „Pakete". · Keine. · Reiner Rohdaten-Log.

## Assistent & Verbindungen

**Claude-Assistent** · Chat übers Cockpit, streamt live, Verlauf
neustart-fest + löschbar. · Sprechblasen-Symbol oben. · Anthropic-API-Key
(Schlüsselbund). · Kennt nur, was du ihm schreibst — keine App-Daten-Tools
in v0.

**Verbindungen (Fähigkeiten-Panel)** · Airtable/Claude/Google-Status je mit
Verbinden/Trennen; dazu die Off-by-default-Toggles: **Standort-Wächter**
(Geofencing, sofort widerrufbar inkl. aller Orte) und **Bluetooth-Laser**
(Suchen/Verbinden/Service-Explorer, 11 Hersteller erkannt). · Antennen-
Symbol oben. · Je nach Dienst: PAT/API-Key/Client-ID. · Laser liefert noch
KEINE Messwerte — Protokoll erst nach Geräteentscheidung; alle Secrets nur
im Schlüsselbund.

## Werkzeuge (Schraubenschlüssel-Symbol)

**Beleuchtungs-Check** · Foto → hell/mittel/dunkel + Empfehlung. · Kamera. ·
Keine Lux-Zahl, kein Sonnenstand — grobe Kategorie.

**Barcode/QR-Scanner** · Live-Scan → neustart-festes Log, teilbar. ·
Kamera, Gerät mit Scanner-Support. · Kein Bestelllisten-Abgleich.

**Wasserwaage** · Punkt + Gradzahl, grün ab ±0,5°. · Keine. · Gyroskop-
Genauigkeit, kein Ersatz für die Richtlatte.

**Farbtemperatur-Check** · Foto → warm/neutral/kühl. · Kamera. ·
Ausdrücklich kein Kelvin-Messwert — Bildverhältnis-Schätzung.

**Raumakustik-Check** · 3 s Pegel → ruhig/normal/laut. · Mikrofon. · Keine
Nachhallzeit, kein dB-Messgerät; nichts wird gespeichert.

**Abnahmeprotokoll** · Nummerierte Mängel je Projekt: diktieren oder
tippen, optional Foto, Export als übergabefähiges PDF. · Werkzeuge. ·
Mikrofon fürs Diktat. · Nummer = Listenposition; lokal, kein Sync.

**Planmodelle · AR** · USDZ importieren (VectorWorks → Reality Converter →
AirDrop), Projekt zuordnen, in AR im Raum zeigen. · Werkzeuge. ·
USDZ-Datei; AR-fähiges Gerät. · Frei platzierbar — KEINE automatische
Raum-Ausrichtung (Stufe 2, offen).

**AR-Maßband** · Zwei Punkte antippen → Distanz. · AR-fähiges Gerät. ·
cm-Genauigkeit — Drei-Toleranzen-Doktrin: fürs Verbindliche der Laser.

**AR-Anker · Gewerke** · Wasser/Strom/Abfluss im Raum markieren → Screenshot
mit Markern → Feld-Foto-Ablage. · AR-fähiges Gerät. · Marker leben nur in
der laufenden Session.

**RoomPlan-Aufmaß** · Raum scannen → 3D (USDZ, Vorschau + Teilen), dazu
**PDF-Grundriss** (Wände + Maße) und **DXF** für VectorWorks (Einheit
Meter). · Werkzeuge; gespeicherte Scans unter „Raumscans". · iPhone/iPad
**mit LiDAR**. · ±1–2 cm typisch — Referenz, kein Werkmaß; DXF-Import in
VectorWorks noch nie live getestet.

---

## Datenschutz-Grundsatz (gilt überall)

Alles startet AUS, alles ist sichtbar, alles ist mit einem Tipp widerrufbar
(§14-Doktrin). Schreiben passiert nie automatisch — immer Karte →
Bestätigung. Secrets nur im iPhone-Schlüsselbund. Volle Berechtigungsliste:
`docs/20_BERECHTIGUNGEN.md`.
