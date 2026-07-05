# Article Image and Price Research Pipeline

Status: Architekturergänzung fuer den WorkBasket Checkout Branch.

## Auftrag

Fuer jeden Artikel sollen Bildquellen, Herstellerbilder, Produktbilder, Marktpreise, Preislistenhinweise und Quellenbelege recherchiert werden. Das Ergebnis wird nicht direkt in den Artikelstamm geschrieben, sondern als Research- und Review-Schicht gefuehrt.

## Grundregel

Jeder Artikel wird zu einem Research Job. Jeder Treffer wird als Beobachtung gespeichert. Kein Treffer wird ohne Review zur Wahrheit.

Article DataObject -> ResearchJob -> SearchQueries -> CandidateResults -> Evidence -> Review -> Approved Image or Price Observation.

## Quellenarten

1. Herstellerseite
2. Hersteller PDF oder Preisliste
3. Haendlerseite
4. Bildquelle
5. Websuche
6. vorhandener Drive Katalog
7. vorhandene Airtable Artikeldaten
8. Angebot oder Archivbeleg

## Suchstrategie pro Artikel

Pro Artikel werden mehrere Suchstrings erzeugt:

- Hersteller plus Artikelnummer
- Hersteller plus Modellname
- Hersteller plus EAN, falls vorhanden
- Artikelnummer plus Produktkategorie
- Modellname plus Produktbild
- Modellname plus Preis
- Hersteller plus PDF plus Preisliste
- Hersteller plus Datenblatt

## Research Tabellen

ArticleResearchJobs
ArticleSearchQueries
ArticleCandidateResults
ArticleImageCandidates
ArticlePriceObservations
ArticleSourceEvidence
ArticleResearchReviewQueue

## Pflichtfelder ResearchJob

job_id
article_data_object_id
manufacturer
model
article_number
ean
query_count
status
created_at
updated_at
review_status

## Pflichtfelder CandidateResult

candidate_id
job_id
source_url
title
snippet
source_type
match_score
confidence
needs_review
created_at

## Pflichtfelder ImageCandidate

image_candidate_id
job_id
source_url
image_url
thumbnail_url
manufacturer
model
article_number
usage_rights_status
match_score
review_status

## Pflichtfelder PriceObservation

price_observation_id
job_id
source_url
source_type
price_net
price_gross
currency
vat_status
availability
observed_at
match_score
review_status

## Match Regeln

Hohe Sicherheit:
- Hersteller exakt
- Artikelnummer exakt
- Modellname exakt
- Quelle Hersteller oder autorisierter Haendler

Mittlere Sicherheit:
- Hersteller exakt
- Modellname aehnlich
- Artikelnummer fehlt

Review Pflicht:
- nur Bild passt optisch
- Preis ohne Artikelnummer
- unklarer Haendler
- abweichende Variante
- andere Farbe oder anderes Finish

## Safety

- Keine Originaldaten ueberschreiben.
- Keine Preise direkt in Artikelstamm schreiben.
- Keine Bilder ohne Nutzungsstatus als extern nutzbar markieren.
- Keine Massenaktion ohne Batch-Plan.
- Keine stillen Imports.
- Jede Beobachtung bekommt Quelle, Zeitstempel und Matchscore.

## Batch Ablauf

1. Artikel aus Airtable lesen.
2. ResearchJobs erzeugen.
3. Queries erzeugen.
4. Suchadapter ausfuehren.
5. Treffer normalisieren.
6. Bild- und Preiskandidaten speichern.
7. ReviewQueue erzeugen.
8. Nach Review Bild oder Preisbeobachtung freigeben.
9. Erst durch separaten Checkout kann daraus ein Artikelupdate-Vorschlag entstehen.

## Suchadapter

Erlaubte Adapter:
- vorhandene Drive Kataloge
- Herstellerseiten Adapter
- PDF Preislisten Adapter
- Web Search Adapter mit dokumentierter API
- lokaler Browser-Assisted Research Adapter

Der Web Search Adapter muss rate limited, protokolliert und abschaltbar sein.

## Output in mykilOS

Artikel Detail bekommt:
- gefundene Bilder
- Preisbeobachtungen
- Quellenbelege
- Matchscore
- Reviewstatus
- letzte Recherche
- Button: Review oeffnen
- Button: Kandidat in Warenkorb
- Button: Kandidat fuer Artikelupdate vorschlagen

## Tests

- query generation per article
- exact article number match
- variant mismatch goes to review
- image candidate does not overwrite article image
- price observation does not overwrite article price
- batch threshold triggers review
- every candidate has source_url
- every price has observed_at
- unknown rights blocks external use

## Live Gate

LG-16: 20 Artikel mit Hersteller und Artikelnummer recherchieren.
LG-17: 10 Bildkandidaten mit Reviewstatus erzeugen.
LG-18: 10 Preisbeobachtungen mit Quelle und Zeitstempel erzeugen.
LG-19: Kein Artikelstamm wurde automatisch veraendert.
LG-20: ReviewQueue zeigt unsichere Treffer.
