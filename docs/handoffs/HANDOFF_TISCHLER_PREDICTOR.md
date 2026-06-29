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

---

## ✅ Prerequisite-Befund (read-only, 2026-06-29)

**Frage 1 — existiert das Ausstattungs-Feld im Schema (`DATA_CONTRACT.md`)?** Ja, teilweise.
- `OfferPositionBlock` trägt `drawer_count` (Schubkasten-Anzahl) + `scope_flags` + `materials`.
- `ComponentPriceAtom` trägt `complexity_class` / `scope_class` / `material_class`.
- **Aber:** es gibt KEINEN expliziten Varianten-Enum (Standard/Legrabox/Apotheker/Innenauszug).
  Die Variante steckt nur implizit in `scope_flags`/`materials`/`complexity_class`.

**Frage 2 — hat der v7-Laufzeit-Anker (`ActivePriceAnchors`/PositionCandidate) ein Auszugsfeld?** Nein.
- Der Laufzeit-Anker `CandidateReleaseDecision` (= was `schaetze` liest) hat **kein** Schubkasten-/
  Ausstattungsfeld — nur `priceNetGuess`, `componentClass`, Freitext (`component`/`title`/`evidenceQuote`/
  `ruleNotes`). Schubkasten-Info wird heute nur über Substring-Matching („legrabox"/„schub") inferiert.
- Die Parse-/Request-Modelle (`OfferPositionBlock.drawerCount`, `EstimateComponent.drawerCount`) tragen es;
  der **Release-Anker nicht**.

**→ Phase-2-Aufwand:** Ein `drawerCount: Int` + Varianten-Feld muss in `CandidateReleaseDecision`
(und den Korpus-Bau, der ihn füllt) ergänzt und vom `OfferPositionBlock` durchgereicht werden. Das ist
die eigentliche Arbeit von Phase 2 — Phase 1 berührt es bewusst nicht.

## ✅ Phase 1 — gebaut & grün (2026-06-29, 421 Tests)

Branch `feat/tischler-predictor`. Build grün, 421 Tests grün, neue Datei lint-clean.

- **v4-Migration** (`LearningDatabase`): `airtable_offer_sync.offerDate` (additiv, nullable) — trägt das
  Original-Angebotsdatum für die Zeitgewichtung. `AirtableOfferSyncEntry`/Record um `offerDate` ergänzt.
- **`OfferAnchorSync.swift`** (neu):
  - `LearningStore.syncAirtableOffers(_:)` — Schreibpfad. Schutzschalter: **nur eingehend** mit gültigem
    `learningReason`, **nur netto**, **Dedup** über `airtableRecordID UNIQUE`. Append-only + Audit.
  - `LearningStore.confirmOfferAnchor(airtableRecordID:note:)` — **menschliches Review-Gate** als
    `ReviewAction(.releaseAsActiveAnchor)` + Audit (append-only). Erst danach wird ein Eintrag Anker.
  - `OfferAnchorInflation` — **Zeitgewichtung** im gelernten Kanal (4 %/J auf Gegenwartswert, gekappt
    auf 6 J; plus Konfidenz-Abschlag fürs Alter). Lässt den geschützten Estimator unangetastet.
  - `LearnedAnchorProvider` — liest **nur** review-bestätigte eingehende Angebote → gegenwartsnormierte
    `aggregateKitchen`-Anker.
  - `CompositeAnchorProvider` — Seed-Korpus (`BrainSeedProvider`) + gelernte Anker; gelernter Kanal
    degradiert still (Seed bleibt allein funktional).
- **Wiring** (`AppState`): ein geteilter `LearningStore` speist Engine **und** `CompositeAnchorProvider`.
- **Tests** (`OfferAnchorSyncTests`, 6): Schutzschalter (ausgehend/signallos gefiltert), Dedup, Review-Gate
  (unbestätigt = kein Anker), Zeitgewichtung, **Cold-Start** (bestätigter Anker überlebt Neustart) und
  **voller Pfad** (bestätigte Anker verschieben `schaetze` nach Neustart messbar nach oben).

