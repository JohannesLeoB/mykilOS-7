# MYKILOS · ClickUp-Setup (Bauplan)

*Komplettes ClickUp-Setup, abgeleitet aus der Slack-/Kontakt-Analyse. Ein Space, vier Ordner entlang der vier real gefundenen Lebenszyklen. Befüllbar am Tag 1 mit dem echten Bestand. Stand 29.06.2026.*

## Prinzip

Ein Projekt ist ein **Task**. Die **Statuses** sind die Phasen – so sieht man im Board-View das ganze Portfolio und wo jedes Projekt klemmt. Die **Subtasks/Checkliste** sind die konkreten Routine-Schritte (aus dem Template je Typ). **Standort ist ein Feld, keine Struktur** – das spart doppelte Hierarchie und entspricht der mykilOS-Logik (Ort = Token, nicht Kopie). Gewonnene Angebote wandern von Ordner ① nach ② – genau wie der Channel in Slack von `a_` zu `p_` umbenannt wird.

## 1 · Hierarchie

| Ordner | Liste | Zweck | Status-Modell |
|---|---|---|---|
| ① Angebote (Pipeline) | Pipeline | Vorvertrieb / Funnel | Neu → Angebot → Gewonnen/Verloren |
| ② Aktive Projekte | Projekte | gewonnene Aufträge in Umsetzung | 11-Phasen-Lifecycle |
| ③ Service & Reklamation | Servicefälle | reaktive Vorgänge nach Abschluss | Neu → Behoben |
| ④ Intern & Entwicklung | Vorhaben | Showroom, Serienküche, Produktentw. | Backlog → Fertig |

## 2 · Custom Fields

| Feld | Typ | Optionen / Format | Warum |
|---|---|---|---|
| Ort | Dropdown | Hamburg, Berlin, Flensburg, Lübeck, Bremen, Übrige | Standort statt eigener Space – eine Eigenschaft, keine Struktur |
| Projekttyp | Dropdown | Vollprojekt, Standard/klein, Gewerbe/B2B, Produkt/Gerät, Service, Intern | steuert, welches Template/Checkliste gilt |
| Lead | People/Dropdown | Daniel, Jasper, Jilliana, Sam, Sebastian, Philipp, Frauke | Projektverantwortliche/r (= Channel-Kürzel) |
| Kunde | Relationship → Kontakte | — | Verknüpfung zum Kontakt aus der Analyse-Brücke |
| Kunde-Token | Text | z. B. amoulong, fuckner_huetter | JOIN-KEY zu Slack/Drive/Airtable/mykilOS |
| Budget (€) | Currency | EUR | höchster bekannter Auftrags-/Angebotswert |
| Lieferanten | Labels (multi) | Weichsel78, Bartels, Meylahn, HKT, Jandali, Horatec, Pelle, Gaggenau, Miele, V-ZUG, BORA, Dornbracht, Vola, Gessi, Quooker | beteiligte Gewerke/Marken |
| Angebotsdatum | Date | — | Start der Entscheidungs-Uhr |
| Auftragsdatum | Date | — | Start der Beschaffungs-Uhr |
| Nächstes Nachfassen | Date | — | treibt die Nachfass-Routine |
| Risiko/Engpass | Dropdown | —, Kundenentscheidung, Lieferanten-Verzug, Scope/Nachtrag, Mängel offen | macht die vier bekannten Engpässe sichtbar |
| Slack-Channel | Text/URL | — | Rückbezug auf den historischen Port |
| Drive-Ordner | URL | — | Projektordner (sobald Drive verdrahtet) |

## 3 · Status-Pipelines je Ordner

**① Angebote (Pipeline)**  
`Neu → Qualifiziert → Aufmaß → Planung/Entwurf → Angebot raus → Nachfassen → ✅ Gewonnen → ❌ Verloren`

**② Aktive Projekte (11-Phasen)**  
`Auftrag/Freigabe → Bestellung → Produktion → Lieferung → Montage → Abnahme/Übergabe → Rechnung/Zahlung → Abgeschlossen`

**③ Service & Reklamation**  
`Neu → Diagnose → Verursacher klären → Teil/Nacharbeit → Termin → Behoben → Abgeschlossen`

