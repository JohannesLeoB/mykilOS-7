# Die Nacht-Bündelung — 60 Ideen in 11 Clustern

**Gebündelt 2026-07-04, auf Johannes' Wunsch nach der großen Ideensalve.**
Quelle: `journal/IDEEN_TOPF.md` (60 Einträge) + Musterdokumente. Status-Zeichen:
✅ bewiesen/bestätigt · 🔧 baufertig (Doktrin steht) · 💡 Idee, Bauplan offen ·
⚠️ ehrliche Grenze.

---

## 1. Doktrinen & Muster (das Fundament, nicht Features)
- **Wächter-Blick** — erkennt GEGEN eine Erwartung, warnt nur bei Abweichung (🔧, 12 Fälle, s. Cluster 5)
- **Planungs-Assistent** — synthetisiert Signale zu einer positiven Empfehlung, neu neben dem Wächter (🔧, 1 Fall bisher: Licht)
- **Drei-Toleranzen-Doktrin** — Foto=Schätzung, AR=cm, Laser=mm, nie mischen ✅ (live getestet)
- **Farb-Toleranzen-Doktrin** — Kamera-Kelvin=Schätzung, ColorReader=Werkfarbe ✅ (Gerät bestätigt)
- **Versteh-Kaskade** — Projektnummer→Name→Kandidaten-Karte→Rückfrage, nie raten ✅
- **Kandidaten-Karte als UI-Grundelement** 🔧

## 2. Ersttermin & Kundengespräch
- **Ersttermin-Fingerschnipps:** Bestandsfoto → Versteh → vorbefüllter Fragebogen → V10-Intake-Straße 💡
- **Erstgespräch-Mitschnitt-Pipeline:** OFFEN mit Einverständnis → Transkript → Extraktion → Fragebogen; Audio verglüht, Transkript bleibt 💡
- **Visitenkarten-Kamera → Kontakte** (OCR → gated ContactActionCard) 💡
- **Selbstheilender Adress-Loop:** GPS an der Tür + Kalender-Kreuzcheck → Adresse bestätigen, schließt Downlink-Lücke 💡
- **„Was kostet das?"-Kamera:** Szene (Küche→Erstaufnahme→Engine) + Detail (Griff/Platte→Preisspanne) 💡

