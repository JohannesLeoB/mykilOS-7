# Bauplan — Kalkulations-Korpus → Team-Airtable (KOMPLETT)

*2026-07-05 spät. Read-only Inventar erledigt (selbst per Bash, Groundtruth-Vault
`~/mykilOS-App-Backups/kalk-korpus-groundtruth-01/brain/`). Johannes: „alle Korpus-Daten
UND Logiken komplett in die Team-Airtable" (Write-GO gegeben; volle Team-Parität, Admin-/
Sichtbarkeits-Feinsteuerung später). Gegencheck ausstehend; Schreiben erst nach GO + Gauge-Check.*

## Ziel-Base
`appuVMh3KDfKw4OoQ` (Mastermind — „enthält eh alle unsere Geheimnisse"). **Airtable = wachsende
Wahrheit · lokales `learning.sqlite` = Laufzeit-Cache** (jeder Mac zieht runter). Es gibt HEUTE
keine Korpus-Tabelle (nur `Eingehende-Angebote`, tbliKfs5FnufjdB36, = App-Live-Flow, NICHT der
historische Korpus → bleibt getrennt).

## Korpus-Inventar (Vault = System-of-Record)
| CSV | Zeilen | Natürlicher Schlüssel (Idempotenz) |
|---|---|---|
| source_documents | 146 | `sha256` (bzw. doc_id) |
| source_pages | 481 | `page_id` |
| money_observations | 3.384 | `money_id` |
| position_candidates | 817 | `candidate_id` (+ `candidate_dedupe_key`) |
| active_price_anchors | 203 | `candidate_id` |
| component_price_atoms | 199 | `atom_id` |
| superseded_candidates | 275 | `candidate_id` |
| review_queue | 339 | `candidate_id` |
| semantic_prices | 9 | `component_class`+`basis` |
| semantic_dictionary | 101 | `term` |
| random_test_kitchens/components | ~40 | (Test-Szenarien, optional) |

**Logik-Dateien** (Regeln/Config, nicht nur Daten): `semantic_dictionary`, `semantic_prices`,
+ aus `_Daten/Kalkulation/EstimationCore_v1_BRANDLESS_verifiziert/exports/`:
`scope_signature_rules`, `calibration_cases`, `component_taxonomy`, `price_summary_by_scope`,
`normalized_anchor_scope_signatures` + Docs `CALIBRATION_REFERENCE.md`, `CALCULATION_BRAIN_RULES.md`.

## Schema-Vorschlag (Airtable-Tabellen, Präfix „Korpus-")
1 Tabelle je Entität, Namen `Korpus-Belege`, `Korpus-Seiten`, `Korpus-Beobachtungen`,
`Korpus-Positionen`, `Korpus-Anker`, `Korpus-Atome`, `Korpus-Superseded`, `Korpus-Review`,
`Korpus-SemantikPreise`, `Korpus-Woerterbuch` (+ Logik: `Korpus-ScopeRegeln`, `Korpus-Kalibrierung`,
`Korpus-Taxonomie`). Felder = die CSV-Spalten (Typen: Text/Number/Date/SingleSelect für status/
doc_type/component_class; `scope_json`/`original_text` = Long text). Beziehungen über die IDs als
Text-Referenz (kein harter Link-Zwang nötig für v1 — hält den Import simpel).

## Import-Strategie (eiserne Regeln)
- **Append-only, kein DELETE, kein Anfassen bestehender/Daniels Records.** Nur CREATE in die neuen `Korpus-`-Tabellen.
- **Idempotent:** vor CREATE per natürlichem Schlüssel prüfen (Re-Run legt keine Doppel an). SHA256-Dedup für Belege.
- **Batched:** Airtable-Limit ~5 req/s, 10 Records/Request → 3.384 Beobachtungen ≈ 340 Requests ≈ ~70 s allein dafür; gesamt ~6.000 Records → sorgfältig gedrosselt, mit Fortschritt + Wiederaufnahme bei Abbruch.
- **Reihenfolge:** erst Struktur (Tabellen anlegen, low-risk, leere Tabelle ist reversibel), Gegencheck, DANN Records.

## Sync-Pfad (App liest zurück)
Neuer read-only Sync: Airtable `Korpus-*` → lokales `learning.sqlite` beim App-Start/`Sync`-Knopf
(bei Google/Airtable verbunden). App nutzt weiter `learning.sqlite` (schnell, offline) — Airtable
ist die Quelle, die alle teilen + die zentral wächst (bestätigte Anpassung → append nach Airtable).

## Datenstrom-Handbuch (Pflicht, `tblaUVftka0GvXzeU`)
Zwei neue Weichen: `KORPUS_IMPORT` (einmalig/Nachträge, mykilOS→Airtable, WRITE, append-only) +
`KORPUS_SYNC` (Airtable→learning.sqlite, READ). `DataFlowLogger`-IDs = exakt diese Strings.

## Kanonische Quelle (verifiziert)
**Location B** `~/mykilOS-App-Backups/kalk-korpus-groundtruth-01/brain/` = der **volle Roh-Korpus** (money_observations 3385 …), sha256-verankert (`IDENT.md`/`MANIFEST.sha256`) → **Import-Quelle**. Location A (`EstimationCore_v1_BRANDLESS_verifiziert`) = downstream, marken-bereinigt, unabhängig gegengeprüft (201/201 Anker identisch) — gut als Verifikations-Gegenprobe. **3 Schema-Generationen auf der Platte** (v0.3-Contract, v4-fullcorpus, brandless-v1) — v4-Groundtruth ist die aktive; die v0.3 mal als „historisch" labeln (nicht jetzt).

## ⚠️ Bewusste Überstimmung
Ein alter Backlog-Eintrag (`IDEEN_UND_BACKLOG.md`) sagte „Zulieferpreise/Rohbeobachtungen bleiben LOKAL, nicht Airtable". **Johannes hat das am 2026-07-05 bewusst überstimmt** („komplett rein, die Team-Airtables enthalten eh alle Geheimnisse"). → volle Parität, Roh + destilliert. (Backlog-Eintrag entsprechend aktualisieren.)

