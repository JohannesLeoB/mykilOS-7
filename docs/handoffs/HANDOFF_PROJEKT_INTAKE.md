# HANDOFF — Küchen-Projekt-Aufnahme (Fragebogen → Kunde + Projekt + Erst-Warenkorb)

```
Quelle:  MYKILOS_Fragebogen_EN.pdf + DE_Fragebogen_AffinityPublisher.pdf (Druckdaten, 2-seitig).
Zweck:   Johannes füllt den Bogen im Erstgespräch beim Kunden aus → daraus leitet mykilOS ab:
         (1) Kundendaten, (2) Kundenprojekt mit Ordner-Schema, (3) Erst-Warenkorb für die Preisschätzung.
Status:  Geplant (Feature B aus HANDOFF_PLANNED_FEATURES). NOCH NICHT gebaut.
Regeln:  AGENTS.md gilt. Airtable gated, append-only, nie Delete.
```

## A. Der Fragebogen — geordnete Struktur (24 Sektionen + Kopf)

**Kopf / Kontakt (→ Kundendaten):** Name · Vorname · Tel. · E-Mail · Angebotsadresse · Projektadresse ·
Datum · Unterschrift · Datenschutz-Zustimmung · „Wie haben Sie von uns erfahren?" (Quelle).

**Rahmen:**
- **Raumgröße:** bis 10 m² · 10–15 m² · 20–30 m² · größer 30 m². · Personenzahl / wer kocht am häufigsten.
- **Budget (inkl. MwSt.):** 25–35k · 35–45k · 45–55k · 55–75k · über 75k €.
- **1. Termine:** frühestmöglicher Aufmaßtermin · angestrebter Fertigstellungstermin (Produktionszeit ~6–8 Wochen; Bau-/Boden-/Sanitärarbeiten vorab abgeschlossen).

**Konfiguration (Mehrfachauswahl je Sektion):**
- **2. Gewünschte Möbelkörper:** Zeile · Oberschrank · Hochschrank · Kücheninsel · L-Form · U-Form · Barsetzen · offene Regale · offenes Weinlager.
- **3. Gewünschte Schränke:** Apothekerschrank · Putzschrank · Karussell-/Eckschrank · Auszug/Tür · Aufsatz · Mülltrennsystem.
- **4. Benötigte Geräte** *(Geräte-Gruppe → Artikel-Auswahl + Freitext, s. C):* Kühlgeräte (Kühl-Gefrierkombi · Side-by-Side · Unterbau-Kühlschrank · Weinkühlschrank · Gefrierschrank · Eiswürfel) · Ofen (Backofen · Dampfgarer · Mikrowelle · Ofen-Kombinationen · Vakuumierschublade · Wärmeschublade) · Kaffeevollautomat · Geschirrspüler (voll/kompakt) · Waschmaschine/Trockner/Kombi.
- **5. Art des Kochfeldes:** Induktion · Flex-Induktion · Flächeninduktion (autom. Topferkennung) · Gas · Teppan Yaki · Wok-Induktion · eingelassene Friteuse · Brätzone · klassische Heizspirale Ceran.
- **6. Dunstabzug:** Wand-/Deckenlüftung (Gaggenau/Bora/Miele/V-Zug) · Muldenlüftung (ausfahrbar) · Umluft vs. Abluft.
- **7. Material Korpus:** Spanplatte · Tischlerplatte · uni · Kante (furniert/ABS/Echtholz).
- **8. Material Fronten:** furniert Holz · Schichtstoff (HPL/PerfectSense) · lackiert · Metall (Messing/Edelstahl) · Linoleum.
- **9. Bedienung Fronten:** Push-to-open · mit Griffen · Griffmulde/Eingriff · grifflos (kombinierbar). **+ Geräteklasse:** € (Bosch/Neff/AEG) · €€ (Miele/Liebherr) · €€€ (Gaggenau/V-Zug/Wolf) — *steuert die Kalkulation/Erst-Warenkorb.*
- **10. Material Schubkästen:** Vollholz · Stahlwange m. Dekorboden · Legrabox.
- **11. Anzahl & Art Spülbecken:** 1/2 Becken (gleich/unterschiedlich) · Abtropffläche · gefräste Abtropfrinne.
- **12. Material Spülbecken:** Edelstahl · Mineralwerkstoff (Corian/Hi-Macs) · Email · Keramik · Quarzkomposit · wie Arbeitsplatte.
- **13. Bauart Spülbecken:** flächenbündig · nahtlos · Unterbau · Spülenunterschrank Auszug/Tür · Müllsystem.
- **14. Material Armatur:** Edelstahl · Messing · Chrom · farbig.
- **15. Art der Armatur:** Standard · Wand · Schlauchbrause · Dreiloch · Niederdruck · kochendes Wasser (Quooker/CLAGE) · vitalisiert/karbonisiert (UMH).
- **16. Zusatzoptionen Wasser:** Heizspirale · eingelassener Dampfgarer · Wok-Induktion · Kaltwasserfilter.
- **17. Material Arbeitsplatte:** Naturstein (Marmor/Schiefer/Terrazzo) · Quarzkomposit · Keramik (Neolith/Dekton) · Beton · Holz · Edelstahl · Mineralwerkstoff · Glas · diverse Metalle · Schichtstoff · Fliesen/Mosaik.
- **18. Spritzschutz/Rückwand:** Fliesen · abwischbare Wandfarbe · wie Arbeitsplatte · Aufsatzkasten · Wischleiste.
- **19. Extras:** Extratiefe Arbeitsplatte · Tritt obere Schränke · integr. Seifenspender · Teleskopauszug Ofen · Schalter/Steckdosen (Korpus/Rückwand) · Schrankinnen-/Oberschrankbeleuchtung · QI-Ladestation · Freezyboy · Einbau-Toaster/-Allesschneider · wandmontierte Ablagen (mit/ohne LED) · Schubladeneinteilung.
- **20. Zusätzliche Raumgestaltung:** Lichtplanung · Trockenbau/Durchreiche · Einbaumöbel · Fußboden · Heizkörperverkleidung · Wandgestaltung · HWR/Vorratsraum · lose Möbel.
- **21. Vorhandene Unterlagen:** vermaßter Grundriss · Skizze · Elektroplan · Sanitärplan · Fotos Bestand · Mood-Bilder.
- **22. Projektadresse-Infos:** Stockwerk · Fahrstuhl · Maße Treppenhaus (Anlieferung) · Deckenhöhe (Stuck/Hohlkehle).
- **23. Weitere Anmerkungen/Fragen/Wünsche** (Freitext).
- **24. Wie haben Sie von uns erfahren?** (Quelle/Marketing).