**④ Intern & Entwicklung**  
`Backlog → In Arbeit → Review → Fertig`

## 4 · Templates (Task-Templates mit Checkliste)

Pro Projekttyp ein Template; beim Anlegen wird die passende Checkliste automatisch gesetzt.

### Vollprojekt (Privatküche)
*Standard-Lead: Daniel/Jasper/Jilliana/Sam · Feld Projekttyp = Vollprojekt*

- [ ] Fragebogen verschickt + Kontakt angelegt
- [ ] Aufmaß-Termin vereinbart
- [ ] Aufmaß + Fotos in Drive
- [ ] CAD / Visualisierung / Moodboard
- [ ] Angebots-PDF erstellt + versandt
- [ ] Angebotsdatum gesetzt
- [ ] Auftragsbestätigung unterschrieben
- [ ] Anzahlungsrechnung raus
- [ ] Bestellung Tischlerei (Weichsel78)
- [ ] Bestellung Geräte + Armaturen
- [ ] Liefertermin bestätigt
- [ ] Montagetermin geplant
- [ ] Montage durchgeführt
- [ ] Abnahmeprotokoll + Mängelliste
- [ ] Schlussrechnung gestellt
- [ ] Zahlungseingang geprüft

### Angebot / Pitch
*Standard-Lead: Lead · Feld Projekttyp = Angebot*

- [ ] Anfrage qualifiziert (Budget/Ernsthaftigkeit)
- [ ] Aufmaß nur bei echtem Interesse
- [ ] Erstentwurf / Konzept
- [ ] Angebot erstellt + versandt
- [ ] Nächstes Nachfassen gesetzt (+10 T)
- [ ] Nachgefasst (Anruf/Mail)
- [ ] Entscheidung: Gewonnen → nach ② / Verloren → Grund dokumentiert

### Gewerbe / Großprojekt (B2B)
*Standard-Lead: Johannes/Daniel · Feld Projekttyp = Gewerbe/B2B*

- [ ] Briefing + Anforderungen erfasst
- [ ] Ortstermin mit Stakeholdern
- [ ] Entwurf + Varianten
- [ ] Angebot + Vertrag/Zahlungsplan
- [ ] Freigabe Gremium/GF
- [ ] Anzahlung
- [ ] Beschaffung (ggf. in Tranchen)
- [ ] Gestaffelte Lieferung/Montage nach Bauphase
- [ ] Teilabnahmen
- [ ] Abschlags- + Schlussrechnungen

### Service / Reklamation
*Standard-Lead: Service-Verantwortliche/r · Feld Projekttyp = Service*

- [ ] Mangel/Defekt erfasst + Ursprungsprojekt verknüpft
- [ ] Fotodoku + Diagnose
- [ ] Verursacher geklärt (eigen vs. Hersteller)
- [ ] Ersatzteil/Nacharbeit bestellt
- [ ] Servicetermin vereinbart
- [ ] Behebung vor Ort
- [ ] Abschluss (ggf. Berechnung/Kulanz)

### Produkt / Gerät (Kleinauftrag)
*Standard-Lead: Verkauf · Feld Projekttyp = Produkt/Gerät*

- [ ] Anfrage erfasst
- [ ] Preis/Verfügbarkeit bestätigt
- [ ] Bestellung beim Hersteller
- [ ] Lieferung/Abholung
- [ ] Rechnung gestellt

### Intern / Entwicklung
*Standard-Lead: Team · Feld Projekttyp = Intern*

- [ ] Konzept/Zielbild
- [ ] Planung + Budget intern
- [ ] Umsetzung/Bau
- [ ] Fertigstellung + Doku

## 5 · Routinen / Automationen

Diese Automationen lassen die Routine von selbst laufen und zielen auf die vier gemessenen Engpässe.

