# S18 Autonomous Article Research Runner

Status: verbindliche Ergaenzung fuer den WorkBasket Checkout Branch.

## Ziel

Die Artikel-Bild- und Preisrecherche soll vollstaendig autonom als mykilOS Pipeline laufen. Die Pipeline arbeitet alle Zielartikel ab, sammelt Quellen, Bilder, Preise und Kandidaten, bewertet Treffer, fuellt ReviewQueue und erzeugt freigegebene Vorschlaege. Sie aendert keine Stammdaten ohne Review.

## Ergebnisziel

Fuer jeden Zielartikel:

- ResearchJob
- SearchPlan
- QuerySet
- CandidateResults
- ImageCandidates
- PriceObservations
- SourceEvidence
- MatchScore
- ReviewQueue Status
- Optional ApprovedCandidate nach Review
- Optional WorkBasket/Checkout Nutzung

## Autonomie-Regel

Autonom bedeutet:

1. Die App kann die Recherche ohne manuelles Oeffnen jeder Zeile ausfuehren.
2. Die App kann Quellen priorisieren.
3. Die App kann Treffer bewerten.
4. Die App kann sichere Kandidaten vorschlagen.
5. Die App kann unklare Kandidaten in Review stellen.
6. Die App kann Batch fuer Batch fortsetzen.

Autonom bedeutet nicht:

- Stammdaten automatisch ueberschreiben
- Preise ohne Quelle akzeptieren
- Bilder ohne Nutzungsstatus verwenden
- Massenwrites ohne Policy
- externe Systeme ohne Audit veraendern

## Runner Komponenten

### ArticleResearchRunner

Orchestriert den Lauf.

Inputs:
- Artikelquelle
- Batch Groesse
- Prioritaet
- Adapterliste
- Rate Limits
- Safety Policy

Outputs:
- ResearchRun
- ResearchJobs
- CandidateResults
- ReviewQueue
- RunReport

### SearchPlanBuilder

Erzeugt pro Artikel einen Plan:

- Hersteller plus Artikelnummer
- Hersteller plus Modellname
- EAN falls vorhanden
- Hersteller plus Datenblatt
- Hersteller plus Produktbild
- Hersteller plus Preis
- Modell plus Preis
- Modell plus Haendler

### SourceAdapterRegistry

Adapter-Reihenfolge:

1. vorhandene Airtable Felder
2. vorhandene Drive Kataloge
3. vorhandene PDF Preislisten
4. Hersteller-Webseiten
5. bekannte Haendlerquellen
6. kontrollierter Websearch
7. kontrollierter Bildsearch

### CandidateNormalizer

Normalisiert Treffer:

- source_url
- title
- snippet
- image_url
- price
- currency
- vat_status
- availability
- manufacturer
- article_number
- ean
- observed_at

### MatchScoringEngine

Score-Regeln:

- Hersteller exakt: plus 0.25
- Artikelnummer exakt: plus 0.35
- EAN exakt: plus 0.25
- Modellname exakt: plus 0.10
- Kategorie passt: plus 0.05

Abzug:

- Variante unklar
- andere Farbe
- andere Laenge/Breite
- kein Preisdatum
- keine Artikelnummer
- keine Quelle

### ReviewRouter

Routing:

- accepted_candidate: sehr hohe Sicherheit, interne Freigabe trotzdem sichtbar
- needs_review: unklare Variante, unklarer Preis, unklarer Bildstatus
- rejected: falscher Hersteller, falscher Artikel, fehlende Quelle
- duplicate: gleicher Treffer existiert bereits

## Batch Steuerung

Standard:

- Batch 1: 20 Artikel Pilot
- Batch 2: P0 High Value
- Batch 3: P1 Medium High
- Batch 4: Herstellerweise grosse Mengen
- Batch 5: Restbestand

Jeder Batch erzeugt RunReport.

## RunReport Felder

- run_id
- started_at
- finished_at
- source_count
- jobs_created
- queries_executed
- candidates_found
- images_found
- prices_found
- accepted_candidates
- review_candidates
- rejected_candidates
- errors
- rate_limit_events
- data_changes

## Safety Gates

Vor jedem Run:

- git/status irrelevant fuer App-Run, aber Build/Test fuer Implementierung
- Adapter aktiv
- API Credentials vorhanden
- Rate Limit gesetzt
- Target Count bekannt
- WritePolicy aktiv
- ReviewQueue aktiv
- Audit aktiv

Waehrend Run:

- keine Stammdatenupdates
- keine externen finalen Writes
- keine Datei-Mutation
- keine Secrets im Log
- Fehler pro Artikel isolieren

Nach Run:

- RunReport
- ReviewQueue
- AuditLog
- NextBatchPlan

## UI Ziel

Artikelrecherche bekommt eine eigene Ansicht:

- Run starten
- Batch waehlen
- Fortschritt sehen
- Treffer sehen
- Quellen oeffnen
- Review abarbeiten
- Kandidaten akzeptieren/ablehnen
- accepted Kandidaten in WorkBasket legen

## Implementierungsreihenfolge

1. S0/S1/S2 abschliessen.
2. Domain: ResearchRun, ResearchJob, SearchPlan, CandidateResult.
3. Stores und Persistence.
4. Adapter Interfaces.
5. Local CSV/Drive/PDF Adapter.
6. Hersteller Adapter.
7. Kontrollierter Websearch Adapter.
8. MatchScoringEngine.
9. ReviewRouter.
10. Runner.
11. UI.
12. Pilot.
13. Batch Ausbau.

## Tests

- runnerCreatesJobsForAllArticles
- searchPlanContainsManufacturerSkuEan
- candidateWithoutSourceRejected
- priceWithoutTimestampRejected
- imageWithoutRightsNeedsReview
- exactSkuEanScoresHigh
- wrongVariantScoresLow
- batchContinuesAfterSingleArticleError
- noMasterDataWriteDuringRun
- runReportCountsMatchOutputs

## Live Gate

LG-21: Runner verarbeitet 20 Artikel autonom.
LG-22: Runner verarbeitet alle P0 Artikel autonom.
LG-23: Runner verarbeitet 1000 Artikel autonom mit Rate Limits.
LG-24: Runner verarbeitet alle Zielartikel in Batches.
LG-25: Keine Stammdaten wurden automatisch geaendert.

## Schlussregel

Autonomer Lauf ja. Autonome Wahrheit nein. Wahrheit entsteht erst durch Quelle, Matchscore, Review und Audit.
