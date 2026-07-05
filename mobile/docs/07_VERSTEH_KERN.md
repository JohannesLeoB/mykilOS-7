# Der Versteh-Kern — Entity-Auflösung des Satelliten

**Der mittlere Takt (Fang → VERSTEH → Verräum), spezifiziert aus den Live-Beweisen ①+②.**
Grundgesetz: **Nie raten. Entweder eindeutig — oder Kandidaten-Karte.**

## Auflösungs-Kaskade (in dieser Reihenfolge, erste Stufe gewinnt)

1. **Projektnummer im Text** — Muster `20JJ-NNN` (tolerant: `2026-16` → `2026-016`).
   Exakter Registry-Match → eindeutig. Stärkste Währung.
2. **Exakter Kundenname** aus der Registry (case-insensitiv, ganzes Wort).
   Genau 1 Projekt zum Kunden → eindeutig. Mehrere (z. B. HS-Architekten hat 2!)
   → Kandidaten-Karte.
3. **Fuzzy-Kandidaten** (Teilstring/Tippfehler-Nähe) → **immer** Kandidaten-Karte,
   maximal 3, nie stillschweigend wählen.
4. **Kein Match** → nachfragen. Der Satellit stellt lieber eine kurze Frage, als
   einen Moment falsch zu verräumen.

## Homonym-Schutzregeln (aus Live-Beweis ① erzwungen)

- **Personen sind keine Kunden:** `mschmidt@cosentino.com` matcht NIE das Projekt
  „Schmidt". E-Mail-Absender/-Domains werden gegen Lieferanten-/Personenkontext
  geprüft, bevor sie als Projektbezug gelten.
- **Betreff-Tags sind keine Wahrheit:** Kommission „#Schmid" war real ein Tippfehler
  für #Schneider. Betreff-Anker sind Stufe-3-Kandidaten, nie Stufe-1-Beweise.
- **Quellen-Hierarchie:** explizite IDs (driveFolderID, clickUpListID, Record-ID)
  > Registry-Graph > Freitext-Anker. Immer.

## Drive-Realitäts-Regeln (aus Live-Beweis ② erzwungen)

- Kanon `01 INFOS / 02 CAD / 03 PRÄSENTATION` (+ 01–09 unter INFOS) = **Heuristik**:
  junge Projekte ggf. unprovisioniert (nur lose Ordner), alte mit Alt-Schema-Resten
  (`HH_`/`B_`-Präfixe). Abweichung wird angezeigt, nicht verschwiegen.