| Automation | Auslöser | Aktion | Wirkung |
|---|---|---|---|
| A1 · Lead & Nachfass beim Anlegen | Neuer Task in ① Pipeline | Lead aus Feld zuweisen + ›Nächstes Nachfassen‹ auf +10 T | Lead-Zuordnung wie Channel-Suffix |
| A2 · Entscheidungs-Engpass | Status ›Angebot raus‹ seit 14 T unverändert | Kommentar + Benachrichtigung an Lead: nachfassen | greift den ~27-T-Entscheidungs-Engpass an |
| A3 · Sofort beschaffen | Status → ›✅ Gewonnen‹ | Task nach ② verschieben, Vollprojekt-Checkliste anwenden, Einkauf benachrichtigen | greift den ~40-T-Beschaffungs-Vorlauf an |
| A4 · Abnahme vorbereiten | Status → ›Montage‹ | Checkpunkte ›Abnahmeprotokoll‹ + ›Mängelliste‹ erzeugen, Subtask ›Abnahmetermin‹ | greift den ~44-T-Mängel-Auslauf an |
| A5 · Schlussrechnung | Status → ›Abnahme/Übergabe‹ | Task ›Schlussrechnung‹ für Frauke/Accounting, fällig +7 T | schließt die Zahlungslücke |
| A6 · Großauftrag priorisieren | Budget > 50.000 € | Priorität = Dringend setzen | Fokus auf Wertprojekte |
| A7 · Nachfass-Fälligkeit | ›Nächstes Nachfassen‹ erreicht | Benachrichtigung an Lead | kein Lead versandet |
| A8 · Service-SLA | Status ›Teil/Nacharbeit‹ seit 7 T | Benachrichtigung an Service | Reklamationen nicht liegen lassen |

## 6 · Views & Dashboard

| View | Typ | Zweck |
|---|---|---|
| Pipeline (①) | Board nach Status | der Vertriebs-Funnel |
| Portfolio (②) | Board nach Status | alle aktiven Projekte auf einen Blick – wo steckt was |
| Nach Lead | Board/Liste gruppiert nach Lead | Auslastung je Person |
| Engpässe | gefiltert: Angebot >14 T ODER Risiko gesetzt ODER Nachfassen überfällig | die Problemzonen |
| Kalender | Calendar über Liefer-/Montage-/Nachfass-Daten | Termine |
| Tabelle | alle Felder | Export / mykilOS-Sync |

Dashboard-Karten: Projekte je Phase (Anzahl) · Pipeline-Wert (Σ Budget in ①) · Auftragswert aktiv (Σ Budget in ②) · Konversion Angebot → Auftrag · Ø Verweildauer je Phase · Überfällige Nachfass-Termine · Offene Service-/Reklamationsfälle.

## 7 · Befüllung am Tag 1

Statt leer zu starten, wird das Setup mit dem realen Bestand aus der Analyse befüllt – **169 Tasks**, je Projekt vorbefüllt mit Kunde, Ort, Lead, Budget, Kunde-Token, Slack-Channel und gesetztem Status (= zuletzt erkannte Phase):

| Ziel-Ordner | Tasks |
|---|---|
| ① Angebote | 73 |
| ② Aktive Projekte | 92 |
| ③ Service & Reklamation | 0 |
| ④ Intern & Entwicklung | 4 |

Die vollständige Seed-Liste (alle Felder pro Task) liegt in `mykilos_clickup_build.json` → `seed_tasks`.

## 8 · Umsetzung – was ich baue, was du klickst

Ehrlich zur ClickUp-API: Spaces, Custom Statuses, Custom-Field-*Definitionen*, Automationen, gespeicherte Templates und Dashboards lassen sich **nicht** über den Connector anlegen – das ist einmalig UI. Ordner, Listen, Tasks (inkl. Status, Assignee, Termine, Priorität) und Docs baue ich **direkt**.

Reihenfolge:
1. **Du (UI, ~30–40 min):** Space anlegen, die 4 Status-Sets, die 13 Custom Fields, die 6 Task-Templates, die 8 Automationen, das Dashboard. Exakte Klick-Rezepte liefere ich.
2. **Ich (Connector):** die 4 Ordner + Listen anlegen und alle **169 Projekte** als Tasks einspielen – vorbefüllt und auf der richtigen Phase. Plus ein ClickUp-Doc mit diesem Bauplan und den Routinen.

So steht das System nicht nur – es bildet ab Minute eins den echten Studio-Stand ab.