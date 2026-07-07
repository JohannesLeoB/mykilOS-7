# ClickUp — Geerntete Grundwahrheit (read-only, Stand 2026-07-07)

**Zweck:** „Sauberes Vernetzen" mit der ClickUp-KI (läuft auf Opus 4.8, wird nach Go-Live abgestellt)
= NICHT KI-zu-KI-Chat (fragil, verdoppelt Erfindungsrisiko, verschwindet beim Go-Live), sondern die
**strukturierte Grundwahrheit, die die ClickUp-KI hinterlassen hat, jetzt deterministisch ernten**
und in unser Datenmodell + Airtable festzurren. Danach läuft mykilOS ohne jede ClickUp-KI-Abhängigkeit.

Alles hier ist **read-only** über den ClickUp-MCP geholt (`get_workspace_hierarchy`, `filter_tasks`).
Kein Write, keine Notifikation. Writes bleiben hinter dem Gate + Johannes-GO (siehe CLICKUP_IO_ARCHITEKTUR_PLAN.md).

---

## 1) Workspace-Struktur (6 Spaces)

| Space | ID | Rolle |
|---|---|---|
| STUDIO INTERN | 90127216635 | intern |
| SALES | 90127216858 | Lead-Pipeline |
| MARKETING | 90127216955 | Marketing |
| **PROJEKTE** | **90127216979** | **echte Produktivprojekte** (Ordner AKTIV 901210707834) |
| meinkilos | 90127395372 | ClickUp-Template-Demo (CRM etc.) |
| **MYKILOS API TESTSPACE** | **90128024109** | Sandbox (Ghost/Provisioning/Config) — **einzige Write-Zone bis Go-Live** |

## 2) Echte Produktiv-Listen-IDs → Airtable `ClickUp-Liste` (löst Plan-Entscheidung E1)

Space PROJEKTE / Ordner AKTIV (901210707834):

| ClickUp-Liste | Liste-ID | mykilOS-Projekt (Vermutung, zu bestätigen) |
|---|---|---|
| 2026_015_Hustadt_KOE66 | 901218617645 | 2026-015 Hustadt |
| 2025_001_Heimhuder8_HEI8 | 901217525046 | 2025-001 Heimhuder 8 |
| 2023_010_Fuckner_Huetter_HOF55 | 901217524954 | 2023-010 Fuckner/Hütter |
| 2025_014_BenjaminMartin_FUN16 | 901217525599 | 2025-014 Benjamin Martin |
| 2025_018_Rodewyk_FLO32 | 901217525468 | 2025-018 Rodewyk |
| 2026_017_JungeSchultzendorff_WRA51 | 901217525191 | 2026-017 Junge/Schultzendorff |
| 2025_021_Schneider_DWA27 | 901217525868 | 2025-021 Schneider |
| 2025_015_May_HEI64 | 901217525304 | 2025-015 May |
| 2024_021_Neuhaus_HOC32 | 901217538759 | 2024-021 Neuhaus |
| 2025_022_Wartenberg_ALS46 | 901218529081 | 2025-022 Wartenberg |
| 2026_AAA_TEMPLATE | 901217571650 | (Vorlage, kein echtes Projekt) |

→ **Datenernte statt Ratespiel:** Der ClickUp-Listenname trägt das mykilOS-Schema `JJJJ_NNN_Kunde_CODE`
bereits — ein deterministischer Parser (wie der Drive-Ordner-Parser) kann Liste→Projekt zuordnen und
die IDs ins Airtable-Feld `ClickUp-Liste` schreiben. **Sauberste Variante:** die ClickUp-KI trägt vor
Go-Live `mykilos_project_id` (s.u.) in jede Liste ein → dann ist die Zuordnung explizit, nicht geparst.

## 3) Projekt-Lebenszyklus-Modell mit Abhängigkeiten (Template `TEST_KUECHE_Vorlage_v2`, Liste 901219239199)

36 Aufgaben, phasiert P1–P10, mit Gate, Parallel-Zweigen und wiederverwendbaren Subflows. **Das ist die
Antwort auf „alle Abhängigkeiten definieren" — von der ClickUp-KI bereits domänengenau modelliert:**

