# Master-Orchestrierung · mykilOS 7/8 ⇄ ClickUp

*Single Source of Truth für das Gesamtsystem. Konsolidiert und ersetzt die verstreuten Vorab-Pläne (ClickUp-Setup, Routinen, UI-Integration, Architektur-Reconciliation). Geprüft gegen `mykilos_clickup_build.json` + `mykilos_project_routines.json` am 29.06.2026. Orchestriert von der Analyse-Session.*

---

## A · Abgleich-Verdikt
Die UI-Integration stimmt im Kern mit dem ClickUp-Bauplan überein. Drei Punkte ziehe ich hier verbindlich fest:

1. **Status ↔ Phase ist eine Mapping-Schicht.** Das 11-Phasen-Rail in der App ist eine Präsentation über ClickUps zwei ordner-bezogene Status-Sets (① früh, ② spät, ③ Service separat). Mapping-Tabelle in Abschnitt B.
2. **Routine ≠ Aufgaben.** Routine = ClickUp-**Checkliste** (Template-Skelett). Nächste Schritte = ClickUp-**Subtasks** (zugewiesen, fällig). Korrigiert die lose Formulierung „subtasks = routine" im `build.json`.
3. **Realität: ClickUp ist noch nicht befüllt.** Es gibt keine laufende Befüllung. Die UI-Integration setzt einen befüllten Stand voraus → „aufstellen + befüllen" steht jetzt vorne (Phase 1).

---

## B · Das validierte kanonische Modell (der Vertrag für alle drei Akteure)

**Identität.** `Kdnr` = kanonischer Kunden-Schlüssel · `kunde`-Token = menschenlesbarer Slug · Projekt-/Angebotsnummer (`YYYY-MM-NNNN`) = Projekt-Schlüssel · Nachträge via `parentProjectNumber`. Beide ersten sind kunden-, der dritte ist projekteindeutig.

**Status ↔ Phase (App-Rail ← ClickUp-Status).**
| Rail | App-Phase | ClickUp-Status (Ordner) |
|---|---|---|
| 1 | Anfrage/Lead | ① Neu, ① Qualifiziert |
| 2 | Termin/Aufmaß | ① Aufmaß |
| 3 | Planung/Entwurf | ① Planung/Entwurf |
| 4 | Angebot/Kalkul. | ① Angebot raus, ① Nachfassen |
| → | *Gewinn* | ① ✅ Gewonnen → Task wandert nach ② |
| ✗ | *verloren* | ① ❌ Verloren (terminal, vom Rail genommen) |
| 5 | Auftrag/Freigabe | ② Auftrag/Freigabe |
| 6 | Bestellung | ② Bestellung |
| 7 | Produktion | ② Produktion |
| 8 | Lieferung | ② Lieferung |
| 9 | Montage | ② Montage |
| 10 | Abnahme/Übergabe | ② Abnahme/Übergabe |
| 11 | Rechnung/Zahlung | ② Rechnung/Zahlung |
| ✓ | *abgeschlossen* | ② Abgeschlossen (terminal, Rail voll) |
| ‖ | Service (parallel) | ③ (eigener Lebenszyklus, als Service-Badge separat, nicht auf dem Haupt-Rail) |

**Arbeitsobjekte.** Projekt = ClickUp-Task. Routine = Checkliste am Task (aus Template). Aufgaben = Subtasks (Assignee, Fälligkeit, Status); eine Subtask kann auf den Routine-Schritt verweisen, den sie erfüllt.

**Farbsprache.** Aufgaben/ClickUp = Ochre · Dateien = Terrakotta · Geld = Indigo · Menschen = Sage · Notizen = Plum · Risiko = Coral (sparsam).

**Schreib-Disziplin.** Lesen inline (immer sichtbar), Schreiben per Karte → Bestätigung → Audit. Kein stiller externer Write. ClickUp ist damit **keine** Read-Write-Ausnahme, sondern nutzt das bestehende v7-Muster.

---

## C · Die Orchestrierung — Ende zu Ende