### Bewusste Phase-1-Grobheit (Datenhygiene-Hinweis)
Ein bestätigtes Angebot ist ein **Whole-Offer-Gesamtbetrag** → modelliert als `aggregateKitchen`-Anker
(Gesamt-Plausibilität), **nicht** positionsweise normalisiert. Das ist genau die Phase-2-Arbeit (Positionen,
€/m²-Front-Bänder, Ausstattungsgrad). Solange ≥3 Komponenten geparst werden, fließen Aggregat-Anker auch
in die Küchenzeile ein — bei sehr wenigen, hohen Whole-Offer-Ankern kann das Komponenten-Schätzungen
verzerren. Schutz heute: Review-Gate + nur-eingehend + Zeitgewichtung + wenige bestätigte Anker.

### Offen / nächste Schritte
- **Live-Airtable-Adapter (Schritt 2, bewusst vertagt):** Tabelle `Eingehende-Angebote`
  (`tbliKfs5FnufjdB36`) ist **leer**, ihre Select-Vokabeln (`Richtung`/`Status`) sind nicht fixiert und sie
  trägt **kein Angebots-Datum** (nur „Importiert-am"). Ein dünner Adapter mappt ihre Records auf
  `[AirtableOfferEntry]` und reicht sie an `syncAirtableOffers(_:)` — sobald die Tabelle befüllt und die
  Vokabeln fix sind. Kein spekulativer Adapter gegen eine leere Tabelle (Datenhygiene-Regel).
- **Review-Action-Card (UI):** `pendingOfferSyncEntries()` ist die Datenquelle für eine Bestätigungs-Karte;
  die UI fehlt noch (Datenpfad + Gate sind fertig und getestet).
- **Datenstrom-Handbuch:** Weiche `AIRTABLE_OFFERS_TO_BRAIN` eintragen, sobald der Live-Fetch läuft
  (jetzt noch kein Runtime-Sync → noch keine Weiche).

## ✅ Phase 2 — Ausstattungsgrad + dichtebewusstes Matching + Lese-Adapter (2026-06-29, 428 Tests)

Branch weiterhin `feat/tischler-predictor` (kein neuer Branch — ein Strang). Build grün, 428 Tests grün,
neue Dateien lint-clean. Grundlage: der zwei-KI-verifizierte Korpus
`_Daten/Kalkulation/EstimationCore_v1_BRANDLESS_verifiziert/` (201/201 Anker = Ground Truth, Summe
808.125 € identisch zu `active_price_anchors.csv`) liefert pro Anker einen **vorberechneten
`equipment_density`/`drawers_per_lfm`** — genau die Phase-2-Lücke.

- **`KitchenScopeSignature.swift`** (neu, MykilosKalkulationsCore): `KitchenEquipmentDensity`
  (none/low/medium/high/very_high/unknown) nach **SCOPE-006** (`drawers_per_lfm`-Schwellen). Bewusste
  **Asymmetrie**: Anker-Seite `drawerCount==0` = `.none` (echte Daten); Anfrage-Seite `drawerCount==0` =
  `.unknown` (Freitext-Schweigen ≠ null) → kein Fehlausschluss. Hart-unvereinbar nur bei ≥2 Stufen
  Abstand und beide bekannt.
- **`CandidateReleaseDecision`** um `equipmentDensity` + `withEquipmentDensity(_:)` ergänzt (in-memory,
  nie aus Persistenz dekodiert → safe).
- **`Estimation.swift`**: `densityCompatible(...)` als Filter NUR für `.kitchenRun`/`.aggregateKitchen`
  und NUR bei bekannter Anfrage-Dichte; Score-Bonus bei Dichte-Treffer (+0.6 gleich / +0.2 benachbart).
- **`ScopeSignatureCatalog.swift`** (neu, MykilosServices): joint `candidate_id → equipment_density` aus
  `normalized_anchor_scope_signatures.csv` an die Seed-Anker (`BrainSeedProvider.activeAnchors()` ruft
  `enrich`). Fehlende Datei → leerer Katalog → `.unknown` → **kein Verhaltenswechsel** (Preise/Backtest
  unberührt).
- **`DriveFileReader.maxChars`** 6000 → 400_000 (6000 schnitt 85/146 Angebote ab = Garbage-in fürs Brain).
- **`IncomingOfferRecordMapper.swift`** (neu, MykilosServices): die getestete, **netzwerkfreie** Naht gegen
  das am 2026-06-29 verifizierte ECHTE `Eingehende-Angebote`-Schema (`tbliKfs5FnufjdB36`, **0 Zeilen** =
  Sync-Ziel, nicht Datenquelle). Records → `[AirtableOfferEntry]` → `syncAirtableOffers`. **Zwei ehrliche
  Lücken** überspielt der Mapper NICHT: (1) `Status` ist Workflow (Neu/Verarbeitet/Archiviert) ohne
  Geschäftsausgang → jede Zeile mappt auf `.eingegangen` (kein Learning-Signal) → Promotion NUR über das
  menschliche Review-Gate, nie auto-abgeleitet; (2) kein Angebotsdatum, nur „Importiert-am" (als `datum`
  durchgereicht, Konfidenz-Abschlag behandelt unbekanntes Jahr konservativ). Kein Live-Fetch verdrahtet.
