# 23 — Mothership-Antenne: Format-Vertrag fuer projekte.json

**Stand:** 04.07.2026, Power-Session (Etappe 2).

Der Satellit kann jetzt drei Projekt-Felder anzeigen, die er selbst nicht
erhebt — sie kommen aus dem **Registry-Schnappschuss** (`projekte.json`),
sobald die Mothership sie dort hineinschreibt. Dieses Dokument ist der
**Vertrag**: welche Schluessel der Satellit liest. Der Satellit fasst das
Schiff nicht an — das Schiff exportiert in dieses Format, der Satellit
liest es.

## Grundregel

Alle neuen Felder sind **optional und additiv**. Ein Schnappschuss ohne
diese Schluessel laeuft unveraendert weiter (der Decoder liest fehlende
Schluessel als `nil`). Das Schiff kann also Projekt fuer Projekt nachziehen,
nichts muss auf einen Schlag fertig sein.

## Bestehende Pflichtfelder (unveraendert)

```json
{
  "projectNumber": "2026-015",
  "title": "Schmidt",
  "kind": "kitchen",
  "customerNumber": "K-001",
  "driveFolderID": "1Q-H_..."
}
```

## Neue optionale Felder (die Antenne)

| Schluessel | Typ | Beispiel | Zeigt sich im Info-Modus als |
|---|---|---|---|
| `art` | String | `"Kueche + Licht"` | Klartext-Art (sonst aus `kind` abgeleitet) |
| `volumen` | Zahl (EUR netto) | `42500` | "Volumen: 42.500 EUR" |
| `letztesAngebot` | String (fertiger Text) | `"AB-2026-015 vom 12.06. - 42.500 EUR"` | "Letztes Angebot: ..." |
| `warenkorb` | Liste von Positionen | siehe unten | Klickbare Geraeteliste |

### Warenkorb-Position

```json
"warenkorb": [
  {
    "name": "Bora Professional 3.0 Kochfeldabzug",
    "artikelnummer": "PKFI11AB",
    "menge": 1,
    "einzelpreis": 2890,
    "kategorie": "Kochen"
  },
  {
    "name": "Miele G 7310 SCi Geschirrspueler",
    "artikelnummer": "G7310SCI",
    "menge": 1,
    "einzelpreis": 1499,
    "kategorie": "Spuelen"
  }
]
```

Nur `name` ist Pflicht; `artikelnummer`, `menge`, `einzelpreis`,
`kategorie` sind optional.

## Vollstaendiges Beispiel

```json
{
  "projectNumber": "2026-015",
  "title": "Schmidt",
  "kind": "kitchen",
  "customerNumber": "K-001",
  "driveFolderID": "1Q-H_...",
  "art": "Kueche + Licht",
  "volumen": 42500,
  "letztesAngebot": "AB-2026-015 vom 12.06. - 42.500 EUR",
  "warenkorb": [
    { "name": "Bora Professional 3.0", "artikelnummer": "PKFI11AB", "menge": 1, "einzelpreis": 2890, "kategorie": "Kochen" }
  ]
}
```

## Was der Satellit damit tut

1. **Projekt-Info-Modus** (Kachel antippen): zeigt Volumen, letztes
   Angebot und die klickbare Warenkorb-Liste. Ohne diese Felder bleibt der
   ehrliche "Kommt vom Mothership"-Platzhalter stehen.
2. **Kreativ-Studio**: der Firefly-Prompt kann die Geraetenamen aus dem
   Warenkorb mit einem Tipp als "Elemente" uebernehmen — der #47-Schlussstein,
   sobald die echten Zutaten fliessen.

## Ausblick (spaeter, gleicher Vertrag)

- **Material-Moodboard-Katalog** (Johannes plant ihn im Schiff): koennte als
  weiteres optionales Feld `materialien` in denselben Schnappschuss —
  dann fuellt sich auch "Material/Farbe" im Firefly-Prompt automatisch.
- **ColorReader-Farben**: kommen vom Geraet (BLE), nicht vom Schiff —
  eigener Kanal, fliessen aber in denselben Prompt.