## Offene Entscheidungen (Gegencheck)
4. **Geräte-Katalog** (`Devices/catalog.csv`, 5.566 Artikel mit EK-Preis + MYKILOS-VK + sevDesk-Artikel-ID) — separat vom Angebote-Korpus. AUCH nach Airtable, oder erstmal draußen (Daniel-nah / eigenes Thema)? *(Empfehlung: separater Strang — es ist eine andere Preis-Dimension.)*

1. **Umfang:** alle ~11 Tabellen inkl. Hilfs (source_pages 481 Text-Excerpts, review/superseded) — oder v1 = **Kern + Logik** (Belege/Beobachtungen/Positionen/Anker/Atome + Wörterbuch/Semantik/Scope-Regeln), Hilfs später? *(Empfehlung: Kern+Logik zuerst, Hilfs optional.)*
2. **Import-Werkzeug:** per Airtable-MCP (Claude schreibt gedrosselt) ODER ein lokales `curl`/Skript mit PAT (schneller für 6k Records, wie beim Mastermind-Seed 2026-06-27). *(Empfehlung: Skript für die Masse, MCP für Struktur/Kleines.)*
3. **Roh vs. destilliert:** Johannes will KOMPLETT → alle rein (bestätigt). Nur bestätigen, dass auch `money_observations` (die rawsten EK-nahen Beträge) rein sollen. 

## Ausführung (Gauge-Gate)
Struktur (Tabellen anlegen) ist klein → geht ggf. noch heute. Der **Massen-Import (~6.000 Records)
ist context-schwer** → läuft am saubersten in einer frischen Session mit lokalem Skript (Claude
überwacht, kein halb-geschriebener Zustand). Plan liegt dann fertig bereit.
