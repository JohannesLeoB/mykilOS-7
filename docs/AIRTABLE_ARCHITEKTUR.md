# Airtable-Architektur — Ist-Landkarte & Ziel-Modell

**Status: Vorschlag v1 · 2026-07-01 · reines Planungsdokument, KEIN Live-Eingriff.**
Autor: Claude (Architektur-Partner) für Johannes. Dieses Dokument definiert die
sauberen IDs/Namen/Nummern und I/O-Übergaben **bevor** an den Live-Bases etwas
geändert wird. Es entscheidet nichts allein — die offenen Punkte (§8) gehören
Johannes (und bei Kern-Daten: Daniel).

---

## 1. Ist-Landkarte (24 Bases)

Gruppiert nach Rolle. IDs sind die echten Airtable-Base-IDs.

### Kern / Geschäft (die eigentliche Wahrheit)
| Base | ID | Rolle | Adresse? |
|---|---|---|---|
| **Artikel- & Einkaufsdatenbank** | `appdxTeT6bhSBmwx5` | **Daniels Master** — Artikel, Kunden (mit `Angebotsadresse`), Projekte (mit `Projektadresse` + Finanzen), Projektartikel, Eingangsrechnungen, Lagerliste, Warenkörbe. Live-Make.com-Automationen (sevDesk). | ✅ **hier liegt die reiche Wahrheit** |
| **mykilOS Mastermind** | `appuVMh3KDfKw4OoQ` | mykilOS-**Kontrollebene** (dünn): Kunden (nur Name/Nr), Projekte (Routing), Kontakte (mit Adresse), Clockodo-*, Kalkulationen, Eingehende-Angebote, Datenstrom-Handbuch/-Log. **Was die App liest.** | ❌ Kunde/Projekt ohne Adresse |
| mykilOS_Projekte | `appWI2qj9cc6Muu3b` | Projekt-bezogen (Detail-Schema ungeprüft) | ? |
| mykilOS_Handelswaren | `appDj4wH4WDQfziDZ` | Handelswaren-Stamm | – |
| mykilOS_Onlineshop & Verkauf | `app2XOhOxXfkLtGVC` | Shop/Verkauf | – |

### Adapter (IO-Grenzen, Feeder/Listener)
| Base | ID | Richtung |
|---|---|---|
| mykilOS-Adapter Clockodo | `appuQDCFGLmjo2L6T` | Zeitbuchungen (WRITE, aktiv) |
| mykilOS_Adapter ClickUp | `app5ab3FhXJRfNr8r` | Tasks/Routing |
| mykilOS_Adapter Slack | `appCfgxyYmoSV5elm` | Slack-Wissen |
| mykilOS_Adapter Sevdesk | `appcSjFNs1knLeM3G` | sevDesk-IO (NO-GO: nie direkt schreiben) |
| mykilOS_Adapter GoogleDrive | `apppWi3kexgOCJHvb` | Drive-Routing |
| mykilOS_Adapter Weclapp | `app10Q63PXjw9IiVc` | Weclapp-IO |

