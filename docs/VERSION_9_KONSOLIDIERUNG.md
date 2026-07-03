# mykilOS — Version 9: Konsolidierung & Recovery-Safe-Punkt

**Stand 2026-07-03 · Der Rundumblick nach der Marathon-Phase.**
Johannes: „Full stop. Rundumblick. Sammle, verstehe, verknüpfe die Fäden, sichere dich ab.
Konsolidiere und führe als Version 9 komplett und recovery-safe zusammen."

**Version 9 = Konsolidierungs-Meilenstein, kein Feature-Bündel.** Alles Verstandene + alles real
Verifizierte an einem Ort, plus ein sauberer, getesteter, gestempelter Rückfall-Punkt — dieselbe
Safe-State-Logik wie `v7.0.0`. Dieses Dokument ist der Einstieg für jede Folge-Session (löst das
teils veraltete HYPERBUILD.md als aktuellen Anker ab).

---

## 1. Verifizierter Ist-Stand (Ground Truth, read-only erhoben)

| Was | Stand |
|---|---|
| **Ausgeliefert** | `dist/mykilOS-8.8.0.dmg` (Jul 3, 01:28) — aktuell zum Skript |
| **Haupt-Branch** | `feat/mykilos8-block-d-provisioning`, HEAD `890a53f`, working tree **clean** |
| **Version im Skript** | `APP_VERSION=8.8.0`, `BUILD_VERSION=17` |
| **C3 WorkBasket** | Commit `a63f5c5` auf `feat/wirbelsaeule-c3` (Worktree `wt-wirbelsaeule-c3`), **verifiziert grün (848 Tests, +13)** — aber **NICHT in block-d** (`merge-base --is-ancestor` = NOT ancestor). Hängt isoliert. |
| **Abnabelung Phase 1** | Ziel-Schema in 3 mykilOS-Airtable-Bases live angelegt, alle IDs in `ABNABELUNG_DANIEL_BASE.md §7`. Keine Records, Daniels Base unberührt. |
| **Test-Kette** | 700 → 719 → 793 (Block D) → 835 (8.8.0/C2) → **848 (C3, im Worktree)**. Nach-C2/C3-Stand war bis jetzt nirgends als Ergebnis-Handoff dokumentiert. |

**Befund:** Heute (2026-07-03) wurde auf block-d fast nur **Doku/Backlog** committed. Der echte
Feature-Code C3 liegt fertig+grün, aber **uneingebaut** in seinem Worktree. Das ist der eine
mechanische Schritt, der Version 9 vom Wissens-Anker zum echten Artefakt macht.

---

## 2. Die großen Stränge — verknüpft (nicht als lose Liste)

Aus dem Backlog-Inventar (100+ Punkte) kristallisieren sich **8 Gravitationszentren**. Wichtig ist,
wie sie zusammenhängen — die meisten Einzelideen hängen an einem dieser Stränge:

1. **🦴 Wirbelsäule / Checkout-Pipeline** (`S10_WIRBELSAEULE.md`, `WARENKORB_CHECKOUT.md`)
   — das **Rückgrat**. C1 (Typen) + C2 (Ports) fertig, C3 (WorkBasket-Store) grün+uneingebaut.
   Daran hängen: Angebots-Positions-Picker, Dokumenten-Katalog, Moodboard, CAD/Vectorworks-Handoff,
   sevDesk-Postbox. **Offene Grundsatzfrage:** Rolling-Plan-Blöcke E/F/G einzeln vs. generisches
   Pipeline-Modell (IO-001…018). → blockiert alles Nachgelagerte.

2. **🗄️ Daten-Wahrheit: Abnabelung + Multi-Base v2** (`ABNABELUNG_DANIEL_BASE.md`)
   — mykilOS von Daniels Base lösen (Phase 1 Schema ✅) + 17 neue Domänen-Bases + Router-Tabelle.
   Löst zugleich den **Budget-Datenkonflikt** (zwei Quellen) und die **Projektnummer-Governance**.
   Der zweitgrößte Strang, Umfang ≥ Block C/D.