> Beim Bau gegen die echten PDFs verifizieren (Reihenfolge der Optionen je Sektion) — die obige Liste ist
> aus den Druckdaten rekonstruiert und vollständig genug zum Strukturieren, aber nicht jede Option garantiert
> in Originalreihenfolge.

## B. Ableitung (was woraus entsteht)

| Bogen-Teil | → mykilOS-Ergebnis |
|---|---|
| Kopf/Kontakt + Adressen + Quelle | **Kunde** (Airtable `Kunden`): Nachname/Vorname/Firma, E-Mail/Tel, Angebots-/Projektadresse, Quelle. |
| Termine · Budget · Raumgröße · Adresse-Infos · Unterlagen · Anmerkungen | **Projekt** (Airtable `Projekte`): Projektname (z. B. `JJJJ-NR_Nachname`), Budget, Status, Projektadresse, Notizen. **+ Drive-Ordner** nach dem **bestätigten Schema** (siehe §B.1). |
| Ausgefüllter Bogen als Dokument | **Fragebogen-PDF** → Drive-Ordner `01 INFOS / 07 Fragebogen` des Projekts (read-only Upload, gated). |

### B.1 Bestätigtes Drive-Projektordner-Schema (Screenshot 2026-06-30)

Pfad: **Geteilte Ablagen › MYKILOS Team › PROJEKTE › `<Projektordner>`**. Vorlage:
`_BEISPIELORDNER_JJJJ_Projektnr_Kunde_STR-Nr`. Aufbau:

```
<JJJJ_Projektnr_Kunde_STR-Nr>
├── 01 INFOS
│   ├── 01 Pläne
│   ├── 02 Fotos Bestand
│   ├── 03 Recherche | Zubehör
│   ├── 04 ausgehende Angebote
│   ├── 05 eingehende Angebote
│   ├── 06 Fotos Baustelle
│   ├── 07 Fragebogen        ← Fragebogen-PDF landet HIER
│   ├── 08 Werkszeichnung
│   └── 09 Fotos Mängel
├── 02 CAD
├── 03 PRÄSENTATION
└── MYKILOS_Abnahmeprotokoll BLANKO.pdf
```

Der Upload-Resolver findet unter der Projekt-`Drive-Ordner-ID` (Mastermind `Projekte.fldr0wVWFrGHEWSeN`)
den Unterordner `01 INFOS` → `07 Fragebogen` und legt das PDF dort ab (Unterordner bei Bedarf anlegen).
**⚠️ Braucht Drive-Schreib-Scope (`drive.file`) → Google Re-Consent durch Johannes** (Trennen→Verbinden).
| Geräte-Sektionen (4–6, 9-Geräteklasse, 15/16) | **Erst-Warenkorb** (Warenkorb → `Warenkörbe` + `Projektartikel`): je gewählter Geräte-Position eine konkrete Artikel-Auswahl (s. C) **plus** Freitext. Geräteklasse €/€€/€€€ steuert die Vorauswahl/Schätzung. |
| Material-/Ausführungs-Sektionen (7,8,10,12,13,14,17,18) | **Kalkulations-Parameter** (Ausstattungsgrad) für die Preisschätzung — Korpus/Front/Arbeitsplatten-Material treiben den Kostenboden. Fließt in `KalkulationsEngine`. |

