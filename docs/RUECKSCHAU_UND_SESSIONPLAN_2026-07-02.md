# mykilOS — Offene-Punkte-Register, Session-Plan & Vision-Check

Stand: 2026-07-02 · Branch `feat/mykilos8-block-d-provisioning` · Quelle: Repo-Audit (Backlog, Gates/HYPERBUILD, aktive Handoffs, Code-Schulden, Git) + Best-in-Class-Lückenanalyse + verbale Session-Wünsche. Erzeugt via Multi-Agent-Rückschau (6 Auditoren → Opus-Synthese).

**Kennzahlen:** 123 offene Punkte · 20 Feature-Lücken · 13 geplante Sessions · 9 verbale Wünsche waren noch nicht sauber im Backlog verankert (jetzt nachgetragen).

---

## (a) Offene-Punkte-Register (dedupliziert, nach Kategorie)

### 🔴 Bugs & Technische Schulden

| Prio | Punkt | Quelle |
|---|---|---|
| P1 | **Keychain-Bug: `baseID`-Feld enthält PAT statt Airtable-Base-ID** → Airtable-Sync schlägt still fehl. Fix: Validierung (`baseID` muss mit `app` beginnen) + klare Fehlermeldung. Teilweise via `AirtableError.invalidBaseID` (S17) adressiert, Live-Datenkorruption bleibt. | Backlog „Security & Onboarding"; MEMORY airtable-keychain-bug |
| P1 | **Budget hat zwei parallele Quellen** (`Project.links.budget` vs. `ExternalMappingRegistry.business.budget`). CashWidget auf Registry umstellen, `links.budget` als Fallback/entfernen. | Backlog „Architektur & Datenfluss" |
| P2 | **Test-Sandbox-UI `ProvisioningTestView` nach Block-D-Live-Abnahme entfernen** (aktuell bewusst aktiv für M3-Test). Blockiert PR gegen main. | HYPERBUILD §6 |
| P3 | Airtable-MCP-Connector ohne Record-Write → PAT/curl-Workaround bleibt (unkritisch). | Backlog |
| P3 | Native Airtable-Automationen bewusst nicht gebaut, nur als Rezepte dokumentiert (Doppel-Projektnummer-Warnung). | AIRTABLE_OEKOSYSTEM_ARCHITEKTUR |

### 🟡 Unfertige Features

| Prio | Punkt | Quelle |
|---|---|---|
| P1 | **Universeller Warenkorb + CheckoutTarget-Router** (Wirbelsäule mykilOS 8): Picks aus jeder Datenmatrix → beliebige Ziele. Generische `DataObject→WorkBasket→CheckoutRun→Preview→Review→Audit`-Pipeline. **Grundsatzentscheidung offen.** | WARENKORB_CHECKOUT.md; Backlog |
| P1 | **Clockodo Zuhörer — Smart Time Logger** (NLP-Zeitbuchung aus Chat). 3 Design-Entscheidungen offen. Schema live, Code fehlt. | Backlog; HANDOFF_LIVE_WIRING_4 |
| P1 | **Assistent-Ausbau: voller Such-/Schreib-Zugriff** (Mail/Kalender/Drive/Notizen/Clockodo/Kontakte/Bilder/Angebote). Offen: Google-Scope-Erweiterung Mail/Kalender-Write. | Backlog; ASSISTANT_CAPABILITIES_PLAN |
| P1 | **User-Identität nach Google-Login sichtbar** (Name/Mail/Avatar). Teil via S17/Phase A, Avatar/Editierbarkeit offen. | Backlog |
| P2 | Artikel-Anreicherung (Links/Dokumente/Bilder/Montage/CAD) fehlt in Airtable-Artikel-Tabelle. Als Pick-Snapshot-Felder nötig. | WARENKORB_CHECKOUT |
| P2 | Geräteliste-an-Tischler / Geräte-Checkout-Dokument (Briefpapier-PDF/Tabelle ins Projekt). | WARENKORB_CHECKOUT §4 |
| P2 | Assistent als vollständige Kontakt-/Beziehungsintelligenz (371 Kontakte ohne Mail). | Backlog |
| P2 | Zeichnungen-Tab mit PDF-Vorschau (QuickLook/PDFKit). | Backlog |
| P2 | Material-Tab (einfache Dateiliste analog Angebote-Tab). | Backlog |
| P2 | Timeline-Tab Phase 2: ClickUp-Aufgaben mit Fälligkeit einblenden. | Backlog |
| P2 | ClickUp als Quelle für `ProjectKind` (Feld + Sandbox 90128024109 vorhanden). | Backlog |
| P2 | **`WidgetKind.kalkulation` ist im Board-Dispatch tot** (`default: EmptyView` in ProjectDetailView + HomeBoardView) — Kind existiert, hat aber keine View. Entweder Widget bauen oder Kind entfernen. | Code-Audit: ProjectDetailView.swift, HomeBoardView.swift |

