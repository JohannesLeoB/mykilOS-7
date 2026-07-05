# Session Log — S17 Artikel Bild- und Preisrecherche

Datum: 2026-07-01
Branch: handoff/workbasket-checkout-architecture-2026-07-01
Typ: docs-only, non destructive

## Eingebracht

- ARTICLE_IMAGE_PRICE_RESEARCH_PIPELINE.md
- ARTICLE_RESEARCH_STARTPROMPT.md
- PR-Kommentar zur S17-Ergaenzung

## Architekturentscheidung

Jeder Artikel wird als ResearchJob bearbeitet. Bild- und Preisfunde werden nicht direkt in den Artikelstamm geschrieben, sondern als Kandidaten, Beobachtungen und Quellenbelege mit Reviewstatus gefuehrt.

## Safety

- Kein automatisches Ueberschreiben von Artikelbildern.
- Kein automatisches Ueberschreiben von Artikelpreisen.
- Jeder Treffer braucht Quelle.
- Jeder Preis braucht Beobachtungszeitpunkt.
- Unklare Treffer gehen in Review.
- Massenrecherche braucht Batch-Grenzen.

## Naechster Schritt

S17 erst nach S0/S1/S2 starten: System Truth Map, I/O Register und Safety Engine muessen stehen.
