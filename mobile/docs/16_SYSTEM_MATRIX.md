# Die System-Matrix — sieben Achsen, ein Bauplan

**Auf Johannes' Wort: „Die Sensoren, das Szenario, das Projekt. Die Daten. Ins
und Outs. Safeties. Regeln. Layer."** Nicht noch eine Themenliste (die steht in
`15_NACHT_BUENDELUNG.md`) — hier das Skelett, durch das jede Idee der Nacht
gelesen werden kann. Dicht, referenzierend, keine Doppelerzählung.

---

## 1. Die Sensoren (Inventar → Detail: `13_SENSORIK_TECHNIK.md`)

| Familie | Kern-API | Liefert |
|---|---|---|
| Kamera/Bild | `AVFoundation`, `Vision`, `DataScanner` | OCR, Barcode, Material-Kandidaten |
| Mikro/Sprache | `Speech` (on-device Deutsch), `AVAudioEngine` | Transkript, Nachhallzeit (Sweep) |
| Ort | `CoreLocation`, `CLGeocoder` | Adresse, Geofence, Sonnenstand-Input |
| Bewegung | `CoreMotion` (Gyro, Barometer) | Lot/Waage, Etagenwechsel, Transport-Stöße |
| AR/Raum | `ARKit`, `ARWorldMap`, `RoomPlan`* | Maße ±1-2cm, persistente Anker, 3D (*nur LiDAR) |
| Bluetooth-Zubehör | `CoreBluetooth` | Laser (mm), ColorReader (Werkfarbe), FLIR (Wärme), Trotec (Feuchte) |
| NFC | `CoreNFC` | Projektanker, Ausrüstungs-Sticker |
| System | `App Intents`, `WidgetKit`, `ActivityKit` | Fingerschnipps, Puls-Widget, Live-Timer |

## 2. Das Szenario (wann im Tag greift was)

| Moment | Sensoren aktiv | Führende Muster |
|---|---|---|
| Ersttermin/Erstgespräch | Mikro, Kamera | Versteh-Kaskade, Intake-Fingerschnipps |
| Aufmaß-Termin | AR, Bluetooth-Laser, Ort | Drei-Toleranzen-Doktrin, Adress-Loop |
| Rundgang/Bestandsaufnahme | Kamera, Licht/Farbe | Wächter-Blick, Planungs-Assistent |
| Wareneingang (Werkstatt) | Kamera/Barcode | Wächter-Blick (Barcode-vs-WorkBasket) |
| Montage/Abnahme | Kamera, Mikro, Bluetooth | Geführte Perspektiven, Diktat-Protokoll |
| Unterwegs/Logistik | Ort, Kalender | Logistik-Cluster, Vorabend-Regel |
| Portfolio/Förderung | Kamera, AR-Anker | Portfolio-Einverständnis, Perspektiven-Sequenz |

## 3. Das Projekt (Mothership-Anker, wo jede Fähigkeit andockt)

- **Registry** = der Graph (wer gehört zu wem) — Projektnummer ist die Königs-ID
- **WorkBasket** = Kosten-/Material-Wahrheit — Wächter-Blick vergleicht IMMER dagegen
- **Drive-Kanon** = Puls (`modifiedTime`) + Zielschubladen (02/06/09) für ★3
- **KalkulationsEngine (`schaetze`)** = Preisziel jeder Kosten-Kamera
- **DeviceCatalog** (13.419) = Ziel jedes Geräteakte-Treffers
- **Airtable Kunden/Adressen** = Ziel des Adress-Loops und der Visitenkarten-Kamera
- **studio_brain.json** = Lieferanten-/Orts-/Team-Lexikon für den Versteh-Kern

## 4. Die Daten (Typen, die durch das System fließen)