## 3. Aufmaß & Bestandsaufnahme
- **Foto-Aufmaß → schaetze-Kette** ✅ (live getestet, Johannes' Maßband-Test)
- **RoomPlan/LiDAR-Aufmaß** → CAD-Zubringer 💡 (braucht LiDAR-Gerät)
- **DISTO/Bosch-Laser-Bluetooth-Brücke** 🔧 (Geräte real, BLE-Protokoll bekannt)
- **Wasser/Strom aus Fotos lesen** ✅ (live bewiesen)
- **Geräteakte per Typenschild → DeviceCatalog** ✅ (BEJUBLAD-Beweis)
- **Barcode-Scanner:** Wareneingang vs. WorkBasket, Seriennummer, Beschläge 💡
- **Schubladen-Inhalt vs. neue Planung** 💡

## 4. AR-Anker & Gewerke
- **AR-Anker für Wasser/Strom/Abfluss** (persistent via `ARWorldMap`) 💡
- **★3-UX komplett designt:** Projekt-Kamera, „ja ab in die Drive"-Dialog, Kanon-Schublade, EXIF-Beweiskette 🔧 (wartet auf Johannes' Freigabe)
- **Gewerke-Briefe aus einer Quelle** + Termin-Abgleich 💡

## 5. Der Wächter-Blick — 12 Fälle
Barcode-vs-WorkBasket · Fahrstuhl/Lieferweg-vs-Bauteil · Gasherd-Wunsch-vs-Foto ·
Elektro-Anschluss-vs-Gerät · Sicherungskasten (⚠️ nur Vorcheck, Elektriker-Pflicht) ·
Wasseranschluss-vs-Planung · Schubladen-Inhalt-vs-Neuplanung · Lampe-vs-Klappenkollision ·
Spüler-Klappe-vs-Durchgang · Küchendreieck (Qualitäts-Unterart, Score statt Alarm) ·
Licht-Alt-vs-Neu (Kelvin) · Raumhall-vs-Materialplan · Trittschall (⚠️ echte Physik-Grenze,
nur Regel-Warnung, DIN 4109 braucht Zertifizierung)

## 6. Licht, Farbe & Rendering
- **AR-Vorschau der geplanten Küche im echten Raum** 💡 (IKEA-Place-Niveau, realistisch)
- **Echtfoto als Firefly-Leinwand** (optional leergeräumt) 💡
- **💎 Firefly-Prompt komponiert sich selbst** aus WorkBasket+ColorReader+Geräteakte+Fragebogen+Foto — Schlussstein, deckt sich mit Schiffs-eigenem C2-Plan ✅ (Konvergenz bestätigt)
- **Farbpipette** (RAL/NCS-Kandidaten) + **Lichttemperatur aus Kamera** (echte API) 🔧
- **Sonnenverlauf** (exakt berechenbar, GPS+Kompass+Datum) 🔧
- **Beleuchtungssituation** (EV-Kategorie) 🔧 · **Spiegelungen** ⚠️ (Grenze, gehört ins Rendering)
- **Licht-Planungs-Assistent:** „hier fehlt eine Leuchte" aus 4 Signalen 💡

## 7. Logistik, Zeit & Route
- **Logistik-Cluster:** Kunden-/Lieferantenkarte (Brain-gefüttert), Routen, „Zeit zum Aufbrechen" (nativ, durch Adress-Loop scharfgeschaltet), Vorabend-Regel 🔧
- **Schiff→Feld-Packlisten-Kanal** + Live-Abhaken (QR/NFC-Schwenk) 💡
- **Lieferschein-Verbucher:** Paket-Foto → Wareneingang-Ereignis, ersetzt Slack-Rauschen 💡
- **Geofence-Projektvorschlag** + Action-Button-Fingerschnipps 🔧

## 8. Team, Abnahme & Nachweis
- **Abnahmeprotokoll per Diktat** 💡 · **Kontakt-Ereignis per Diktat** (statt Telefon-Logs, die iOS sperrt) 🔧
- **Portfolio-Shot-Modus** (eigenes Einverständnis, Gyro+AR-Anker) 💡
- **Geführte Perspektiven-Sequenz** (Vorher/Nachher konsistent) 💡
- **Förderungs-Beweispaket** (KfW/BAFA) 💡
- **Front+Back-Kamera** (real, aber Delight statt Kernwerkzeug) 💡

## 9. Sensor-Zubehör — bestätigt real
DISTO D2 / Bosch GLM (Laser, BLE) · **Datacolor ColorReader** (offizielles SDK ✅) ·
**FLIR Edge Pro** (Wärmebild, offizielles SDK ✅, kabellos) · Trotec BM22WP
(Feuchte, App bestätigt, Dritt-SDK offen)

## 10. Sinnesflug — Schiffswissen × Satelliten-Sinne
Stadt-Geofence (164/169 Orte im Brain) · Lieferanten-Lexikon (22, gewichtet) ·
Transport-Wächter (G-Sensor) · Barometer-Etagen-Sinn · SOLL/IST-Blick (CAD×Kamera) ·
Aktive Raumakustik (Sweep, erster akustischer Wächter)

## 11. Ehrliche Grenzen (bewusst NICHT gebaut)
Telefon-Anruflisten (iOS-API-Mauer) · mm aus reinem Foto (Physik) ·
Wand-Durchleuchtung (Hardware fehlt) · Trittschall-Messung (DIN-Zertifizierung nötig) ·
Spiegelungen (AR-Störfaktor) · Sicherungskasten (nur Vorcheck, nie Ersatz fürs Fachpersonal) ·
Front+Back (Delight, kein Muss)

---

## Nebenbefunde der Nacht (kein Feature, aber wichtig)
- **Scope-Erweiterung:** Böden/Abhangdecken/Bäder sind eigene Leistungen — Registry
  kennt bisher fast nur „kitchen" (reine Beobachtung, keine Aktion).
- **Datenschutz-Doktrin (§14):** Opt-in, Fähigkeiten-Panel, Portfolio≠Dokumentation
  als eigene Einverständnis-Ebene.
