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

## ⏳ Welle 2 — noch offen (nächste Session / nach Limit-Reset)

- **Block E:** WarenkorbWidget/-Panel vom Airtable-`WarenkorbListeStore` auf den persistierten
  WorkBasket umhängen (eine Quelle der Wahrheit), editierbar, Renderstates, Screenshot-Check.
- **Block G:** „Zum Angebot"-Knopf (WorkBasket → Mapper → PDF lokal + Angebote-Tab). Killer-Moment.
- **Block H:** Cash-Zeile „kalkuliert/offen" aus dem WorkBasket.
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
