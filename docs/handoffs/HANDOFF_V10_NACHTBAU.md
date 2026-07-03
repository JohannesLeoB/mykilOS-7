# HANDOFF — V10-Nachtbau (2026-07-03, ~04:45–05:45)

**Auftrag (Johannes, vor dem Schlafen):** „PLANE 10 … während ich Träume, GO" + „Never stop
designing, denk an die Limits." Plan: [VERSION_10_PLAN.md](../VERSION_10_PLAN.md).

---

## ✅ Welle 1 — KOMPLETT integriert auf `feat/mykilos8-block-d-provisioning`

**879 Tests grün (von 848).** Jeder Block in isoliertem Worktree gebaut, unabhängig verifiziert
(build+test selbst gelaufen, nicht nur Bericht geglaubt), einzeln cherry-gepickt, nach jedem Pick
voller Test-Lauf.

| Block | Inhalt | Tests | Commit (block-d) |
|---|---|---|---|
| **A+B** | Per-User-Keychain (6 Services → `com.mykilos6.<service>.<userID>`, sanfte Migration, alte Einträge bleiben) + stabile First-Run-`userID` (GRDB v22) + Anti-Impersonation-Zeile im Assistenten-Prompt. Bonus-Bugfix: Wizard/Settings hätten `userID` bei jedem Save gelöscht. | +16 | `179ee89` |
| **C+D** | `WorkBasketStore` an `AppState` verdrahtet (kein toter Code mehr) + Migrations-Gate-Test (v20→v21 gegen Bestands-DB) + `WarenkorbWorkBasketBridge` (Intake-Korb → GRDB-WorkBasket, Cold-Start-bewiesen, Schneider-Testdaten). Läuft ZUSÄTZLICH zum Airtable-Pfad. | +7 | `6157bff` |
| **F** | `AngebotsRenderMapper`: WorkBasket → `MykPDFRenderer`-Args (Briefkopf, Positionstabelle, Netto/MwSt 19%/Brutto, de_DE-Format, Datum injizierbar, `A-<projektNummer>`-Nummer). | +8 | `f5cf95f` |

**Checkpoint:** Version `10.0.0-alpha1` gestempelt, DMG in `dist/` (Rückfälle: 9.0.0 + 8.8.0-SAFETY).
Ein Konflikt (GRDBDatabase: buildMigrator vs. v22) sauber von Hand gelöst.

## ✅ Welle 2 — KOMPLETT integriert auf `feat/mykilos8-block-d-provisioning` (2026-07-03, Nacht)