Drei Akteure: **Johannes** (Policy-Entscheidungen, UI-Scaffold-Klicks, Freigaben) · **Analyse-Session / ich** (Connector-Jobs, Validierung, Spec-Pflege) · **Code-Session / die App** (Read-Aggregation, UI, später bestätigte Writes).

| Phase | Was | Akteur | Gate |
|---|---|---|---|
| **0 · Fundament** | Dieses Modell als Spec festziehen (Mapping, Identität, Checklist/Subtask). | alle | — |
| **1a · Scaffold** | Space, 4 Ordner + Status-Sets, 13 Felder, 6 Templates, 8 Automationen, Dashboard (UI-Anleitung). | Johannes | — |
| **1b · Befüllen** | 169 Projekte → Tasks: Status gemappt, Felder + Routine-Checkliste vorbefüllt. Lücken-Report. | ich (Connector) | Freigabe je Job |
| **2 · App liest** | mykilOS rendert die UI-Integration (Projekt-Rail, Routine-/Aufgaben-Widget, Gallery-Chips, Pipeline, Today-Fokus) über den befüllten Stand. | Code-Session | — |
| **3 · App bedient** | Aktions-Karten: Status setzen, Schritt abhaken, Aufgabe zuweisen, Nachfass-Datum. Werfend + bestätigt + auditiert. | Code-Session | **Johannes' OK nötig** |
| **4 · Betrieb** | Neues Projekt in mykilOS → provisioniert ClickUp-Task (bestätigt). Engpass-Intelligenz, Lieferanten-Qualität, Geld-Loop. | alle | Gate aus Phase 3 |

**Wichtig zu den Gates:** Phasen 1–2 brauchen den Write-Gate **nicht**. Das Befüllen (1b) läuft über mich per Connector mit Einzelfreigabe — das ist **kein** App-Schreibpfad. Erst Phase 3 (die App schreibt selbst) verlangt Johannes' grundsätzliches OK.

---

## D · Validierungs-/Prüfschicht (das „prüfen und validieren")
- **Mapping-Tabelle als Vertrag** — jede ClickUp-Statusänderung muss eindeutig auf genau eine Rail-Position fallen; unmappbare Status sind ein Fehler.
- **Lücken-Report beim Befüllen** — welche Projekte ohne Kdnr, ohne Kontakt-Match, ohne Drive-Ordner.
- **Pilot vor Bulk** — erst 5 Projekte seeden, Johannes prüft Status/Felder/keine Duplikate, dann die restlichen 164.
- **Reconciliation-Check** — für eine Stichprobe muss gelten: App-Sicht == ClickUp-Wahrheit == Registry.
- **Idempotenz** — Seed/Provisioning re-runnable ohne Duplikate (Schlüssel: Kdnr + Projektnummer).
- **Audit-Log als Write-Nachweis** — jede Mutation nachvollziehbar; in Phase 3 vor Ausweitung einmal end-to-end geprüft.

---

## E · Offene Entscheidung (markiert)
**Der Write-Gate (Phase 3).** Bis zu Johannes' explizitem OK schreibt die App nicht selbst. Alles bis Phase 2 (aufstellen, befüllen, lesen, gesamte UI-Integration im Lese-Modus) läuft ohne diese Freigabe.

---

## F · Was ich als Orchestrator übernehme
- Halte dieses kanonische Modell aktuell — es ist die einzige Quelle der Wahrheit; alle Schärfungen laufen hier zusammen.
- Fahre die Connector-Jobs (Befüllen, Mapping-Validierung) mit deiner Freigabe und liefere den Lücken-Report.
- Gebe der Code-Session die Spec (Mapping-Tabelle, Identität, Checklist/Subtask-Regel) und prüfe ihre Rückfragen.
- Validiere jede Phase, bevor die nächste startet — Pilot vor Bulk, Reconciliation vor „grün".

*Nächster konkreter Schritt: Phase 1a (du, Scaffold per Anleitung) — danach starte ich 1b mit einem 5er-Pilot zur Validierung. Der Write-Gate (Phase 3) wartet auf dein OK.*