### Dokumente IN/OUT
| Base | ID |
|---|---|
| mykilOS_Angebote IN / OUT | `appI7Q1jTajUSK4K6` / `appJXkyABMenI8GQP` |
| mykilOS_Rechnungen IN / OUT | `appQ0pgTbrZdphXJ6` / `appNomkNNvvu8wCeF` |
| mykilOS_Fragebogen & Projekt IN | `appYE7GnC4bcfTBTX` | **⚠️ aktuell leer** (nur Default-„Table 1") — der Intake schreibt real in die Artikel-Base, nicht hierhin. |

### Alerts
mykilOS_Alerts News (`app6VXcxrhfiiR3AS`) · Cash (`appJqaL3OOUOsHO2E`) · Timelines (`app2R76qgh7NCNdBx`)

### Infrastruktur / Sonstige
mykilOS 8 Backup Base (`app56DTbSoqPvZhom`, Write-Shadow-Spiegel) · mykilOS_TRESOR (`appyD6BxJ5Qw9p98V`) · mykilOS_Datenweichen (`appGugtieBPgbIekk`) · mykilOS_App Entwicklung (`appfPsOHxuGbQBQ6y`)

### TABU (read-only NO-GO)
mykilos Datenbank Zuliefererpreise Schätzung (`appkPzoEiI5eSMkNK`) — **niemals lesen/schreiben.**

---

## 2. Die vier Kern-Probleme

1. **Entität-Fragmentierung ohne Master.** Kunde & Projekt existieren *doppelt* — reich in der Artikel-Base, dünn in Mastermind — mit unterschiedlichem Schema. Kein „single source of truth".
2. **Kein durchgängiger Join-Key.** Airtable-Record-Links funktionieren **nur base-intern**. Basisübergreifend hilft nur ein Textschlüssel — der aber fehlt/uneinheitlich ist (Artikel-`Projekte`-Primärfeld = „Projektname", nicht Projektnummer).
3. **Zwei-Eigentümer-Problem.** Daniel besitzt die Artikel-Base *und* ihre Make.com-Automationen; mykilOS besitzt Mastermind. Kein Umbau ohne Koordination.
4. **Folge im App-Feeling:** Adresse hängt nicht am Projekt, weil die App aus der dünnen Mastermind-Kopie liest.

---

## 3. Ziel-Prinzipien

1. **Ein System-of-Record je Kern-Entität** (Kunde, Projekt, Artikel) — alle anderen referenzieren per Schlüssel, keine Teilkopien.
2. **Durchgängige Business-Keys überall:** `Kundennummer`, `Projektnummer`, `Artikelnummer` als Textfeld in JEDER Base, die die Entität berührt.
3. **Relationaler Kern (native Links) + Adapter als eigene IO-Bases.** Kern verdichten, Ränder trennen.
4. **App bleibt local-first.** Base-Struktur = Sync-Layer, kein Runtime-/App-Speed-Thema. Die App synct die *richtigen Felder* (inkl. Adresse) in ihren GRDB-Cache.
5. **Feeder/Listener via Webhook-Relay** (die bereits getroffene Push-Entscheidung).
6. **3-Kopien-Redundanz behalten:** Airtable-Snapshot + Backup-Base (WriteShadowRecorder, append-only) + lokaler GRDB.

---

## 4. Kern-Schema-Entwurf — neue Base `mykilOS_Core` (greenfield)

**Entschieden (2026-07-01):** frische, saubere Core-Base als **einziger Master, mit dem
die App spricht.** Native Record-Links innerhalb der Base machen die Beziehungsarbeit;
jede Tabelle trägt zusätzlich den **Business-Key als Textfeld** (für basisübergreifende
Übergaben). Zwei Typen von Tabellen:
- **Eigene Tabellen** (App liest+schreibt): Kunden, Projekte, Positionen, Warenkörbe.
- **Read-only Sync-Spiegel** von Daniels Base (App liest nur): Artikel, Lagerliste.

### `Kunden` — eigene Tabelle · Primär `Kundennummer`
| Feld | Typ | Zweck |
|---|---|---|
| `Kundennummer` | Text, UNIQUE | Business-Key |
| `Nachname` / `Vorname` / `Firma` | Text | Identität |
| `E-Mail 1/2` / `Telefon 1/2` | E-Mail/Tel | Kontakt |
| **`Adresse Straße` / `PLZ` / `Ort` / `Land`** | Text | **die fehlende Adresse — hier zuhause** |
| `Clockodo-Kunden-ID` | Number | Feeder → Clockodo |
| `sevDesk-Kontakt-ID` / `ClickUp-Lead-ID` | Text | Feeder-Rückweg an Daniels Pipeline |
| `Quelle` | Select | Herkunft (Intake/Import) |
| `Projekte` | Link → Projekte | Relation |
| `Status` | Select (Aktiv/Archiv) | Inaktivierung, **nie löschen** |
| `Notizen` | Long text | |

### `Projekte` — eigene Tabelle · Primär `Projektnummer`
| Feld | Typ | Zweck |
|---|---|---|
| `Projektnummer` | Text, UNIQUE, `JJJJ-NNN` | Business-Key |
| `Titel` | Text | |
| `Kunde` | Link → Kunden | Relation |
| `Kundennummer` | Text (Lookup/Copy) | Übergabe-Key |
| `Art` / `Phase` | Select | |
| **`Projektadresse Straße/PLZ/Ort`** | Text | Lieferadresse |
| `Drive-Ordner-ID` / `Drive-Ordnername` | Text | Drive-Routing |
| `ClickUp-Liste` / `ClickUp-Lead-ID` | Text | ClickUp-Routing |
| `sevdesk-Ref` / `sevDesk-Angebot-ID/Link` | Text/URL | Feeder ↔ sevDesk |
| `Budget` | Number | |
| `Eltern-Projekt` | Link (self) | Nachträge |
| `Positionen` | Link → Positionen | |
| `Finanz-Status` (Anzahlung/Abschlag/Schluss) | **read-only Spiegel** | von Daniels sevDesk-Pipeline zurückgefüttert |
| `Status` | Select (Aktiv/Archiv) | nie löschen |

### `Positionen` — eigene Tabelle (Projekt-Artikel-Zeilen)
`Projektnummer` (Text-Key) · `Projekt` (Link) · `Artikelnummer` (Text-Key → Artikel-Spiegel) · `Menge` · `Rabatt %` · `Reihenfolge` · Preise per Lookup aus `Artikel`-Spiegel.

### `Warenkörbe` — eigene Tabelle, **append-only**
`Bezeichnung` · `Projektnummer` (Key) · `Prüfsumme` · `Version` · `Status` (Aktuell/Archiviert) · `Positionen (JSON)` · `Summe EK/VK` · `Erstellt-am`.

### `Artikel` + `Lagerliste` — read-only **Airtable-Sync-Spiegel**
1:1-Sync aus Daniels Artikel-Base (~13k Preise + Lager). Kein App-Kopier-Job — Airtable
hält den Spiegel aktuell, die App liest nur. So bleiben Preise frisch ohne Pflegeaufwand.

### Bewusst NICHT in Core v1 (Scope-Grenze)
Adapter-Bases (Clockodo/ClickUp/Slack/Drive/Sevdesk/Weclapp) bleiben getrennt. Die
Mastermind-Kontroll-Tabellen (Datenstrom-Handbuch/-Log, Clockodo-Nutzer/-Leistungen,
Kalkulationen, Eingehende-Angebote) bleiben vorerst in Mastermind — ob sie später in
Core wandern oder Mastermind als „Kontroll-Base" schlank weiterlebt, ist §8-Punkt 4.

---

## 5. I/O-Übergaben (Feeder/Listener)

Jeder Adapter ist eine IO-Grenze, die **auf einem Business-Key joint** (nie auf Airtable-internen Record-IDs, die basisübergreifend nicht stabil sind):

| Adapter | Richtung | Join-Key | Trigger |
|---|---|---|---|
| Clockodo | WRITE (Zeit) | Kundennummer→customers_id, Kostenstelle→services_id | Timer-Bestätigung |
| ClickUp | R/W (Tasks) | Projektnummer ↔ Liste | Provisionierung / Sync |
| Drive | READ (Dateien) | Projektnummer ↔ Ordner-ID | Poll/Webhook |
| Sevdesk | via Make.com | Projektnummer/Kundennummer | Airtable-Checkbox (NO-GO direkt) |
| Angebote/Rechnungen IN/OUT | Dokument-Fluss | Projektnummer | Make.com |

**Prinzip:** Übergaben laufen über den stabilen Business-Key, nicht über Record-Links. So bleibt jede Base unabhängig migrierbar.

---

## 6. Migrationsplan (Strangler — nie Big-Bang, Master = frische Core-Base)

Empfohlene Sequenz: **nach 8.0-Abnahme**, als eigener ruhiger Strang.

1. **Ziel-Modell fixieren** (dieses Dokument + Johannes ✅ / Daniel für die Schreib-Übergabe).
2. **Greenfield `mykilOS_Core` anlegen** (leer, reiner `create`, null Risiko).
3. **Business-Keys nachziehen:** `Projektnummer`/`Kundennummer` als Textfeld in Daniels Base
   (braucht Daniel) — der eine hochwertige Vorab-Fix, ohne den keine saubere Übergabe geht.
4. **READ-Seite zuerst (einfach):** Artikel + Lagerliste als read-only Airtable-Sync in Core
   spiegeln; Kunden/Projekte/Warenkörbe per kontrolliertem Backfill re-mappen. App liest
   testweise gegen Core; Alt-Quellen bleiben Wahrheit bis grün.
5. **App-Umstellung Read:** `ArtikelKatalogStore`/`LagerlisteStore`/`WarenkorbListeStore`/
   `CachedBusinessRegistry` lesen Core statt Daniels Base.
6. **WRITE-Seite (die Arbeit):** Intake + Cart schreiben in Core; **Feeder-out** (Core →
   Daniels Base/sevDesk über den Business-Key) füttert seine Pipeline weiter. `Finanz-Status`
   kommt read-only zurück. `appdxTeT6bhSBmwx5` fällt aus `writableMap`.
7. **Alt-Tabellen stilllegen** (Status/Archiv-Feld, **nie löschen**).

---

## 7. Grenzen / NO-GOs

- **Daniels Artikel-Base wird nicht umgeschrieben.** Reiche Daten kommen per **Airtable-Sync** (read-only Spiegel) in den Core — er behält Hoheit, seine Make.com-Automationen bleiben unberührt.
- **Kein Big-Bang-Cut-over.** Immer entität-für-entität, reversibel.
- **Airtable-Records nie löschen** — Inaktivierung nur per Status/Archiv-Feld.
- **TABU-Base `appkPzoEiI5eSMkNK` niemals anfassen.**
- **Kern-Umbau von Kunde/Projekt ist keine mykilOS-Solo-Entscheidung** — Daniel muss am Tisch sein.

---

## 8b. ENTSCHEIDUNG 2026-07-01 (Johannes): App komplett von Daniels Base entkoppeln

**Richtung fix:** Die App hängt künftig **nur an unseren eigenen Bases**. Daniels
Daten werden **gespiegelt/kopiert reingeholt und bei uns neu einsortiert/zugeordnet**
— nie direkt aus seiner Base gelesen oder in sie geschrieben. Sein Base bleibt sein
Hoheitsgebiet (mit seinen Make.com-Automationen), wir werden robust dagegen: strukturiert
er um, bricht unsere App nicht.

### Ist-Kopplung (was heute an `appdxTeT6bhSBmwx5` hängt)
| Richtung | Code | Tabelle |
|---|---|---|
| **READ** | `ArtikelKatalogStore` | Artikel (~13k Preise) |
| **READ** | `LagerlisteStore` | Lagerliste |
| **READ** | `WarenkorbListeStore` | Warenkörbe |
| **READ** | `CachedBusinessRegistry` | Geschäfts-Records (Kunde/Projekt) |
| **WRITE** | Intake (`IntakeResultBuilder`/`AppState`) | **Kunden + Projekte** |
| **WRITE** | `CartStore` | Warenkörbe + Projektartikel |

### Das asymmetrische Muster (der Knackpunkt)
Entkopplung hat zwei sehr verschiedene Hälften:

- **READ-Seite = einfach.** Daniels Artikel/Lager/Warenkörbe/Geschäfts-Records werden
  **einmal in unseren Core kopiert** (re-sortiert), die App liest ab da nur die Kopie.
  Seine Base = Upstream-Quelle, Einbahn rein. Mechanik: Airtable-Sync (read-only Spiegel)
  ODER ein App-/Make-getriebener Kopier-Job, der beim Kopieren in unser Schema mappt.

- **WRITE-Seite = die eigentliche Arbeit.** Intake schreibt Kunde/Projekt heute **genau
  deshalb** in Daniels Base, weil dort seine **sevDesk/Make-Pipeline** hängt (das „Angebot
  an sevDesk"-Häkchen liest von dort). Schreiben wir künftig in *unseren* Core, muss eine
  neue **Übergabe/Feeder** (unser Core → Daniels Base bzw. → eine geteilte „Übergabe"-
  Tabelle) dafür sorgen, dass seine Pipeline weiter gefüttert wird. **Das ist die „Übergabe
  an I/Os", die Johannes meint.**

### Sauberes Zielbild
Die App spricht **nur** mit dem Core. Daniels Base ist:
- **Upstream** (Copy-in → re-sortiert in unseren Core) für alles, was wir lesen, UND
- **Downstream** (Feeder-out aus unserem Core → seine Base/sevDesk) für alles, was seine
  Pipeline braucht.

Beide Übergaben laufen über den **stabilen Business-Key** (`Kundennummer`/`Projektnummer`),
nie über basisübergreifende Record-Links (die es in Airtable nicht gibt).

### Was das für den Code heißt (post-8.0)
- `appdxTeT6bhSBmwx5` fällt aus `AirtableClient.writableMap` (kein Direkt-Schreiben mehr).
- Intake schreibt in Core; ein Feeder überträgt an Daniels sevDesk-Pipeline.
- `ArtikelKatalogStore`/`LagerlisteStore`/`WarenkorbListeStore`/`CachedBusinessRegistry`
  lesen den Core-Spiegel statt Daniels Base.
- **Sonderfall Artikel-Katalog (~13k Preise):** volle Dauerkopie wäre pflegeintensiv/veraltet-
  anfällig. Hier ist ein read-only **Airtable-Sync-Spiegel** (statt App-Kopie) die sauberere
  Wahl — zu klären in §8.

---

## 8. Offene Entscheidungen (Johannes / Daniel)

1. ✅ **ENTSCHIEDEN (2026-07-01):** neue Greenfield-Core-Base `mykilOS_Core` als Master; App vollständig von Daniels Base entkoppelt (§8b).
2. **Sync-Richtung & -Mechanik:** Airtable-native Sync (read-only Spiegel — Favorit für Artikel/Lager) vs. App-getriebener Backfill über die Keys (für Kunden/Projekte, wg. Re-Mapping). Offen.
3. **Wer trägt die Business-Keys zuerst nach** (`Projektnummer`/`Kundennummer` in Daniels Base) — und wann?
4. **Adapter-Konsolidierung:** bleiben alle 6 Adapter-Bases getrennt (empfohlen) oder werden selten genutzte zusammengelegt?
5. **Zeitpunkt:** vor oder nach dem 8.0-Merge? (Empfehlung: **nach** 8.0 — erst die laufende App abnehmen, dann die Airtable-Konsolidierung als eigener, ruhiger Strang.)
