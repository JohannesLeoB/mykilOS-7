# mykilOS · ClickUp Aufbau-Anleitung

*Einmaliger UI-Aufbau (~30 min). Reihenfolge strikt einhalten — danach befuelle ich per Connector automatisch mit allen 169 Projekten. Hintergrund: Tasks brauchen die Status und Felder, bevor sie sauber landen.*

## Schritt 1 - Space anlegen  (1 min)
Sidebar -> **+ Create Space** -> Name exakt: `mykilOS Projekte`. Template-Wizard ueberspringen, Default-Listen loeschen.

## Schritt 2 - Vier Ordner mit eigenen Status-Sets  (10 min)
Im Space je **+ Create Folder**, dann in den Folder-Settings **Statuses -> Override space statuses** aktivieren und exakt diese Status anlegen (Reihenfolge = Pipeline):

**① Angebote**  
`Neu - Qualifiziert - Aufmaß - Planung/Entwurf - Angebot raus - Nachfassen - ✅ Gewonnen - ❌ Verloren`

**② Aktive Projekte**  
`Auftrag/Freigabe - Bestellung - Produktion - Lieferung - Montage - Abnahme/Übergabe - Rechnung/Zahlung - Abgeschlossen`

**③ Service & Reklamation**  
`Neu - Diagnose - Verursacher klären - Teil/Nacharbeit - Termin - Behoben - Abgeschlossen`

**④ Intern & Entwicklung**  
`Backlog - In Arbeit - Review - Fertig`

## Schritt 3 - Je eine Liste pro Ordner  (1 min)
(1) -> `Pipeline` , (2) -> `Projekte` , (3) -> `Servicefaelle` , (4) -> `Vorhaben`.  
*(Optional: Listen weglassen und mir Bescheid geben - die kann ich per Connector anlegen.)*

## Schritt 4 - Custom Fields  (10 min)
Space-Settings -> **Custom Fields** -> fuer jedes Feld **Create field**:

| # | Feld | Typ | Optionen / Format |
|---|---|---|---|
| 1 | Ort | Dropdown | Hamburg, Berlin, Flensburg, Lübeck, Bremen, Übrige |
| 2 | Projekttyp | Dropdown | Vollprojekt, Standard/klein, Gewerbe/B2B, Produkt/Gerät, Service, Intern |
| 3 | Lead | People/Dropdown | Daniel, Jasper, Jilliana, Sam, Sebastian, Philipp, Frauke |
| 4 | Kunde | Relationship → Kontakte | — |
| 5 | Kunde-Token | Text | z. B. amoulong, fuckner_huetter |
| 6 | Budget (€) | Currency | EUR |
| 7 | Lieferanten | Labels (multi) | Weichsel78, Bartels, Meylahn, HKT, Jandali, Horatec, Pelle, Gaggenau, Miele, V-ZUG, BORA, Dornbracht, Vola, Gessi, Quooker |
| 8 | Angebotsdatum | Date | — |
| 9 | Auftragsdatum | Date | — |
| 10 | Nächstes Nachfassen | Date | — |
| 11 | Risiko/Engpass | Dropdown | —, Kundenentscheidung, Lieferanten-Verzug, Scope/Nachtrag, Mängel offen |
| 12 | Slack-Channel | Text/URL | — |
| 13 | Drive-Ordner | URL | — |

> `Kunde-Token` bitte **exakt** so benennen - das ist der Join-Key zu Slack/Drive/Airtable/mykilOS.

## Schritt 5 - Task-Templates  (5 min)
Je einen Beispiel-Task anlegen -> Checkliste einfuegen (Checklist -> add items) -> **... -> Templates -> Save as Template**. Checklisten:

### Vollprojekt (Privatküche)  -  Lead: Daniel/Jasper/Jilliana/Sam  -  Projekttyp = Vollprojekt
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

### Angebot / Pitch  -  Lead: Lead  -  Projekttyp = Angebot
- [ ] Anfrage qualifiziert (Budget/Ernsthaftigkeit)
- [ ] Aufmaß nur bei echtem Interesse
- [ ] Erstentwurf / Konzept
- [ ] Angebot erstellt + versandt
- [ ] Nächstes Nachfassen gesetzt (+10 T)
- [ ] Nachgefasst (Anruf/Mail)
- [ ] Entscheidung: Gewonnen → nach ② / Verloren → Grund dokumentiert

