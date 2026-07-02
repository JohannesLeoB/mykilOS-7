# Admin-Blocker: ClickUp Custom Fields nicht per Connector anlegbar

**Erstellt: 2026-07-02.** Gemäß `HANDOFF_CODING_AGENT_MYKILOS8_CLICKUP_STUDIO_OS.md` §7.5:
„Wenn Custom Fields per Connector/API nicht anlegbar sind, muss der Agent eine
`ADMIN_REQUIRED_CUSTOM_FIELDS.md` erzeugen."

## Befund

Der verfügbare ClickUp-MCP-Connector kann Custom-Field-**Definitionen** nur LESEN
(`clickup_get_custom_fields`), aber nicht ANLEGEN. Es gibt keinen `create_custom_field`-artigen
Tool-Aufruf. Aktuell hat der Testspace ("MYKILOS API TESTSPACE", `90128024109`) nur 2 Custom
Fields (auf Space-Ebene, geerbt an alle Listen): `Drive-Ordner anlegen` (checkbox),
`Angebotsadresse Ort` (short_text).

## Fehlende Felder (aus Handoff §7.5, empfohlen für die Studio-OS-Rollout)

| Feld | Typ | Zweck |
|---|---|---|
| `mykilos_project_id` | short_text | Stabile Rückverfolgung App ↔ ClickUp |
| `client_name` | short_text | Kundenbezug direkt auf dem Task sichtbar |
| `project_phase` | dropdown | Phase (Briefing/Planung/Angebot/Ausführung/Abschluss/Service) |
| `drive_folder_url` | url | Direktlink zur Projektakte |
| `evidence_grade` | dropdown | stark/mittel/schwach/konflikt (für Slack-Process-Mining-Funde) |
| `review_required` | checkbox | Review-Gate sichtbar auf dem Task |
| `finance_relevant` | checkbox | Offer-to-Cash-Markierung |
| `change_order_relevant` | checkbox | Nachtrag/Margenrisiko-Markierung |
| `blocker_type` | dropdown | intern/Kunde/Lieferant/Daten/Geld/Datei |
| `source_system` | dropdown | Slack/Drive/Airtable/myKilOS/manual |

## Weg für Johannes (manuell, einmalig)

1. ClickUp öffnen → Space „MYKILOS API TESTSPACE" → Einstellungen → Custom Fields (Space-Ebene,
   damit alle Ordner/Listen sie erben).
2. Obige Felder mit exakt diesen Namen + Typen anlegen (Dropdown-Optionen selbst wählen, z. B.
   `project_phase`: Briefing, Planung, Angebot, Bestellung, Ausführung, Abschluss, Service).
3. Danach kann der Code (`ClickUpClient.findOrCreateList`/`createTask`) optional erweitert werden,
   um diese Felder beim Provisioning direkt zu setzen (`clickup_create_task` unterstützt bereits
   `custom_fields: [{id, value}]` — die Feld-IDs müssen dann per `clickup_get_custom_fields`
   abgefragt und in Code/Config hinterlegt werden).

## Bis dahin

Der Studio-OS-ClickUp-Schritt (`ProvisioningStep.clickUpStruktur`) funktioniert bewusst OHNE diese
Felder — er legt nur Liste + Standard-Tasks an (Name-basiert). Kein Blocker für die aktuelle
Sandbox-Implementierung, nur für die spätere Feld-gestützte Auswertung (Projektgesundheit,
Review-Queues nach Handoff §11.3).
