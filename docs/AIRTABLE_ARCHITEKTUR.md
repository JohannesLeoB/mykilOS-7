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

## 4. Kern-Schema-Entwurf (neue „Core"-Base, greenfield)

Zwei sauber definierte Kern-Tabellen (Auszug — Felder als Vorschlag):

### `Kunden` (Primärschlüssel: `Kundennummer`)
`Kundennummer` (Text, UNIQUE) · `Nachname` · `Vorname` · `Firma` · `E-Mail 1/2` · `Telefon 1/2` · **`Adresse Straße` · `PLZ` · `Ort` · `Land`** · `Clockodo-Kunden-ID` · `sevDesk-Kontakt-ID` · `ClickUp-Lead-ID` · `Quelle` · `Projekte` (Link) · `Notizen`

### `Projekte` (Primärschlüssel: `Projektnummer`)
`Projektnummer` (Text, UNIQUE, Format `JJJJ-NNN`) · `Titel` · `Kunde` (Link → Kunden) · `Art` · `Phase/Status` · **`Projektadresse Straße/PLZ/Ort`** · `Drive-Ordner-ID` · `ClickUp-Liste` · `sevdesk-Ref` · `Budget` · `Eltern-Projekt` (Link) · Finanz-Status (Anzahlung/Abschlag/Schluss) · `Positionen` (Link)

> **Kern-Entscheidung (§8):** Wird diese Core-Base *neu* angelegt — oder wird Daniels Artikel-Base zum offiziellen Master erklärt und Mastermind darauf reduziert? Beides ist tragfähig; die Wahl bestimmt die Migrationsrichtung.

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

## 6. Migrationsplan (Strangler — nie Big-Bang)

1. **Ziel-Modell fixieren** (dieses Dokument + Johannes/Daniel-Freigabe).
2. **Greenfield Core-Base anlegen** (leer, reiner `create`, null Risiko).
3. **Business-Keys überall nachziehen** (`Projektnummer`/`Kundennummer` als Textfeld in Daniels Base + Mastermind) — der eine hochwertige Vorab-Fix.
4. **Kontrollierter Sync/Backfill** in den Core; App liest testweise dagegen; Alt-Mastermind bleibt Wahrheit bis grün.
5. **Entität für Entität umschalten** (erst Kunden, dann Projekte, dann Artikel) — jeder Schritt einzeln, reversibel, 3-Kopien-Backup als Netz.
6. **Alt-Tabellen stilllegen** (Status/Archiv-Feld, **nie löschen**).

---

## 7. Grenzen / NO-GOs

- **Daniels Artikel-Base wird nicht umgeschrieben.** Reiche Daten kommen per **Airtable-Sync** (read-only Spiegel) in den Core — er behält Hoheit, seine Make.com-Automationen bleiben unberührt.
- **Kein Big-Bang-Cut-over.** Immer entität-für-entität, reversibel.
- **Airtable-Records nie löschen** — Inaktivierung nur per Status/Archiv-Feld.
- **TABU-Base `appkPzoEiI5eSMkNK` niemals anfassen.**
- **Kern-Umbau von Kunde/Projekt ist keine mykilOS-Solo-Entscheidung** — Daniel muss am Tisch sein.

---

## 8. Offene Entscheidungen (Johannes / Daniel)

1. **Master für Kunde/Projekt:** neue Greenfield-Core-Base — ODER Daniels Artikel-Base offiziell zum Master erklären und Mastermind darauf reduzieren?
2. **Sync-Richtung & -Mechanik:** Airtable-native Sync (read-only Spiegel) vs. App-getriebener Sync über die Keys.
3. **Wer trägt die Business-Keys zuerst nach** (`Projektnummer`/`Kundennummer` in Daniels Base) — und wann?
4. **Adapter-Konsolidierung:** bleiben alle 6 Adapter-Bases getrennt (empfohlen) oder werden selten genutzte zusammengelegt?
5. **Zeitpunkt:** vor oder nach dem 8.0-Merge? (Empfehlung: **nach** 8.0 — erst die laufende App abnehmen, dann die Airtable-Konsolidierung als eigener, ruhiger Strang.)