3. **🔒 Datenschutz / DSGVO** (Task #5) — Settings-UI + KI-Master-Switch + Datenexport (Art. 15/20)
   + Admin-2FA + Anti-Impersonation. **Rechtlich verpflichtend** und **gatet den ganzen Alerts-Strang**
   (jeder Alert braucht einen Datenschutz-Toggle). Größtes offenes *Design*-Thema.

4. **🔔 Zentraler Alerts-Strang** — 6–7 Einzel-Alerts (Kontakt anlegen, Zeichnungsstand, Nachfass,
   Rechnung bezahlt, Werkzeichnung, Ins-Drive-CTA) + altes „Benachrichtigungs-Zentrum". Muster erkannt:
   **einen zentralen Alerts-Kern bauen**, nicht 7 Einzel-Watcher. Wartet auf #3.

5. **🎯 Angebots-Positions-Extraktion (Flaggschiff)** — klick-getriebenes Picking auf PDF (kein
   Batch-OCR). „Der Beweis, dass die Wirbelsäule trägt." Mechanik geklärt, bewusst noch nicht gebaut;
   ~818 `position_candidates` evtl. wiederverwendbar; hängt an `importPDF`-Bestätigungsschicht.

6. **💰 Kosten-/API-Governance** — Airtable 100k Calls/Monat, 5/sec/Base (killte den 24-Parallel-Scan),
   aiText-Kostenfalle. Cheap-Wins benannt, nicht umgesetzt. Wird mit Multi-Base + mehr Pollern dringlicher.

7. **📄 Dokumente / Formulare-Ebene** (HTML→WKWebView→PDF entschieden) — operativer Layer, den
   sevDesk NICHT macht (Abnahmeprotokoll, Fragebogen, Geräteliste, Briefpapier). Überschneidet sich
   mit dem sevDesk-Briefpapier-Projekt → **Konsolidierungsbedarf** (drei Doku beschreiben teils dasselbe).

8. **🔗 Integrationen-Reife** — Google (Mail SENDEN, NO-GO aufgehoben, braucht Re-Consent), Clockodo
   (6-Schichten-Architektur live, Code offen), ClickUp (Ghost→Live, nur Testspace), sevDesk-Postbox.
   Jede braucht per-User-Isolation + einen Datenschutz-Toggle (→ hängt an #3).

**Vectorworks-Planköpfe (Port #17)** ist eine konkrete Ausprägung von Strang #1 (CAD-Handoff) — wartet
auf Johannes' Title-Block-Export, Erinnerung läuft für 2026-07-04.

---

## 3. Alt vs. neu — was steht, was ist frisch geworfen

- **Fertig/erledigt** (nicht mehr anfassen): CopyButton, WarenkorbWidget, ArtikelDetailSheet,
  Preisliste-Detail, Lebenszyklus-Stepper, Demo-Werte raus, `AirtableSyncService` weg, C1/C2-Ports.
- **Entschieden, Umsetzung offen:** HTML-Templates fürs Rendern, Kontakte-Widget aus Airtable,
  Mail-Versand erlaubt (Gate), Airtable-Core-Konsolidierung, Schätzpreis-Konfigurator-Richtung.
- **Frisch geworfen (diese Marathon-Phase), noch roh:** der ganze Alerts-Komplex, Datenschutz-Paket,
  sevDesk-Postbox-Regeln, Vectorworks-Planköpfe, Dokumenten-Katalog, per-User-Datenisolation,
  Kosten-Governance als Design-Kriterium.
- **Bewusst verworfen:** Assistent editiert eigene Codebase („zu dünnes Eis").

---

## 4. Widersprüche zu bereinigen (aus der Gedächtnis-Konsolidierung)

1. **`appkPzoEiI5eSMkNK`:** Tagesregel sagt **freigegeben** (Johannes 2026-07-03), aber die
   Nachtmodus-Memory listet sie noch als „nicht anfassen". → **Auflösung: freigegeben gilt.**
   Nachtmodus-Datei wird nachgezogen.
2. **Einzige geschützte Base = `appdxTeT6bhSBmwx5`** (Daniels): Lesen frei, seine Records nie ändern.
   Die ältere `artikel-projektliste-no-edit-rule` bleibt gültig (Projekte/Kunden-Tabellen), aber die
   neuere „Lesen frei"-Präzisierung führt.
3. **Versionszählung 6→7→8→9** ist nirgends erklärt. Festhalten: mykilOS-6 archiviert, origin=mykilOS-7,
   `v7.0.0` = Safe State; die 8.x-DMGs sind die laufende Entwicklungszählung; **9.0.0 = dieser
   Konsolidierungspunkt.** (Marketing-Version ≠ `BUILD_VERSION`.)
4. **Veraltete Einstiegs-Memories:** `project-current-state` (6.5.0/386 Tests) + `orchestrator-partner-role`
   Startbahn-Snapshot sind Historie — nur `version-9-konsolidierung` + `session-stand` gelten als Stand.

---

## 5. Der Version-9-Checkpoint (recovery-safe machen)

Der eine mechanische Schritt, der aus dem Wissens-Anker das Artefakt macht:

1. `a63f5c5` (C3, verifiziert grün) → **cherry-pick nach block-d** (kein Konflikt: 890a53f ist nur Doku).
2. Auf block-d: `swift build` + `swift test` **grün** (re-verifizieren, 848 erwartet).
3. Version `8.8.0` → **`9.0.0`** in `build_and_run.sh` + `create_dmg.sh` + Changelog.
4. **DMG bauen** (`MYKILOS_NO_LAUNCH=1`) → `dist/mykilOS-9.0.0.dmg`.
5. Commit. **NICHT** main/`v7.0.0` anfassen; ein `v9.0.0`-Tag nur nach Johannes' OK.

Danach: Datenstrom-Handbuch + Benutzerhandbuch + Gedächtnis nachziehen.

---

## 6. Wartet auf Johannes (nicht Claude-entscheidbar)

- **aiText-Felder** in den 3 neuen Airtable-Bases manuell löschen (Kostenfalle).
- **Brain-Follow-up-Prompt** pasten (restliche ~107 Felder, Merge über `mykilos_project_id`).
- **Vectorworks Title-Block-Export** in den Feedback-Ordner (Erinnerung: 2026-07-04 12:00).
- **Grundsatzentscheidung Strang #1:** Rolling-Plan E/F/G vs. generische Pipeline.
- **Datenschutz-Wording** (Task #5, dedizierte Session).

---

*Recovery-Anker im Gedächtnis: [[version-9-konsolidierung]]. Rails unverändert: main heilig, kein
Push ohne Freigabe, Sevdesk nur Postbox, Airtable kein Delete/`appdx` read-only, ClickUp nur Testspace.*