- **Tests:** `KitchenEquipmentDensityTests` (6, inkl. Akzeptanz „4,5 m Eiche, 6 Schübe, ohne Geräte" =
  low matcht NICHT gegen high-Anker), `ScopeSignatureCatalogTests` (3), `IncomingOfferRecordMapperTests`
  (4: reale Felder, signal-freier Status, Skip unvollständiger Zeilen, Richtung-Toleranz).

### Ehrliche Grenze (Datenhygiene)
20 Test-Küchen sind nur „belegbar", **kein ±7 %-Holdout** — die Genauigkeit ist unbewiesen, die Bänder
bleiben bewusst breit. Der Mapper ist gebaut, aber **kein** Runtime-Sync ist verdrahtet (Tabelle leer,
Vokabeln tragen keinen Geschäftsausgang). → noch keine Datenstrom-Weiche, kein Benutzerhandbuch-Eintrag.

### Offen / nächste Schritte (Phase 2+)
- **Review-Action-Card (UI)** für `pendingOfferSyncEntries()` (Datenpfad+Gate fertig, UI fehlt).
- **Live-Fetch** erst, wenn `Eingehende-Angebote` befüllt ist UND die Vokabeln einen Abschluss tragen
  (heute Workflow-Status); dann `AirtableClient.list → IncomingOfferRecordMapper.map → syncAirtableOffers`
  verdrahten + Weiche `AIRTABLE_OFFERS_TO_BRAIN` ins Datenstrom-Handbuch + Benutzerhandbuch.
- **Positions-Parser** der ~30 Weichsel78-Angebote für positionsweise (statt Whole-Offer-) Anker —
  jetzt mit Dichte-Signatur belegbar.

## Regeln (nicht verhandelbar)

- `main` heilig; signierte Commits (SSH); Conventional Commits + S-/Phasen-Nummer; PR statt Direct-Merge.
  Vertrag: [docs/GIT_WORKFLOW.md](../GIT_WORKFLOW.md).
- **EK-Preise NIE ins Repo.** Externe Daten read-only.
- **Datenhygiene-Regel:** Wird im Zuge der Arbeit Code tot (z. B. bei Kalkulation-Sidebar-Entkopplung →
  `KalkulationsWidget`/`KalkulationsPageView`/`AppModule.kalkulation`), aktiv melden statt verschleppen.