### Gewerbe / Großprojekt (B2B)  -  Lead: Johannes/Daniel  -  Projekttyp = Gewerbe/B2B
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

### Service / Reklamation  -  Lead: Service-Verantwortliche/r  -  Projekttyp = Service
- [ ] Mangel/Defekt erfasst + Ursprungsprojekt verknüpft
- [ ] Fotodoku + Diagnose
- [ ] Verursacher geklärt (eigen vs. Hersteller)
- [ ] Ersatzteil/Nacharbeit bestellt
- [ ] Servicetermin vereinbart
- [ ] Behebung vor Ort
- [ ] Abschluss (ggf. Berechnung/Kulanz)

### Produkt / Gerät (Kleinauftrag)  -  Lead: Verkauf  -  Projekttyp = Produkt/Gerät
- [ ] Anfrage erfasst
- [ ] Preis/Verfügbarkeit bestätigt
- [ ] Bestellung beim Hersteller
- [ ] Lieferung/Abholung
- [ ] Rechnung gestellt

### Intern / Entwicklung  -  Lead: Team  -  Projekttyp = Intern
- [ ] Konzept/Zielbild
- [ ] Planung + Budget intern
- [ ] Umsetzung/Bau
- [ ] Fertigstellung + Doku

## Schritt 6 - Automationen  (5 min)
Space/Folder -> **Automations -> Add automation**. Rezepte:

| Automation | When (Ausloeser) | Then (Aktion) |
|---|---|---|
| A1 · Lead & Nachfass beim Anlegen | Neuer Task in ① Pipeline | Lead aus Feld zuweisen + ›Nächstes Nachfassen‹ auf +10 T |
| A2 · Entscheidungs-Engpass | Status ›Angebot raus‹ seit 14 T unverändert | Kommentar + Benachrichtigung an Lead: nachfassen |
| A3 · Sofort beschaffen | Status → ›✅ Gewonnen‹ | Task nach ② verschieben, Vollprojekt-Checkliste anwenden, Einkauf benachrichtigen |
| A4 · Abnahme vorbereiten | Status → ›Montage‹ | Checkpunkte ›Abnahmeprotokoll‹ + ›Mängelliste‹ erzeugen, Subtask ›Abnahmetermin‹ |
| A5 · Schlussrechnung | Status → ›Abnahme/Übergabe‹ | Task ›Schlussrechnung‹ für Frauke/Accounting, fällig +7 T |
| A6 · Großauftrag priorisieren | Budget > 50.000 € | Priorität = Dringend setzen |
| A7 · Nachfass-Fälligkeit | ›Nächstes Nachfassen‹ erreicht | Benachrichtigung an Lead |
| A8 · Service-SLA | Status ›Teil/Nacharbeit‹ seit 7 T | Benachrichtigung an Service |

## Schritt 7 - Dashboard  (3 min)
**+ Dashboard** -> `mykilOS Steuerung` -> Cards anlegen:

- Projekte je Phase (Anzahl)
- Pipeline-Wert (Σ Budget in ①)
- Auftragswert aktiv (Σ Budget in ②)
- Konversion Angebot → Auftrag
- Ø Verweildauer je Phase
- Überfällige Nachfass-Termine
- Offene Service-/Reklamationsfälle

---

## Danach: ich befuelle (Connector)
Sag mir Bescheid, sobald Geruest steht und der Connector freigegeben ist. Dann lese ich die Feld-IDs und lege alle Projekte als Tasks an - in der richtigen Liste, mit Status = zuletzt erkannter Phase und vorbefuellten Feldern (Ort, Lead, Projekttyp, Budget, Kunde, Kunde-Token, Slack-Channel). Zielverteilung:

| Ordner | Tasks |
|---|---|
| (1) Angebote | 73 |
| (2) Aktive Projekte | 92 |
| (3) Service & Reklamation | 0 |
| (4) Intern & Entwicklung | 4 |

Plus ein ClickUp-Doc mit dem 11-Phasen-Modell und den Routinen.