# 24 — Rueckkanal: Feld-Bericht des Satelliten ans Schiff

**Stand:** 04.07.2026, Fusions-Hyperdrive (Phase 3).

Gegenstueck zu docs/23 (Antenne, Schiff -> Satellit). Hier: **Satellit ->
Schiff**. Der Satellit buendelt alles, was er zu einem Projekt im Feld
erfasst hat, als JSON-Datei, die der Mensch bewusst rausschickt (AirDrop an
den Mac oder Upload in den Projekt-Drive). Das Schiff liest sie in die
Projektakte ein.

**Kein stiller Schreibzugriff** - der Satellit schreibt nichts direkt ins
Schiff. Er erzeugt eine Datei, der Mensch teilt sie. Karte->Bestaetigung
auch hier.

## Wo entsteht der Bericht

App: Projekt-Kachel -> "Auftrag fuehren" -> unten "Rueckkanal" ->
"Feld-Bericht erstellen" -> "Feld-Bericht ans Schiff senden" (Share-Sheet).

## Dateiname

`Feldbericht_<projectNumber>.json`, z. B. `Feldbericht_2026-015.json`.

## Aufbau

```json
{
  "quelle": "mykilOS mobile (Satellit)",
  "projectNumber": "2026-015",
  "projectTitel": "Schmidt",
  "erstelltAm": "2026-07-04T20:35:00Z",
  "fotos": [
    {
      "dateiname": "UUID.jpg",
      "ziel": "Rohbau",
      "aufgenommenAm": "2026-07-04T10:12:00Z",
      "breitengrad": 52.51, "laengengrad": 13.40,
      "foerderrelevant": true,
      "inDrive": true
    }
  ],
  "scans":   [ { "dateiname": "UUID.usdz", "aufgenommenAm": "..." } ],
  "vertraege": [
    { "vertragsName": "Werkvertrag", "unterzeichner": "M. Schmidt",
      "unterschriebenAm": "...", "sha256": "..." }
  ],
  "anfragen": [ { "partnerName": "Bora", "geraet": "PKFI11AB", "gesendetAm": "..." } ],
  "maengel":  [ { "text": "Kratzer Front links", "erfasstAm": "..." } ]
}
```

Alle Zeitstempel ISO-8601. Alle Listen koennen leer sein.

## Was das Schiff damit tun kann

- Feld-Fotos, die schon in Drive liegen (`inDrive: true`), in der Projektakte
  verlinken; die anderen anfordern.
- Vertraege mit ihrem SHA-256-Siegel als Beweiskette ablegen.
- Service-Anfragen und Maengel in die Nachbetreuungs-Liste des Projekts
  uebernehmen.
- Raumscans (USDZ) anfordern/verknuepfen.

## Naechster Ausbau (spaeter)

- Automatischer Upload des Berichts in einen festen Drive-Unterordner je
  Projekt (statt manuellem Share) - derselbe drive.file-Kanal wie beim
  Feld-Foto-Upload.
- Zwei-Wege-Abgleich (Schiff bestaetigt Empfang zurueck ueber die Antenne).
