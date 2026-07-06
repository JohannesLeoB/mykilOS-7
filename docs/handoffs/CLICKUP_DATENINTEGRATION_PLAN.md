# 📋 ClickUp-Datenintegration — Startplan (Johannes 2026-07-06)

**Ziel:** ClickUp-**Aufgaben, Fälligkeiten, Meilensteine, Projekt-Stati** UND die **Custom Fields**
aus dem Setup sinnvoll in mykilOS führen.

```
Regel:  Anzeige = read-only (unkritisch). Schreiben nach ClickUp = Testspace-only,
        Ghost-Persona, KI weist NIE zu. API-Limit 100k/Monat → cachen + dosiert pollen.
        Kontext der Erfassungs-Session am Limit → eigener frischer Bau-Strang.
```

## Was schon steht (Fundament)

- **`ClickUpTask`** (Domain): `id, name, status, dueDate, assignee, isUrgent` + Custom-Field
  `project_phase` (7-stufiges Drop-down, Testspace `90128024109`).
- **`ClickUpClient.tasks(listID:)`** liest Tasks einer Liste; `customFields` wird bereits generisch
  dekodiert (`CustomFieldEntity` name+value), aber nur `project_phase` ausgewertet.
- **`Project.clickUpListID`** — jedes Projekt trägt seine ClickUp-Liste.
- **`ProjectClickUpRef`**, **`ClickUpRouting`** (CU_PROJ_LIST/CU_PROJ_TASKS), **`TasksWidget`**.

## Die 13 Custom Fields aus dem Setup (`mykilos_clickup_build.json`) + Mapping

| ClickUp Custom Field | Typ | → mykilOS-Konzept | Stand |
|---|---|---|---|
| Budget (€) | Currency | Cash-Widget-Budget (siehe VISION_LOGIN_UND_DATENFLUSS Sevdesk-Budget) | verknüpfen |
| Angebotsdatum | Date | Timeline-Meilenstein | neu |
| Auftragsdatum | Date | Timeline-Meilenstein | neu |
| Nächstes Nachfassen | Date | Fälligkeit / Alert | neu |
| Drive-Ordner | URL | `Project.driveFolderID` | ✅ existiert → verknüpfen |
| Kunde | Relationship→Kontakte | `Project.customer` | ✅ existiert → verknüpfen |
| Kunde-Token | Text | interne Kunden-Referenz | neu |
| Projekttyp | Dropdown | `Project.kind` (Projektart) | ✅ existiert → mappen |
| Ort | Dropdown | Projekt-Metadatum | neu |
| Lead | People/Dropdown | Projekt-Verantwortlicher | neu |
| Lieferanten | Labels (multi) | Projekt-Metadaten (multi) | neu |
| Risiko/Engpass | Dropdown | Status-Signal / Alert | neu |
| Slack-Channel | Text/URL | Projekt-Link | neu |

**Space-Struktur** (aus dem Setup): ① Angebote · ② Aktive Projekte · ③ Service & Reklamation ·
④ Intern & Entwicklung. **Projekttyp-Optionen:** Vollprojekt (Privatküche) · Angebot/Pitch ·
Gewerbe/Großprojekt (B2B) · Service/Reklamation · Produkt/Gerät (Kleinauftrag) · Intern/Entwicklung.
**Automations A1–A7** (Lead-Nachfass, Engpass, Beschaffen, Abnahme, Schlussrechnung, Großauftrag,
Nachfass-Fälligkeit) — Kontext für die Alert-/Fälligkeits-Ableitung.

## Bau-Reihenfolge (klein, read-only zuerst)

1. **`ClickUpProjektMeta`-Struct** — die generisch dekodierten `custom_fields` in ein typisiertes
   Modell heben (13 Felder). Der Adapter liest `customFields` schon; nur das Auswerten erweitern.
2. **Spiegeln in bestehende Felder:** Drive-Ordner→`driveFolderID`, Kunde→`customer`,
   Projekttyp→`kind`, Budget→Cash-Widget. Read-only, kein Schreiben.
3. **Meilensteine:** `ClickUpTask` um `isMilestone` (ClickUp liefert `milestone: true`) +
   Angebots-/Auftragsdatum → Projekt-**Timeline**-Marker (Backlog „Timeline erkennt Meilensteine").
4. **Projekt-Status ableiten** — ✅ **ERLEDIGT, schon gebaut** (Korrektur 2026-07-06/07: dieser
   Punkt stand hier noch als offen, ist aber längst live): `ProjectLifecycleStage` (nutzergesetzter
   Stepper, `ProjectLifecycleStore`) + `ProjectLifecycleDeriver.derive(timeBookedHours:isArchived:)`
   als Startwert, solange der Nutzer nichts gesetzt hat. ClickUp-`project_phase`
   (`ClickUpClient.projectPhase(from:)`) läuft NUR als read-only Abweichungs-Hinweis
   ("ClickUp sagt: X") daneben — nie Auto-Write, der Nutzer tippt seine Stufe selbst.
   Siehe `Sources/MykilosApp/Detail/ProjectLifecycleBar.swift` + `ProjectLifecycleStoreTests.swift`.
5. **Fälligkeiten/Alerts:** `dueDate` + „Nächstes Nachfassen" + „Risiko/Engpass" → Signal-/Alert-Pfad
   (bestehendes Mediator-/Signal-System, nie schreibend).
6. **Caching/Polling** dosiert (API-Limit) — Muster wie `DriveOfferWatcher` (Poll + Baseline).

## Offen für Johannes
- Verknüpfung `clickUpListID` pro Projekt: aus Airtable (M3) oder Provisioning — muss gesetzt sein.