**894 Tests grün (von 879).** Direkt auf dem Zielbranch gebaut (kein isolierter Worktree),
jeder Block einzeln committet + nach jedem Block voller Testlauf grün. **Begründung der
Abweichung von „Worktree je Block + Cherry-Pick":** Die drei Blöcke teilen sich alle die
`ProjectDetailView`-Aufrufstellen (`.warenkorb`/`.offers`/`.cash`) — isolierte Cherry-Picks
hätten nur künstliche Konflikte auf einer Datei erzeugt. Direkt-Bau im kanonischen Ordner
(CLAUDE.md „Keine parallelen Worktrees") + volle Suite je Block wahrt den Prüf-Geist.

| Block | Inhalt | Tests | Commit (block-d) |
|---|---|---|---|
| **E** | WarenkorbWidget liest den lokal persistierten `WorkBasket` (GRDB) statt Airtable — EINE editierbare Quelle der Wahrheit. `WorkBasketEditing` (Kit, rein: Menge/Preis korrigieren, entfernen; nur `.kalkulation` editierbar) + `WorkBasketEditSheet` (roomy Panel, sichtbarer SaveState, persistiert via `WorkBasketStore.speichere`). `WorkBasket.vkNettoSumme` (Kit). | +7 | `575f98b` |
| **G** | „Zum Angebot"-Knopf im Angebote-Tab: WorkBasket → `AngebotsRenderMapper` → `MykPDFRenderer` → PDF **lokal** (`<App-Support>/mykilOS6/AngebotsVorschau/<projektNr>/`), sichtbar im Tab. **Beschriftete VORSCHAU** (belegfuehrung-extern-regel): Titel „Angebots-Vorschau" + Kopf-Hinweis + Fußzeile „Kalkulations-Vorschau — kein offizielles Angebot". Kein Drive/sevDesk-Write. `MykPDFRenderer` bekam additiven `footerNote:`. `AngebotsVorschauStore` (Basisordner injizierbar → Cold-Start-Test). | +5 | `ffaf2c5` |
| **H** | Cash-Widget: schlanke Zeile „Kalkuliert (Warenkorb): netto · brutto" aus `WorkBasket.vkNettoSumme` (19 % MwSt). Reine Sicht, kein Schreiben, sevDesk bleibt read-only. | +3 | `eb440a7` |

**Checkpoint:** Version `10.0.0-alpha2` (Build 20) gestempelt, DMG `dist/mykilOS-10.0.0-alpha2.dmg`
(12M, signiert). Rückfälle: 10.0.0-alpha1 · 9.0.0 · 8.8.0-SAFETY.

### Offen / bewusst NICHT nachts gemacht
- **Live-Abnahme (Phase 3, Block I — Schneider-Lauf):** ausschließlich Johannes' Gate. Alle
  UI-Blöcke sind Build+Test-grün, aber NICHT live gegen Screenshots abgenommen (P0-Drift-Lehre).
  Insbesondere prüfen: WarenkorbWidget + „Bearbeiten"-Sheet in der Übersicht/Angebote-Tab
  verschieben Sidebar/Layout nicht; „Zum Angebot" erzeugt sichtbar ein Vorschau-PDF; Cash-Zeile
  erscheint. Erst nach Live-OK: Block J (10.0.0 final stempeln).
- **Kein neuer externer Datenstrom:** Block E/G/H schreiben nur LOKAL (GRDB + App-Support-PDF).
  Kein neuer Airtable-Datenstrom-Handbuch-Eintrag nötig; externe Writes waren nachts korrekt gesperrt.
- **Datenquelle-Doppelung bewusst:** Der Airtable-`WarenkorbListeStore`/`CartStore`-Versandpfad
  (globaler Session-Warenkorb) bleibt unberührt; der Widget-Pfad ist jetzt der lokale WorkBasket.
  Eine spätere Verallgemeinerung/Zusammenführung (CartStore) bleibt Folgethema.

## ⏳ Welle 2 — ursprünglicher Auftrag (jetzt erledigt, Historie)

- ~~Block E / G / H~~ → oben integriert.
- **Phase 3 (Blocks I+J):** Schneider-Lauf live = **Johannes' Gate**, dann 10.0.0 final.

## 📌 Für Johannes (Morgen-Checkliste)

1. **Übergabe-Paket an Daniel:** Zip liegt in `dist/mykilOS-Uebergabe-V10.zip` → in **Drive** hochladen,
   Link in die Mail (Anhang wird von Gmail geblockt — live gesehen). Mail-Entwurf liegt bereit.
2. **1Password:** Tresor `mykilOS-Test Daniel` steht (3 Karten) → Anthropic-Key „Daniel-Test" in der
   Console erzeugen + einfügen, Tresor an Daniel teilen.
3. **Airtable manuell:** Datenstrom-Handbuch-Zeile `WORKBASKET_INTAKE_PERSIST` eintragen (Inhalt im
   Commit-Body von `6157bff`; externer Write war nachts korrekt gesperrt). + aiText-Felder in den 3
   neuen Bases löschen (Kostenfalle, IDs in ABNABELUNG_DANIEL_BASE.md §7).
4. **Re-Consent** irgendwann fällig (Tokens liegen noch unter Legacy-Keychain-Service, Migration
   findet sie weiter — kein Zwang, kein Bruch).

*Alle Regeln gehalten: kein Push, keine externen Writes, keine Notifikationen. Worktrees
`wt-v10-a/cd/f` können nach Welle 2 aufgeräumt werden.*
