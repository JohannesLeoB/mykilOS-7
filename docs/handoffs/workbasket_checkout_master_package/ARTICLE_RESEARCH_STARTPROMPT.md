# Startprompt — Artikel Bild- und Preisrecherche

Du arbeitest im Branch handoff/workbasket-checkout-architecture-2026-07-01.

## Auftrag

Baue die Architektur fuer eine produktive Artikel-Bild- und Preisrecherche. Jeder Artikel bekommt ResearchJobs, Suchqueries, Trefferkandidaten, Bildkandidaten, Preisbeobachtungen, Quellenbelege und Reviewstatus.

Nicht direkt Artikelpreise oder Artikelbilder ersetzen. Erst recherchieren, belegen, reviewen.

## Vorher

```bash
pwd
git status
git branch --show-current
swift build
swift test
```

Wenn nicht sauber oder nicht gruen: stoppen.

## Zuerst lesen

- docs/handoffs/workbasket_checkout_master_package/ARTICLE_IMAGE_PRICE_RESEARCH_PIPELINE.md
- docs/handoffs/workbasket_checkout_master_package/IO_REGISTER_SEED.md
- docs/handoffs/workbasket_checkout_master_package/ROLLING_HANDOFF_AND_SESSION_PROTOCOL.md

## Implementierungsreihenfolge

S17.0 Artikel-Research-Schema dokumentieren.
S17.1 Query Generator fuer Hersteller, Modell, Artikelnummer, EAN.
S17.2 ResearchJob Domain.
S17.3 CandidateResult Domain.
S17.4 ImageCandidate Domain.
S17.5 PriceObservation Domain.
S17.6 Adapter Interface fuer Quellen.
S17.7 Drive/PDF Adapter zuerst.
S17.8 Web Search Adapter nur mit dokumentierter API oder lokalem, kontrolliertem Research-Modus.
S17.9 ReviewQueue.
S17.10 UI erst nach funktionierender Review-Schicht.

## Safety

- Keine Originaldaten ueberschreiben.
- Keine Artikelbilder direkt ersetzen.
- Keine Artikelpreise direkt ersetzen.
- Keine unklaren Treffer accepted setzen.
- Keine Massenrecherche ohne Batch-Grenze.
- Kein Treffer ohne Quelle.
- Kein Preis ohne Zeitstempel.
- Keine externe Bildnutzung ohne Nutzungsstatus.

## Tests

- QueryGeneratorTests
- ArticleResearchJobTests
- CandidateMatchScoringTests
- PriceObservationSafetyTests
- ImageCandidateRightsTests
- BatchResearchThresholdTests
- ReviewQueueTests

## Live Gate

20 echte Artikel aus der Artikeldatenbank nehmen. Fuer jeden ResearchJob erzeugen. Fuer mindestens 10 Artikel Bildkandidaten und Preisbeobachtungen erzeugen. Keine Originaldaten automatisch veraendern. ReviewQueue sichtbar.