- **P1 Lead/Onboarding:** P1.1 Lead qualifizieren → P1.2 Kontaktdaten+Adresse → P1.3 Kunde+Projektübersicht (Lead→Kitchen-Übergang)
- **P2 Aufnahme:** P2.1 Grob-Aufmaß → P2.2 Beratung vor Ort → P2.3 Wünsche/Stil dokumentieren
- **P3 Konzept:** P3.1 Geräteliste+Schätzpreis → P3.2 Moodboard-Varianten (≥2 parallel) → P3.3 Kundenfeedback (Revisionsschleife)
- **P4 Angebot:** P4.1 Tischlerangebote (Mehrfachvergleich) → P4.2 vergleichen+auswählen → P4.3 Angebot an Kunde
- **P5 GATE:** P5.1 Beauftragung/Freigabe durch Kunde (harter Gate-Task)
- **P6 Werksplanung:** P6.1 Werkzeichnung Tischler → P6.2 Finales Aufmaß → P6.3 Materialmuster+Kundenfreigabe
- **P7 Bestellung:** P7.1 Geräte, P7.2 Sonderanfertigungen (Stein/Metall/Arbeitsplatte), P7.3 Lieferort
- **P8 Fremdgewerke:** P8.1 Elektro (Blocker-Risiko!), P8.2 Sanitär, P8.3 Trockenbau/Maler-Schnittstelle
- **P9 Montage:** P9.1 Zeitfenster/Zugänglichkeit → P9.2 Montage → P9.3 QK/Mängel
- **P10 Abschluss:** P10.1 Schlussrechnung → P10.2 Übergabeprotokoll
- **Subflows:** „Anbieter 1/2/3 anfragen" (Mehrfachvergleich); **NACHTRAG-Subflow** (wiederverwendbar, jede Phase): 1 Wunsch/Änderung erfassen → 2 Preis/Angebot → 3 Kunde-GO → 4 Auftrag/AB aktualisieren → 5 Gewerk informieren

*Offen (nächster read-only Schritt):* die exakten Dependency-Kanten (blocking/waiting) je Task via
`get_task` ernten — die P-Nummerierung + „GATE"/„Blocker-Risiko"-Marker kodieren sie implizit schon.

## 4) Daten-Kontrakt: 10 Custom-Fields (Liste „Custom-Field-Wünsche" 901219238396)

Von der ClickUp-KI explizit als Konfigurations-Wunsch spezifiziert = **der geteilte Schema-Vertrag:**

| ClickUp-Feld | Typ | ↔ mykilOS |
|---|---|---|
| **mykilos_project_id** | short_text | **`Project.projectNumber` — JOIN-SCHLÜSSEL** |
| client_name | short_text | Kunde |
| project_phase | dropdown (Briefing/Planung/Angebot/Bestellung/Ausführung/Abschluss/Service) | `ClickUpProjektMeta.projectPhase` (dekodiert) |
| drive_folder_url | url | `Project.links.driveFolderID` |
| evidence_grade | dropdown (stark/mittel/schwach/konflikt) | KalkulationsEngine-Konfidenz-Ampel |
| review_required | checkbox | Review-Center |
| finance_relevant | checkbox | Cash/sevDesk |
| change_order_relevant | checkbox | Nachtrag/addendum |
| blocker_type | dropdown (intern/Kunde/Lieferant/Daten/Geld/Datei) | Abhängigkeits-/Blocker-Modell |
| source_system | dropdown (Slack/Drive/Airtable/myKilOS/manual) | `DataFlowLogger`-Quellen |

## 5) Weitere relevante Test-Listen

- `Go-Live-Freigaben` (901219238389) — Go-Live-Gate ist in ClickUp modelliert.
- `_TEST_PROVISIONING`-Ordner (901212093014): TEST_LICHT/NACHTRAG/ANGEBOT/KUECHE-Vorlagen → Provisioning-Templates.
- `01 Kundenprojekte`-Ordner: Testspace-Spiegel echter Projekte (Berger SON/FOL, Schneider, Wartenberg u.a.).

---

## Was das für die Vernetzung bedeutet (Fazit)

Die „andere KI" hat die Integration bereits als **deterministischen Vertrag** hinterlegt:
1. **Ein Join-Schlüssel** (`mykilos_project_id` ↔ `Project.projectNumber`).
2. **Ein Feld-Schema** (10 Fields, oben gemappt).
3. **Ein Lebenszyklus-/Abhängigkeits-Modell** (36-Task-Template P1–P10 + Nachtrag-Subflow).

**Sauberes Vernetzen = diese drei jetzt read-only ernten und festzurren** (Join-Schlüssel + Feld-Router
in `ClickUpProjektMeta`, Listen-IDs → Airtable, Lebenszyklus → unser Projekt-Phasen-Modell). Kein
Live-KI-Draht nötig; nach Go-Live (ClickUp-KI aus) läuft alles deterministisch weiter. Passt exakt zur
S0-Regel „kein Faktum ohne Beleg": Fakten kommen per Referenz aus der echten Quelle, nichts erfunden.

**Der einzige Schritt, der einen Write bräuchte** (unsere Rückfragen/Antworten für die ClickUp-KI in der
Config-Liste hinterlassen, ODER die Felder anlegen), bleibt hinter dem Write-Gate + Johannes-GO.