- `modifiedTime` der Ordner = **Aktivitätssignal** („was ist heiß") — gratis.

## Ausgabeformen des Versteh-Schritts

- **Eindeutig** → direkt verräumen (bzw. Karte→Bestätigung bei jedem Write).
- **Mehrdeutig** → Kandidaten-Karte: „Meinst du 2026-021 oder 2026-026 (beide
  HS-Architekten)?" — ein Tipp entscheidet.
- **Unbekannt** → eine kurze Rückfrage.


## Der Wächter-Blick — Erkennen GEGEN eine Erwartung (ab 04.07.)

Ein wiederkehrendes Muster in der Nachtsalve: nicht bloß erkennen, sondern
**A (Foto/Messung) gegen B (Plan/Wunsch/Bestellung/Kapazität) prüfen** und NUR
bei Abweichung sprechen. Stiller Wächter, kein Dauer-Kommentator.

**Fälle dieser Nacht, die dem Muster folgen:**
- Barcode-Schwenk **gegen** WorkBasket → „fehlt: Spüle"
- Fahrstuhl-/Lieferweg-Maß **gegen** WorkBasket-Bauteil-Dimension → „Steinplatte
  passt/passt nicht in den Aufzug"
- Fragebogen-Wunsch „Gasherd" **gegen** Baustellenfoto → „kein Gasanschluss
  erkennbar — bitte vor Ort klären!"
- Elektro-Steckdosentyp **gegen** Gerätebedarf (Induktion braucht oft Drehstrom)
  → Vorab-Warnung, ersetzt NIE den Elektriker
- Sicherungskasten-Belegung **gegen** geplante Zusatzlast → **NUR Vorcheck**,
  erzeugt eine Fragenliste FÜR den Elektriker (VDE-Relevanz, Haftungsgrenze —
  hier gilt dieselbe Präzisions-Ehrlichkeit wie bei den Toleranzstufen)
- Wasseranschluss-Position/-Typ **gegen** Spülen-/Geschirrspüler-Planung
- **Schubladen-Inhalt (Bestand) gegen neue Planung:** was der Kunde tatsächlich
  besitzt, gegen den Stauraum des neuen Entwurfs — deckt auf, wenn die schöne
  Planung am echten Krimskrams vorbeigeplant ist. Eigener Beratungsmoment.
- **Lampe gegen Klappen-Schwenkradius:** AR projiziert den geplanten Öffnungs-
  bogen einer Lift-/Schwenktür (aus CAD-Maßen) in den echten Raum, gegen die
  fotografierte/bestehende Leuchtenposition — Kollision VOR der Montage sehen,
  nicht danach. Klassiker bei Hängeleuchten über Kochinseln.
- **Geschirrspüler-Klappe gegen Durchgangsbreite:** offene Tür + Schwenkraum
  gegen nötige Gehwegbreite (Ergonomie-Richtwert) — Alarm, wenn der Durchgang
  bei geöffneter Klappe zu eng wird. Häufig in schmalen/Galley-Küchen.
- **Trittschall (Fussboden zwischen Stockwerken):** ECHTE PHYSIK-GRENZE, nicht loesbar per Handy-Sensor - Norm-Messung braucht Hammerwerk nach DIN 4109. Machbar nur als REGEL-Waechter (nicht Messung): Bodenaufbau-Foto + Regel (z.B. Fliese direkt auf Estrich + bewohntes Geschoss drunter) -> Warnung 'Trittschall-Risiko, Fachplaner pruefen', nie ein Messwert vorgetaeuscht.
- **Raumhall-Waechter empfiehlt Abhangdecke:** schliesst den Kreis zur eigenen Leistung - warnt vor Hall UND verweist auf das hauseigene Akustikdecken-Angebot.
- **💎 Erster AKUSTISCHER Fall — Raumhall gegen Material-Plan:** aktive Messung
  (Lautsprecher-Sweep + Mikro-Antwort → Nachhallzeit-Kategorie) gegen geplante
  harte Oberflächen (Fliese/Stein/Glas) → „wird hallig, Akustikpaneele einplanen?"
  Schätzkategorie, kein kalibriertes Messmikro — gleiche Ehrlichkeit wie Lux.
- **Bestandsbeleuchtung (Kelvin) gegen geplante neue Leuchten:** jedes Foto
  trägt seine Farbtemperatur (Kamera-Weißabgleich, `AVCaptureDevice`-API, kein
  Extra-Sensor) — warnt bei Lichtbruch Alt/Neu, macht Farbmuster-Fotos ehrlich
  vergleichbar (Holz sieht unter 2700K anders aus als unter 4000K).
- **Küchendreieck (Herd–Spüle–Kühlschrank) gegen Ergonomie-Richtwert:**
  KEIN Kollisions-Alarm, sondern ein **Qualitäts-Wächter** — Summe der drei
  Laufwege gegen den ergonomischen Zielkorridor, als Score/Ampel statt ja/nein.
  Erste eigene Unterart des Musters: Kollision (hart) vs. Qualität (graduell).

**AR-Fundament für alle drei:** nicht Live-Scan-Zauberei, sondern die geplante
Küche (aus CAD) als verankerte 3D-Vorschau im echten Raum (Tap auf Raumecke,
`ARWorldMap` hält den Anker) — **der Kunde läuft durch seine künftige Küche,
bevor sie gebaut ist.** Die Wächter-Checks (Klappe/Dreieck/Lampe) laufen GEGEN
diese Vorschau, nicht gegen Live-Rätselraten. Technische Grenze: saubere
Verdeckung nur mit LiDAR; Grundfunktion (Anker+Maße+Overlay) läuft auf jedem
neueren iPhone.

## Der Planungs-Assistent — neue Familie neben dem Waechter (ab 04.07.)

Waechter warnt GEGEN eine Erwartung (Abweichung). Der Planungs-Assistent ist
das Gegenstueck: er SYNTHETISIERT mehrere Signale zu einer POSITIVEN Empfehlung,
ohne dass etwas "falsch" ist.

**Erster Fall - Licht-Planungs-Assistent:** Helligkeitskarte aus dem Rundgang-Foto
(CoreImage-Histogramm, welche Ecken dunkel sind) + Kelvin/EV-Kategorie (wie das
Licht ist) + exakter Sonnenverlauf (bekommt die Ecke je Sonne?) + Kuechendreieck-
Arbeitszone (braucht diese Stelle Arbeitslicht?) -> "Hier fehlt eine Leuchte."
Ehrlich: Design-Hinweis, keine Lichtplaner-Lux-Berechnung.

**Regel:** Der Wächter warnt, er entscheidet nie. Sicherheitsrelevante Fälle
(Elektro) bekommen IMMER den Zusatz „vom Fachbetrieb prüfen lassen" — Kandidaten-
Karte reicht hier nicht, es braucht die ausdrückliche Fachmann-Verweisung.

## Planungs-Assistent Fall 2 — Stunden-Berater (04.07. spät)

Wie der Licht-Assistent, aber auf Zeit: reale Buchungshistorie aus der
Adapter-Base/Clockodo-Leistungen → Vorhersage „ähnliche Aufgaben dauerten
zuletzt X Stunden" beim Planen/Anbieten. Zwilling der KalkulationsEngine
(Kosten), hier für Zeit. Reine Historie-Synthese, kein neuer Sensor.

## Versteh-Kaskade verstärkt: Ort + Kunde zusammen (04.07. spät)

Lehre aus dem #Schmid/Cosentino-Homonym-Fund (Live-Beweis ①): Name ALLEIN ist
schwach. Kalendertermin-Name + Standort (aus dem Adress-Loop) ZUSAMMEN als
Compound-Schlüssel macht die Kaskade robust gegen genau die Homonyme, die
uns beim ersten Live-Test hereingelegt haben.

## STERN-1 — passiver Fang: Ortsaufenthalt als Zeit-Quelle (04.07. spät)

Ergänzt das aktive Diktat ("4h CAD für Heinz") um einen passiven Zwilling:
Geofence misst Ankunft-bis-Abfahrt-Dauer beim Kunden, gegen den Kalender-
termin (Ort+Kunde-Schlüssel) abgeglichen → Vorschlagskarte "X Stunden als
Kundenzeit vorbuchen?" statt Erinnerungspflicht. Landet wie gehabt: gated
Karte → Adapter-Base "Vorgebucht". **Pflicht:** Standort-DAUER-Erfassung
(nicht nur Ping) gehört ins Fähigkeiten-Panel (§14) — sichtbar, opt-in,
1-Klick-Widerruf, nie stillschweigend im Hintergrund.
