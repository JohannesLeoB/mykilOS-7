# S18 — Codex Encapsulated Article Research Capsule

Status: Korrektur der S18-Zielarchitektur.

## Grundentscheidung

Die vollstaendige Artikel-Datenerschliessung laeuft nicht innerhalb von mykilOS.

Sie laeuft als separater, gekapselter Codex-Prozess.

mykilOS bleibt geschuetzt. Codex erschliesst, sammelt, normalisiert, bewertet und exportiert. mykilOS importiert spaeter nur strukturierte Review- und Staging-Ergebnisse.

## Ziel

Aus der Artikeldatenbank entsteht eine grosse, strukturierte Quellen- und Kandidaten-Datenbank.

Pipeline:

Artikel-CSV oder Artikeldatenbank
-> Codex Capsule
-> Research Jobs
-> Search Queries
-> Quellenfunde
-> Bildkandidaten
-> Preisbeobachtungen
-> Dokumentquellen
-> Matchscores
-> ReviewQueue
-> accepted/rejected Kandidaten
-> SQLite und CSV Export

## Harte Trennung

Nicht in mykilOS implementieren.
Nicht mykilOS starten.
Nicht mykilOS-Datenbank beschreiben.
Nicht Airtable direkt beschreiben.
Nicht Artikelstamm aendern.
Nicht Bilder oder Preise automatisch uebernehmen.

## Capsule Struktur

mykilOS-data-research-capsule/
  capsule_input/
  capsule_work/
  capsule_cache/
  capsule_logs/
  capsule_output/

## Output Dateien

capsule_output/research_jobs.csv
capsule_output/search_queries.csv
capsule_output/source_candidates.csv
capsule_output/image_candidates.csv
capsule_output/price_observations.csv
capsule_output/document_sources.csv
capsule_output/match_scores.csv
capsule_output/review_queue.csv
capsule_output/accepted_candidates.csv
capsule_output/rejected_candidates.csv
capsule_output/run_report.csv
capsule_output/research_database.sqlite
capsule_output/research_database_manifest.json

## Datenbank Tabellen

research_runs
research_jobs
search_queries
source_candidates
image_candidates
price_observations
document_sources
match_scores
review_queue
accepted_candidates
rejected_candidates

## Codex Arbeitsauftrag

Codex soll autonom fuer alle Zielartikel:

- ResearchJobs erzeugen
- Suchqueries erzeugen
- Herstellerseiten, Haendlerseiten, PDF-Quellen, Bildquellen und vorhandene Katalogquellen auswerten
- Quellenfunde normalisieren
- Bildkandidaten speichern
- Preisbeobachtungen speichern
- Dokumentquellen speichern
- Matchscores berechnen
- ReviewQueue fuellen
- accepted und rejected Kandidaten trennen
- SQLite und CSV Exporte erzeugen
- RunReport schreiben

## Suchstrategie

Pro Artikel mindestens:

- Hersteller plus Artikelnummer
- Hersteller plus Artikelnummer plus EAN
- Hersteller plus Modell oder Beschreibung
- Artikelnummer plus Produktbild
- Artikelnummer plus Preis
- Hersteller plus PDF plus Preisliste
- Hersteller plus Datenblatt
- Hersteller Site Search
- Dealer Price Search
- Image Search

## Matchscore

Plus:

- Hersteller exakt: 0.25
- Artikelnummer exakt: 0.35
- EAN exakt: 0.25
- Modell/Beschreibung passend: 0.10
- Kategorie passend: 0.05

Minus:

- andere Variante
- andere Farbe
- andere Groesse
- fehlende Artikelnummer
- fehlende Quelle
- unklarer Preis
- unklare Bildrechte

## Accepted Regeln

Accepted nur bei hoher Sicherheit:

- Hersteller exakt
- Artikelnummer exakt oder EAN exakt
- source_url vorhanden
- retrieved_at vorhanden
- bei Preis: currency und VAT status vorhanden
- bei Bild: usage_rights_status gesetzt

Sonst Review.

## Output in mykilOS spaeter

mykilOS bekommt spaeter nur capsule_output.

Importziel ist Review/Staging, nicht produktiver Artikelstamm.

mykilOS zeigt spaeter:

- Quellenfunde
- Bildkandidaten
- Preisbeobachtungen
- Matchscore
- Reviewstatus
- accepted Kandidaten
- rejected Kandidaten

## Definition of Done

Vollstaendig gruen ist erst:

- alle Zielartikel haben ResearchJob
- alle Zielartikel haben SearchQueries
- alle Zielartikel haben mindestens einen Quellen- oder Reviewstatus
- alle Preisfunde haben Quelle und Zeitstempel
- alle Bildfunde haben Quelle und Nutzungsstatus
- alle Scores berechnet
- ReviewQueue vollstaendig
- SQLite erzeugt
- CSV Export erzeugt
- Manifest erzeugt

## Schlussregel

Codex erschliesst autonom.
mykilOS bleibt unberuehrt.
Wahrheit entsteht erst durch Quelle, Matchscore, Review und Audit.