### 💡 Ideen & Wünsche

| Prio | Punkt | Quelle |
|---|---|---|
| P1 | SQLite-Backup / Archiv-Log für GRDB (täglicher Snapshot, max. 30, Restore in Settings). Bei DB-Verlust ist der Audit-Log weg. | Backlog |
| P2 | Formulare-Ebene (gebrandete Firmendokumente → Projekt-Drive-PDF). | Backlog; FORMULARE_EBENE |
| P2 | Airtable-Core-Konsolidierung (`mykilOS_Core` als Master, Artikel-Base entkoppeln). | Backlog; AIRTABLE_ARCHITEKTUR |
| P2 | Multi-Base-Architektur v2 + zentrale Datenweichen-Router-Tabelle. | Backlog |
| P2 | Kunden-Adressmodell (Customer + Adresse ans Projekt) — Voraussetzung Maps-Widget. | Backlog |
| P2 | Onboarding-Flow (Erste-Schritte-Checkliste). | Backlog |
| P2 | Crash-Reporting (lokales Fehlerprotokoll + Settings-Button, opt-in). | Backlog |
| P3 | Herstellerbilder-/Bild-Assetkatalog für Moodboards. | Backlog |
| P3 | Webhook-basierter Airtable-Push (Relay-Server) statt Polling. | Backlog |
| P3 | Cache-Management (TTL, „Cache leeren"-Button, Offline-Indikator). | Backlog |
| P3 | Archiv-Übersetzungsregistry für `_PROJEKTE_ARCHIV` (~200 Ordner, altes Schema). | Backlog |
| P3 | Intelligente Alerts-Logik auf Airtable-Basis. | Backlog |
| P3 | 3 geparkte Erkundungs-Sessions — Start an Johannes-Freigabe gebunden. | Backlog; MEMORY geplante-nebensessions |

### ✅ Offene Abnahmen & manuelle Aktionen

| Prio | Punkt | Quelle |
|---|---|---|
| P0 | **Hustadt-Gate + Block-D-Sandbox-Test** — Live-Abnahme. Einziger verbleibender Schritt für Block A–D — kein Code mehr. | HYPERBUILD §4/§5/§6 |
| P0 | **P0-HARD-GATE: Projekt-„Übersicht" überlagert Sidebar** — Live-Abnahme mit 3 Projekten ausstehend. Fix committed, nicht live abgenommen. | CLAUDE.md P0-Block |
| P0 | **M1** Airtable Base-ID verifizieren · **M2** Google Re-Consent (drive.file, contacts, gmail.compose). Nur Johannes. | HYPERBUILD §6 |
| P1 | **M3** ClickUp-Listen-IDs → schaltet B5 live. **M4** sevdeskRef + Budget → schaltet B6 live. | HYPERBUILD §6 |
| P1 | Live-Test Block D Provisioning mit Johannes (Sandbox-Ziele, `writableMap`, Idempotenz-Doppelklick). | HYPERBUILD §6 |
| P2 | **M5** Clockodo-Stundensätze in Airtable (leer; blockiert Kostenboden NICHT). · **M6** Alt-PAT revoken. | HYPERBUILD §6 |
| P2 | Artikel-Base „Projekte" hat kein Projektnummer-Feld (Daniel muss anlegen; kein Fuzzy-Match). | Backlog; MEMORY artikel-projektliste-no-edit |
| P2 | Intake — Daniel-DB-Zuordnung: 6/11 Records offen (sichtbare Warnung, nie Auto-Match). | AIRTABLE_OEKOSYSTEM_ARCHITEKTUR |
| P3 | **M7** Projektordner-Rename `2026_20 → 2026_020` + Backup-Base-Tabellenname verifizieren. | HYPERBUILD §6 |
| P3 | Google Desktop-App OAuth `client_secret` evtl. nötig. · „Nie verbunden" vs. „Sitzung abgelaufen" nicht unterschieden. | Backlog |
| P3 | Font-Embedding: Monument-Grotesk wartet auf Dinamo-Lizenzklärung. | Backlog; brand/README |

### 🏛️ Offene Grundsatzentscheidungen (blockieren Bau)

| Prio | Punkt | Quelle |
|---|---|---|
| P1 | **Rolling-Plan E/F/G einzeln VS. generisches WorkBasket/Checkout-Pipeline-Modell.** Branch `handoff/workbasket-checkout-architecture-2026-07-01` liegt bis Entscheidung. | Backlog; HYPERBUILD §5/§6 |
| P2 | Partner-App Kalkulation: Ownership steht, WO/WIE gebaut nicht. | Backlog |
| P2 | „Drive-Ordner anlegen"-Automatisierung = erster echter Drive-Write (aktuell read-only NO-GO) — Klärung zwingend. | Backlog |

### 📄 Doku-Drift

| Prio | Punkt | Quelle |
|---|---|---|
| P2 | P0-Sidebar-Gate: CLAUDE.md „offen" vs. HYPERBUILD „✅ erledigt" — vor 8.0-Tag gegenchecken. | CLAUDE.md vs. HYPERBUILD |
| P3 | „Nächste Schritte"-Abschnitt in CLAUDE.md veraltet (referenziert S18), nicht entfernt; M1–M4 redundant zu HYPERBUILD §6. | CLAUDE.md |

### 🗑️ Toter/aufräumbarer Code

| Prio | Punkt | Quelle |
|---|---|---|
| P2 | `ProvisioningTestView` (Sandbox-UI) nach Abnahme entfernen. | HYPERBUILD §6 |
| P2 | `WidgetKind.kalkulation` ohne View im Dispatch (siehe unfertige Features). | Code-Audit |
| — | Datenhygiene-Regel: bei Kalkulations-Entkopplung → Kalkulations-Widget als Kandidat prüfen. | MEMORY data-hygiene-rule |

### 🔀 Git / Release

| Prio | Punkt | Quelle |
|---|---|---|
| P0 | **83 Commits auf `feat/mykilos8-block-d-provisioning` unmerged, kein PR offen.** main steht auf 7.7.2 (`d36063c`). Merge/PR erst nach S1-Live-Abnahme. | git `main...feat/mykilos8-block-d-provisioning` |

---

## (b) Nicht erfasste / noch offene Nutzerwünsche

Diese verbalen Wünsche waren **nicht sauber im Backlog verankert** — jetzt in `IDEEN_UND_BACKLOG.md` nachgetragen:

1. **Grundriss-/Skizzen-Zeichentool im Fragebogen (Canvas) → Drive-Export** — war nirgends erfasst.
2. **Projekt-Hero-Bild editierbar (Upload je Nutzer)** — nur indirekt über Avatar gestreift.
3. **Teamkalender-Widget in Projekt-Übersicht (farbcodiert, editierbar)** — nicht erfasst, braucht Kalender-Schreibpfad.
4. **Upload-/Anhang-Icon im Chat-Composer schöner/echter Anhang-Button** — nicht erfasst (Multi-Datei-Drop selbst ist erledigt).
5. **Kontakte-Widget klickbar/editierbar → Airtable als Quelle** (Google→Airtable-Import + Dubletten-Check) — Migrationspfad nicht im Register.
6. **ClickUp-Schreib-/Signal-Integration** (Tasks aus mykilOS anlegen/ändern, alarmieren, terminieren-Toggle, Signal-Kanal) — nur als ProjectKind-Quelle erfasst, nicht als Schreibsession.
7. **Dubletten-Zusammenführung realer Projekte** (Vinahl+Uetersen = EIN Projekt) mit Nummernkreis-Warnung — nicht als konkreter Task.
8. **Meilenstein-Statusbar mit Monatsangaben** im Hero/als Widget — Lebenszyklus-Stepper erledigt, aber die Datums-/Monats-Variante nicht.
9. **Mail SENDEN + Nachrichten-Aktionen** (gelesen/Stern/Archiv) — NO-GO in MEMORY aufgehoben, aber nicht als geplante Session verankert (→ S3).

---

## (c) Priorisierter Session-Plan

| # | Session | Ziel | Modell | Level | Abhängigkeiten | Größe | Prio | int/ext |
|---|---|---|---|---|---|---|---|---|
| S1 | **Live-Abnahme A–D + P0-Gates + Doku-Sync** | Hustadt-Gate, P0-Sidebar, Block-D-Sandbox live abnehmen; ProvisioningTestView entfernen; Doku-Drift; PR gegen main | opus | high | M1, M2, Johannes live | M | **P0** | intern |
| S2 | **Stabilitäts-Fundament** | Keychain-baseID-Validierung, Budget-Single-Source, GRDB-Backup/Restore (30 Snapshots, Settings) | opus | high | — | M | **P1** | intern |
| S3 | **Assistent Schreib-Ausbau + Mail-Vollversand** | Google-Scopes (gmail.send/compose, calendar.write, contacts), Mail SENDEN + Aktionen, Kalender-Write — je Karte→Bestätigung→Audit | opus | high | M2 Re-Consent | L | **P1** | intern |
| S4 | **Clockodo Zuhörer (Smart Time Logger)** | NLP-Zeitbuchung aus Chat → Draft → Wochenabschluss → POST; 3 Design-Fragen; Private-Area-Scoping | opus | high | Schema live, S3-Muster | XL | **P1** | intern |
| S5 | **Command Palette (⌘K) + Global Search + Gallery-Views** | ⌘K Fuzzy-Jump; quellfarbige Ergebnisseite; gespeicherte gefilterte Galerie-Views | sonnet | high | — | L | **P1** | intern |
| S6 | **Pipeline-Board + Forecast** | Kanban über 31 Projekte (drag-to-advance, Stage aus ClickUp/Airtable, Status→Audit); Deal-Value×Wahrscheinlichkeit → Monatsforecast | sonnet | high | ClickUp-ProjectKind (M3) | L | **P1** | intern |
| S7 | **Projektdetail-Tabs füllen** | Zeichnungen (PDF-Vorschau), Material (Liste), Timeline Phase 2 (ClickUp-Fälligkeit), projektgebundene Mail-Threads | sonnet | medium | M3, Gmail-Tool | L | **P2** | intern |
| S8 | **Moodboard-/Formulare-Ebene v1** | Board-Tile-Widget (Drive-Bilder + Artikel-Fotos, Drag) + gebrandete PDF-Export-Pipeline ins Projekt-Drive | opus | high | S10, Font-Lizenz, Adressmodell | XL | **P2** | intern |
| S9 | **Kunden-Adressmodell + Maps-Widget + Hero-Bild** | Adressfelder ans Projekt; Google-Maps-Widget; editierbares Hero-Bild + Avatar; Meilenstein-Statusbar (Monate) | sonnet | medium | Adressmodell (in Session) | M | **P2** | intern |
| S10 | **WorkBasket/Checkout-Grundsatzentscheidung** (Architektur-Spike) | E/F/G-einzeln vs. generische Pipeline; Merge-Ziel `handoff/workbasket`-Branch; ADR | opus | high | — (blockiert S8) | S | **P1** | intern |
| S11 | **Onboarding + Crash-Reporting + Cache-Mgmt** | Erste-Schritte-Checkliste, lokales Fehlerprotokoll (opt-in), TTL/Cache-leeren, Offline-Indikator | sonnet | medium | — | M | **P2** | intern |
| S12 | **Slack→ClickUp-Status verifizieren** (Recherche) | Hintergrund-Agent-Status prüfen (nicht verifiziert!); Bericht + Empfehlung, kein Bau | haiku | low | — | S | **P2** | **extern** |
| S13 | **Geparkte Erkundungen** (auf Johannes-Ansage) | Gerätelisten-Expand / Schätzpreis-Konfig / ClickUp-aus-Slack — je isolierte Branch-Session | sonnet | medium | Johannes-Freigabe | M | **P3** | **extern** |

> **Nachgetragen (Johannes 2026-07-02, „hinten anstellen"):** **S3.5 — ClickUp live in die App + Ghost Johannes hot schalten.** Ghost→Real NUR für Johannes; die anderen vier bleiben Ghosts (sonst echte Notifikationen an reale Personen). Läuft nach S1/S2 und der Eiserne-Regel-Abstimmung. Berührt direkt Wunsch #6 oben.

---

## (d) Vision-Check — sind wir auf Kurs?

**Kurz: ja im Fundament, nein in der Oberfläche.**

**Was steht (stark):** Das Nervensystem ist da — Signal→Karte→Bestätigung→Audit, GRDB-Persistenz mit Cold-Start-Disziplin, Design-Tokens/Quellfarben, echte Integrationen (Drive/Kalender/Mail/Kontakte/Airtable/ClickUp/Sevdesk/Clockodo/Claude), Kalkulations-Engine portiert und live, Safe State gesichert. Solides, seltenes Fundament.

**Was fehlt zum „nie mehr raus"-Cockpit — die harten Wahrheiten:**

1. **Zu viel ist „code-fertig, nicht live abgenommen".** Block A–D, P0-Sidebar, B5/B6 — hängt an M1–M4 und Live-Checks, die nur Johannes machen kann. **Das ist der Engpass, nicht fehlender Code.** S1 zuerst, sonst plant man auf Sand.
2. **Der Assistent kann lesen, aber kaum handeln.** Ein Cockpit, das man nicht verlässt, muss DINGE TUN — Mail senden, Termine schreiben, Zeit buchen. Aktuell: Entwürfe und Vorschläge. Größter Abstand zum Versprechen (S3/S4).
3. **Keine visuelle Ebene.** Für ein Küchen-/Interior-Studio der eklatanteste Gap: kein Moodboard, kein Board-View, keine gebrandeten Präsentations-PDFs. Genau hier gehen Nutzer heute raus (Milanote/PowerPoint/InDesign). S8 ist strategisch das wertvollste neue Modul.
4. **Keine Vogelperspektive.** 31 Projekte in flacher Galerie, kein Pipeline-Board, kein Forecast, kein ⌘K. Das „trickreiche, schnelle" Versprechen ist nicht eingelöst (S5/S6).
5. **Resilienz-Lücke.** Kein DB-Backup — bei Korruption ist der Audit-Log weg. Für local-first mit Geschäftsdaten ein stilles P1-Risiko (S2).
6. **Architektur-Weggabelung ungelöst.** Die WorkBasket/Checkout-Entscheidung blockiert die sauberste Version von Warenkorb, Moodboard, Geräteliste und Checkout gleichzeitig (S10 vor S8).

**Fazit:** Auf Kurs, aber der Schwerpunkt muss von „mehr Integrationen anschließen" zu **abnehmen → handlungsfähig machen → sichtbar/visuell machen** wechseln. Reihenfolge **S1→S2→S10→(S3/S5)→S8** ist der ehrlichste Weg zum polierten all-day Cockpit.

---

## (e) Top-Feature-Empfehlungen (aus Best-in-Class-Vergleich)

1. **Command Palette ⌘K** (M, → S5) — billig auf bestehenden Registries, riesiger gefühlter Speed. Direkt auf Vision-Kern „trickreich, schnell".
2. **Visual Moodboard / Material Board per Projekt** (XL, → S8) — größter „sie verlassen die App"-Gap für ein Design-Studio. Board-Tiles + PDF-Export, passt zu Farbe-ist-Sprache. Wichtigste Neuentwicklung. *(Morpholio Board / Programa / DesignFiles)*
3. **Pipeline-/Kanban-Board mit Drag-to-Advance** (M, → S6) — Daten existieren. Ersetzt den Sprung nach Pipedrive/ClickUp. *(ClickUp/Monday/Pipedrive)*
4. **Product/Finish Spec Schedule (Ausstattungsliste) + Geräteliste-an-Tischler** (M, → S8) — kompiliert aus vorhandenen Warenkorb-/Katalogdaten, keine Neueingabe. Entfernt den InDesign/Excel-Umweg fürs Kern-Deliverable. *(2020/Houzz Pro)*
5. **Projekt-gebundene Mail-Threads** (M, → S7) — baut auf Gmail-Tool-Use; macht aus Viewer ein CRM-Cockpit.
6. **Per-Projekt Budget-vs-Actual Margin Tracker** (M, → S6/S8) — Kalkulation + Sevdesk-Ist + Sale-Price → Live-Marge. Löst nebenbei den Budget-Doppelquellen-Bug.
7. **Reusable Templates (Projekt/Task/Warenkorb)** (M, → S9/S8) — „Standard-Küche mittlere Ausstattung" spinnt Ordner + Checkliste + Starter-Warenkorb auf. Kodiert den Studio-Prozess.
8. **Saved Views / Filter auf der Galerie** (M, → S5) — mit 31 aktiven + 200 archivierten Projekten skaliert eine flache Galerie nicht.

**Bewusst nachrangig (L, später):** Client-Portal/Approval-Link, Timeline-Gantt mit Lead-Time-Engine, PO-/Bestell-Tracker, Aufmaß-Erfassung, Rules-Engine, Beratungsprotokoll-Extraktion — hoher Wert, größerer Aufwand, teils abhängig von S8/S10.