Foto (Kontext/Beweis) · Maß (3 Stufen: Foto/AR/Laser) · Zeit (Postbox „Vorgebucht")
· Adresse (bestätigt, nie Bewegungsspur) · Kontakt (OCR) · Farbe (Kelvin=Schätzung,
ColorReader=Werkfarbe) · Temperatur (Wärmebild-Kandidat) · Akustik
(Nachhallzeit-Kategorie) · Audio→Transkript (Audio verglüht) · Barcode/Seriennummer
· Diktat-Text · GPS+Kompass (Sonnenstand-Input)

## 5. Ins und Outs (zwei Richtungen, nie vermischt)

**OUT — Satellit → Schiff** (voll in `12_DOWNLINK_DOKTRIN.md`):
Zeiten→Adapter-Base · Fotos→Drive-Kanon (★3) · Aufmaße→Projektordner ·
Fragebogen→Intake-Straße · Adressen→Kunden (gated) · Geräteakten→Notiz+Katalog ·
Förderungs-Belege→Beleg-Paket. **Immer:** Daten, nie Befehle. Append-only, gated.

**IN — Schiff → Satellit** (bisher narrativ, hier erstmals als Tabelle):

| Was kommt rein | Woher | Wofür |
|---|---|---|
| Projekt-Graph | Registry/Airtable | Versteh-Kaskade, Kandidaten-Karte |
| WorkBasket-Stand | Schiff (GRDB→Airtable-Spiegel) | Wächter-Blick-Vergleich |
| Packliste „vergiss nicht" | Termin-Anhang | Vorabend-Flüstern, Live-Checkliste |
| Kalender/Termine | Google Calendar | Adress-Loop, Zeit-zum-Aufbrechen |
| Lieferanten-/Team-Lexikon | studio_brain.json | Versteh-Kern-Vokabular |
| Preiskatalog (DeviceCatalog) | Schiff (read-only) | Geräteakte-Matching |
| CAD-Grundriss (vereinfacht) | VectorWorks/Onshape-Export | AR-Vorschau im Raum |

## 6. Safeties (RAIL-Schicht, Details in `02` + `14`)

- **Zwei-Tank-Doktrin:** Repo-Trennung, nie Branch — Schiff für immer read-only
- **Externe Writes:** nur gated Karte→Bestätigung→Audit, nie automatisch
- **Datenschutz-Transparenz (§14):** Opt-in statt Opt-out, Fähigkeiten-Panel,
  1-Klick-Widerruf — gilt auch für reine Reads (Mikro/GPS/Kamera-Dauerlauf)
- **Portfolio ≠ Dokumentation:** eigenes, separates Einverständnis
- **Fachmann-Pflicht:** sicherheitsrelevante Wächter-Fälle (Elektro, Sicherungskasten)
  verweisen IMMER an Fachbetrieb — Kandidaten-Karte reicht dort nicht
- **Reality-Check-Ritual + Downlink-Blick:** vor jedem Thematisieren, inkl. „was
  braucht das Schiff gerade"

## 7. Regeln (die Muster-Familie, Details in `07_VERSTEH_KERN.md`)

- **Versteh-Kaskade:** Projektnummer → Name → Kandidaten-Karte → Rückfrage. Nie raten.
- **Wächter-Blick:** A (Foto/Messung) gegen B (Plan/Wunsch/Bestellung/Kapazität) —
  warnt nur bei Abweichung. 12 Fälle bisher, zwei Unterarten (hart/Qualität).
- **Planungs-Assistent:** synthetisiert Signale zu einer POSITIVEN Empfehlung
  (kein Alarm). Erster Fall: Licht-Platzierung.
- **Toleranzen-Doktrinen:** Maß (Foto/AR/Laser) und Farbe (Kamera/ColorReader) —
  gleiche Struktur, zwei Domänen.

## 8. Layer (die Architektur-Schichten, aus `13_SENSORIK_TECHNIK.md`)

```
FANG            Sensor/Framework, on-device, roh
  ↓
VORVERDICHTEN   on-device: OCR, Transkript, Geocoding — Rohdaten bleiben lokal
  ↓
VERSTEH         Kandidaten-Karte/Kaskade — Cloud-KI nur wo nötig
  ↓
VERRÄUM         Postbox/Drive/Airtable, gated, Offline-Queue wenn kein Netz
  ─ ─ ─ ─ ─ ─ ─  ← TANK-GRENZE (Satellit endet hier, Schiff liest von dort)
SCHIFF          Registry/WorkBasket/KalkulationsEngine — ausserhalb des Satelliten
```

Jede Fähigkeit aus der Nacht lässt sich durch alle acht Zeilen dieser Matrix
lesen — Sensor, Szenario, Projekt-Anker, Daten-Typ, Richtung, Safety, Regel,
Layer. Was durch keine Zeile passt, ist noch keine fertige Idee.

---

## 9. Die drei Primitiven (Johannes' Reduktion, 04.07. spaet)

Fast alle "Datenbuendel" der Nacht sind INSTANZEN von nur drei bekannten
Bausteinen - keine neuen Datenstrukturen noetig:

| Primitiv | Existiert schon als | Neue Instanzen heute Nacht |
|---|---|---|
| **Warenkorb** (fuellt sich bis Ziel) | `WorkBasket` (Material-Positionen) | Packliste, Foerderungs-Beweispaket, Perspektiven-Sequenz |
| **Briefkasten** (einbahnig, append-only) | Ideen-Topf, Zeit-Postbox/Adapter-Base | Wareneingang-Ereignisse, Kontakt-Eingaenge |
| **ClickUp-Abhaker** (Checkliste) | ClickUp-Integration (Schiff, NUR Testspace) | Packliste abhaken, Perspektiven-Fortschritt, Waechter-"fehlt X" aufloesen |

**Konsequenz:** ~15 vermeintlich neue Features reduzieren sich auf 3
wiederverwendbare Bausteine, nur unterschiedlich befuellt. Bauaufwand sinkt
drastisch. **RAIL-Grenze:** ClickUp-Abhaker ist fertig gedacht, aber produktiv
gesperrt bis M3 (echte Listen-IDs) - wie STERN-3.