**Ziel:** Ein ausgefüllter Bogen → 1 Kunde + 1 Projekt (mit Ordnern) + 1 Erst-Warenkorb + eine erste
Preisschätzung (Min/Mitte/Max) — alles aus EINER Maske heraus.

## C. Geräte-Gruppe → Artikel/Shop-Auswahl + Freitext

Pro Geräte-Position (z. B. „Backofen", „Kochfeld", „Dunstabzug", „Kühl-Gefrierkombi", „Armatur"):
- **Konkrete Auswahl aus der Artikel-DB** (`appdxTeT6bhSBmwx5`/`Artikel`): gefiltert nach Kategorie +
  Geräteklasse (€/€€/€€€ → Hersteller-Mapping: € Bosch/Neff/AEG, €€ Miele/Liebherr, €€€ Gaggenau/V-Zug/Wolf).
  Picker zeigt passende Artikel mit Bild/Preis; gewählter Artikel → Erst-Warenkorb-Position (voller Snapshot).
- **Immer auch Freitext** („noch offen", „Kunde bringt eigenes", Sondermodell) — Freitext-Position ohne Artikel-Link,
  trotzdem im Warenkorb sichtbar und später ersetzbar.
- Wo „Auf Lager" passt: der `AufLagerMatcher` zeigt direkt, ob ein gewähltes/ähnliches Gerät im Lager ist.

## D. Lokaler Spiegel der Artikel-DB (statt teurer Live-Loads)

Johannes' Wunsch: 13.419 Artikel nicht jedes Mal live laden (langsam, API-Last). Stattdessen **lokaler
Abbild-Cache**, der sich automatisch abgleicht.

**Empfohlene Architektur:**
- **Lokaler Snapshot** der Artikel-Tabelle in **GRDB** (`artikel_cache` in der bestehenden DB) ODER als
  JSON-Datei in Application Support. Enthält alle Felder (Artikelnummer, Hersteller, Kategorie, Beschreibung,
  EK, VK-MYKILOS, Bild-URL, Airtable-Record-ID).
- **Suche/Filter/Anzeige laufen gegen den lokalen Cache** (schnell, offline-fähig) — der Artikel/Shop-Tab und
  die Geräte-Picker im Fragebogen lesen lokal.
- **Abgleich (Refresh):** (a) manueller „Aktualisieren"-Button, (b) beim App-Start wenn Cache älter als X,
  (c) **inkrementell** über Airtable `Zuletzt geändert` (`fldd4eeutPgkyRoZ8`, lastModifiedTime) — nur Records
  laden, die neuer sind als der letzte Sync-Zeitstempel. So kommen neue/geänderte Artikel automatisch dazu,
  ohne jedes Mal alle 13.419 zu ziehen.
- **Sichtbarer Sync-Status** (wie SaveState): „zuletzt abgeglichen vor …", „N neue Artikel".
- Konsistent mit dem local-first-Prinzip von mykilOS. Cold-Start-Test fürs Cache-Schema.

> Das löst zugleich den aktuellen „Artikel/Shop lädt langsam/leer"-Schmerz: einmal cachen, dann lokal arbeiten.

## E. Intake-UI-Flow (Vorschlag)
1. „+" → **Projekt (umfangreich)** → **geführter Fragebogen** (Sektionen 1–24 als Schritte/Abschnitte,
   Mehrfachauswahl-Chips + Freitext, exakt der Bogen-Logik folgend). **Option-Illustrationen** aus
   `Archiv.zip → Linienzeichnungen_Fragen/` (Strichzeichnungen je Wahl: Armatur-Form, Schubladen-Bedienung,
   Möbelkörper, Spülbecken-Bauart, Zusatzfunktionen Wasser) als visuelle Auswahl-Kacheln → die Maske sieht
   aus wie der Papierbogen, nur klickbar. (Assets nach `Sources/MykilosApp/Resources/` legen.)
2. Während des Gesprächs ausfüllbar (Tablet/Laptop), Zwischenspeichern (lokal), nichts geht verloren.
3. Abschluss → **Bestätigung** zeigt, was angelegt wird: Kunde · Projekt (+Ordner) · Erst-Warenkorb · Schätzung.
   → gated Schreiben (Airtable CREATE, Drive-Ordner, Warenkorb append-only) + Audit.
4. Danach: Projekt-Detailseite mit Warenkorb-Widget (s. HANDOFF_PLANNED_FEATURES Feature C).

## F. Offen / braucht Johannes
- Genaues Front-/Back-Mapping der Optionen je Sektion gegen die Original-PDFs feinschleifen.
- Welche Projekt-Tabelle führt (Mastermind vs. Artikel-DB-`Projekte` mit Sevdesk-Pipeline) — für den Warenkorb→Sevdesk-Fluss die Artikel-DB.
- Drive-Ordner-Schema bestätigen (Unterordner-Namen).
- `Archiv.zip` (mitgeschickt) — Inhalt noch nicht gesichtet; bei Bedarf einordnen.
