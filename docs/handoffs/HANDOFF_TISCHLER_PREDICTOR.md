# HANDOFF — feat/tischler-predictor (B-gated, selbstwachsendes Schätz-Brain)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/tischler-predictor (von release/7.5, dem aktuellen grünen Stand)
Entscheidung (Johannes, 2026-06-29): B-gated
Datum:  2026-06-29
```

> **⚠️ Der veralteten `CLAUDE.md` NICHT trauen** (eingefrorener 6.4.0-Stand). Alle Aussagen unten
> gegen den echten Code verifizieren. Lebender Stand: HYPERBUILD.md + dieser Handoff.

## Ziel

Das Schätz-Brain **selbstwachsend** machen: bestätigte **eingehende** Lieferanten-Angebote werden zu
Preis-Ankern, die `schaetze` direkt liest — **hinter einem Review-Gate**, ohne die Offline-Backtest-
Disziplin (Leave-one-out, ~8 %) zu verlieren.

## Verifizierte Ausgangslage (kein Greenfield)

- GRDB-Gerüst existiert: v2 `document_imports`, v3 `airtable_offer_sync` (`nettoEur`/`kind`/`reviewActionID`)
  — mit Insert/Read-Methoden, aber **von niemandem befüllt/gelesen**.
- Aktuelle Angebote: Preis kommt **strukturiert aus Airtable** (`AirtableOfferEntry.nettoEur`;
  `AirtableOfferStatus.learningReason(kind:)` kodiert die Disziplin schon: eingehend+Schlussrechnung 2,0×,
  eingehend+akzeptiert 1,6×, ausgehend → eigener Kanal/nie Kostenboden, abgelehnt → kein Signal).
  → **Kein PDF-Parsing nötig** für aktuelle Angebote.
- `LearningStore` hat **keinen** Anker-Schreibpfad (nur `saveSession`/`appendAdjustment`/`promote…`/`deactivate…`).
  `schaetze` baut `EvidenceBasedEstimator(provider:, calibrationProvider: learningStore)` — Anker kommen
  aus `provider` (heute `BrainSeedProvider` = gebackenes CSV).
- Archiv-Smoke-Test faktisch erledigt: `source_documents_fullcorpus_v4.csv` = **146/146 sauberer Text,
  keine Scans**. Einziger Fix: `DriveFileReader.maxChars = 6000` schneidet 85/146 lange Angebote ab.
- Externe Daten (Mac, **nie ins Repo**): `catalog.csv` (5.565 Geräte, verdrahtet),
  `active_price_anchors.csv` (~200 Anker, speist `schaetze` schon).

## Prerequisite (zuerst, read-only — entscheidet Phase-2-Aufwand)

- Maßgebliche Schema-Quelle: `…/mykilO$$$/ClaudeCode_Final_Handoff_2026-06-26/04_PROJECT/
  MYKILOSKalkulationslabor/Docs/DATA_CONTRACT.md` + `CALIBRATION_REFERENCE.md`. Prüfen: existiert das
  **Ausstattungs-Feld** (Schubkasten-Anzahl × Variante) schon im Schema?
- Im v7-Code: haben `ActivePriceAnchors`/PositionCandidate schon ein Auszugs-/Ausstattungsfeld?

## Phase 1 — Airtable-Sync + Composite-Anker hinter Review-Gate (DIESE Session)

1. **Anker-Schreibpfad** im `LearningStore` (append-only, Dedup über `airtableRecordID UNIQUE`).
2. `AirtableClient` listet abgeschlossene Angebote → **Filter via `learningReason`** (nur eingehend/
   akzeptiert/Schlussrechnung werden Kostenanker; ausgehend → getrennter Marktkanal) → in
   `airtable_offer_sync` schreiben.
3. `review_actions` als **menschliches Gate** (Action-Card → Bestätigung → Audit).
4. Neuer `LearnedAnchorProvider` (liest **nur** review-bestätigte Anker) + `CompositeAnchorProvider`
   (Seed-CSV + gelernte Anker) → in `schaetze` einhängen.
5. Schutzschalter: nur netto, nur eingehend, Dedup, **Zeitgewichtung** gegen Inflation 2021–23
   (Estimator hat heute keine — ergänzen).
6. **Cold-Start-Test:** bestätigter Anker überlebt Neustart + verschiebt `schaetze` messbar.

## Phase 2 — Ausstattungs-Parameter + Positions-Parser (gated auf grünes Phase 1)

- Neues Feld **Ausstattungsgrad pro Korpus** (Schubkasten-Anzahl × Variante: Standard/Legrabox/Apotheker/
  Innenauszug). Zerlegt die €/m²-Front-Spanne **1365–2809** (`BottomUpCost.swift`) in enge, begründbare Bänder.
  Engine trennt `drawerAddon` schon — fehlt: positionsweises Parsen im Korpusbau-Kontext.
- ~30 saubere **Weichsel78**-Angebote (= die Tischlerei) parsen: nicht „Unterschrank 60 cm = X €",
  sondern „Unterschrank 60 cm, 4 Auszüge Legrabox = X €".

## Regeln (nicht verhandelbar)

- `main` heilig; signierte Commits (SSH); Conventional Commits + S-/Phasen-Nummer; PR statt Direct-Merge.
  Vertrag: [docs/GIT_WORKFLOW.md](../GIT_WORKFLOW.md).
- **EK-Preise NIE ins Repo.** Externe Daten read-only.
- **Datenhygiene-Regel:** Wird im Zuge der Arbeit Code tot (z. B. bei Kalkulation-Sidebar-Entkopplung →
  `KalkulationsWidget`/`KalkulationsPageView`/`AppModule.kalkulation`), aktiv melden statt verschleppen.
