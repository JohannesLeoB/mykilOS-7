# ClickUp Ghost Mode / Shadow-Betrieb
## Konzept- und Übergabebriefing für Folge-Session

Erstellt: 2026-07-02 02:22 · Ins Repo übernommen 2026-07-02 04:28.

**Verhältnis zur bestehenden Eisernen Regel:** [GHOST_PERSONA_REGEL.md](GHOST_PERSONA_REGEL.md)
(verankert in CLAUDE.md) ist die knappe, bereits VERBINDLICHE Basisregel (nur Testspace, nie
echte Assignee-ID, Ghost-Kürzel Jo/Da/Fra/Sen/Jil als Text, keine echten Notifikationen) —
entstanden aus einem echten Vorfall in dieser Session. Dieses Dokument ist die **formalere,
mehrphasige Ausbaustufe** davon (Ghost → Shadow → Controlled Go-Live, Custom-Field-Schema,
Go-Live-Gates). Beide gelten parallel; dieses Dokument verfeinert, ersetzt aber nicht die
Basisregel. Bei Widerspruch gewinnt die knappere, härtere Regel in GHOST_PERSONA_REGEL.md.

---

## 1. Zweck dieses Dokuments

Dieses Dokument übergibt das Konzept **„Ghost Mode / Shadow-Betrieb“** für die geplante Einführung von ClickUp als operatives System in Verbindung mit myKilOS 8, Google Drive, Airtable und den aus Slack abgeleiteten Prozessdaten.

Die Folge-Session soll dieses Konzept weiterführen, konkretisieren und in die bestehende ClickUp-/myKilOS-8-Rollout-Planung integrieren.

---

## 2. Ausgangslage

MYKILOS hat Slack gekündigt und will ClickUp als operatives Aufgaben-, Projekt- und Meilensteinsystem aufbauen. Parallel entsteht myKilOS 8 als eigene Studio-App und Schaltzentrale.

Aus Slack-Exporten, Drive-Projektordnern, Airtable-Stammdaten und myKilOS-Projektanlage sollen künftig reale Projekte, Aufgaben, Routinen, Meilensteine, Alerts und Templates abgeleitet werden.

Problem: Wenn diese abgeleiteten Aufgaben direkt echten Personen in ClickUp zugewiesen werden, besteht hohes Risiko:

- falsche Verantwortliche werden gepingt
- ungeprüfte Altlasten landen bei Teammitgliedern
- ClickUp wirkt sofort chaotisch
- Team verliert Vertrauen
- Automationen erzeugen Benachrichtigungs-Spam
- halbvalidierte Slack-/Drive-Ableitungen werden als Wahrheit behandelt

Daher braucht es vor dem echten Rollout eine sichere Simulationsphase.

---

## 3. Kernidee

ClickUp wird zunächst vollständig im **Ghost Mode** aufgebaut.

Das bedeutet:

```text
Rollen, Verantwortlichkeiten, Aufgaben, Meilensteine und Alerts werden simuliert,
aber noch nicht echten Menschen als operative Pflicht zugewiesen.
```

Es gibt also zunächst keine echten Assignees, keine echten Pings, keine produktiven Benachrichtigungen und keine automatischen Eskalationen an Teammitglieder.

Stattdessen werden Platzhalter-Rollen, Custom Fields, Testspaces, Review-Queues und Go-Live-Gates verwendet.

---

## 4. Begriffe

| Begriff | Bedeutung |
|---|---|
| Ghost Mode | Simulationsmodus ohne echte Benachrichtigungen an Teammitglieder |
| Shadow Mode | Beobachtungsphase mit bekannten echten Usern, aber noch ohne volle operative Verantwortung |
| Go-Live Mode | echte Assignees, echte Benachrichtigungen, echte Verantwortlichkeit |
| Ghost Role | Platzhalter-Rolle statt Person, z. B. `GHOST_PROJEKTLEAD` |
| Ghost Task | Aufgabe, die fachlich existiert, aber noch nicht live zugewiesen ist |
| Real Assignee | echte ClickUp-Person |
| Assignment Mapping | Übersetzung von Ghost-Rolle zu echter Person |
| Notification Mode | Modus für Benachrichtigungen: `silent`, `digest`, `live` |
| Go-Live Ready | Feld, das markiert, ob eine Aufgabe/Struktur produktiv aktiviert werden darf |

---

## 5. Drei Phasen

### Phase 1: Ghost Mode

Ziel: ClickUp, Templates, Routinen und Alerts vollständig simulieren.

Merkmale:

```text
Real Assignee = leer
Ghost Owner Role = gesetzt
Notification Mode = silent
Go-Live Ready = nein
```

Erlaubt:

- Testspace aufbauen
- Projektvorlagen anlegen
- Aufgaben simulieren
- Meilensteine simulieren
- Alerts als Tasks/Marker erzeugen
- Ghost-Rollen verwenden
- Custom Fields setzen
- Automationen intern testen
- myKilOS-Anzeige vorbereiten

Nicht erlaubt:

- echte Assignees setzen
- echte Teammitglieder pingen
- @Mentions verwenden
- echte Eskalationen auslösen
- produktive Webhooks feuern
- Kunden-/Finance-Aktionen auslösen

### Phase 2: Shadow Mode

Ziel: reale User werden dem System bekannt gemacht, aber noch kontrolliert.

Merkmale:

```text
Real Assignee = vorgeschlagen, aber nicht zwingend aktiv
Assignee Mapping Status = proposed oder confirmed
Notification Mode = digest oder silent
Go-Live Ready = teilweise ja
```

Erlaubt:

- echte User als Mapping-Kandidaten hinterlegen
- Verantwortlichkeit prüfen
- Teamfeedback einholen
- tägliche/wochentliche Zusammenfassungen testen
- myKilOS-Review-Queues validieren

Noch nicht erlaubt:

- flächige Live-Benachrichtigungen
- unkontrollierte Aufgabenflut
- automatische Eskalation an echte Personen
- systemische Umstellung ohne Review

### Phase 3: Controlled Go-Live

Ziel: echte operative Nutzung.

Merkmale:

```text
Real Assignee = gesetzt
Notification Mode = live
Go-Live Ready = ja
Source Confidence = stark oder geprüft mittel
```

Erlaubt:

- echte Aufgaben an echte Menschen zuweisen
- Benachrichtigungen aktivieren
- Follow-up-Alerts live schalten
- Meilensteine produktiv nutzen
- myKilOS-Cockpit mit Live-Zuständen verbinden

Voraussetzung:

Alle Go-Live-Gates müssen bestanden sein.

---

## 6. ClickUp-Struktur für Ghost Mode

Empfohlener Testspace:

```text
00_TESTSPACE_STUDIO_OS_SIMULATION
```

Empfohlene Folder:

```text
00_Systemtest
01_Ghost_Kundenprojekte
02_Ghost_Sales_Angebote
03_Ghost_Studio_Operations
04_Ghost_Service_Nacharbeit
05_Ghost_myKilOS8_Integration
```

Empfohlene Listen:

```text
Ghost Aufgaben
Ghost Meilensteine
Ghost Alerts
Ghost Automations Log
Mapping Review
Go-Live Kandidaten
Fehler / Konflikte
```

---

## 7. Ghost-Rollen

Statt echten Personen werden zunächst Rollenwerte verwendet.

| Ghost-Rolle | Bedeutung | Späteres Mapping |
|---|---|---|
| `GHOST_PROJEKTLEAD` | Projektsteuerung, Kundenkommunikation, Freigaben | echte Projektleitung |
| `GHOST_DESIGN` | Entwurf, Moodboard, Präsentation | Designer/in |
| `GHOST_INTERIOR` | Planung, Maße, Ausführung | Interior/Planung |
| `GHOST_ACCOUNTING` | Rechnung, Zahlung, Belege | Buchhaltung |
| `GHOST_EINKAUF` | Lieferanten, Angebote, Bestellung | Einkauf/Projektteam |
| `GHOST_GF_REVIEW` | kritische Entscheidungen, Freigaben | Geschäftsführung |
| `GHOST_ASSISTENZ` | Ablage, Recherche, Vorarbeit | Assistenz/Werkstudent |
| `GHOST_SERVICE` | Service, Reklamation, Nacharbeit | Serviceverantwortung |
| `GHOST_MYKILOS_ADMIN` | System, Mapping, Integrationen | myKilOS/Admin |

Diese Ghosts sind **keine ClickUp-User**. Sie sind Custom-Field-Werte. Dadurch wird niemand benachrichtigt.

---

## 8. Empfohlene Custom Fields

| Feld | Typ | Zweck |
|---|---|---|
| `Ghost Owner Role` | Dropdown | primäre Platzhalter-Rolle |
| `Ghost Review Role` | Dropdown | prüfende Platzhalter-Rolle |
| `Ghost Responsibility` | Dropdown | macht, prüft, entscheidet, informiert |
| `Real Assignee Proposed` | Person/Text | vorgeschlagene echte Person |
| `Real Assignee Confirmed` | Person/Text | bestätigte echte Person |
| `Assignee Mapping Status` | Dropdown | `unmapped`, `proposed`, `confirmed`, `live` |
| `Notification Mode` | Dropdown | `silent`, `digest`, `live` |
| `Go-Live Ready` | Checkbox | darf produktiv aktiviert werden |
| `Go-Live Gate Status` | Dropdown | `blocked`, `review`, `ready`, `live` |
| `Simulation Batch` | Text | Testlauf-Version |
| `Source System` | Dropdown | Slack, Drive, Airtable, myKilOS, manuell |
| `Source Confidence` | Dropdown | stark, mittel, schwach, Konflikt |
| `Source Evidence Link` | URL/Text | Quelle/Beleg |
| `Project ID` | Text | myKilOS-Projekt-ID |
| `Drive Folder ID` | Text/URL | Drive-Projektakte |
| `Airtable Record ID` | Text | Registry-/Stammdatensatz |
| `myKilOS Entity ID` | Text | interne myKilOS-Referenz |
| `ClickUp Live Target` | Text | späteres produktives Ziel |

---

## 9. Beispiel für Ghost Task

```text
Titel: Kundenfreigabe für Angebot prüfen
Projekt: Schneider Küche
Phase: Angebot & Freigabe
Ghost Owner Role: GHOST_PROJEKTLEAD
Ghost Review Role: GHOST_GF_REVIEW
Real Assignee Proposed: leer
Real Assignee Confirmed: leer
Assignee Mapping Status: unmapped
Notification Mode: silent
Source System: Slack + Drive
Source Confidence: mittel
Go-Live Ready: nein
```

Nach Review:

```text
Real Assignee Proposed: Johannes
Assignee Mapping Status: proposed
Notification Mode: digest
Go-Live Ready: nein
```

Nach finaler Freigabe:

```text
Real Assignee Confirmed: Johannes
Assignee Mapping Status: live
Notification Mode: live
Go-Live Ready: ja
```

---

## 10. Automationen im Ghost Mode

### Erlaubte Automationen

Im Ghost Mode dürfen Automationen nur interne Zustände setzen oder Testartefakte erzeugen.

Erlaubt:

```text
Status ändern
Custom Field setzen
Priorität setzen
Fälligkeitsdatum berechnen
Task in Review-Liste kopieren
Subtask erzeugen
Dependency setzen
Tag setzen
Go-Live Gate Status ändern
Eintrag in Ghost Automations Log erzeugen
```

### Nicht erlaubte Automationen

Nicht erlaubt:

```text
echte Assignees setzen
DM senden
@mention in Kommentar
Follower hinzufügen
echte Person in Kommentar markieren
externe produktive Webhooks feuern
E-Mail-Benachrichtigung auslösen
Slack/Chat-Benachrichtigung auslösen
Kunden-, Finance- oder Lieferantenaktion auslösen
```

Grundregel:

```text
Ghost Mode darf niemals echte operative Verantwortung auslösen.
```

---

## 11. Alerts im Ghost Mode

Alerts sollen als Ghost-Alerts getestet werden, nicht als echte Eskalation.

| Bedingung | Ghost-Reaktion |
|---|---|
| Angebot versendet, 7 Tage keine Reaktion | Ghost Follow-up Task |
| Freigabe erwähnt, keine Quelle im Drive | Ghost Review Task |
| Bestellung geplant, Artikelcheck fehlt | Ghost Blocker |
| Nachtrag erkannt, keine Kundenfreigabe | Ghost Margenwarnung |
| Montage abgeschlossen, Schlussrechnung fehlt | Ghost Accounting Task |
| Projekt 14 Tage ohne Aktivität | Ghost Projektgesundheit |
| Drive-Projekt ohne ClickUp | Ghost Mapping-Fehler |
| ClickUp-Projekt ohne Drive-Link | Ghost Aktenwarnung |

---

## 12. myKilOS-Handshake

myKilOS 8 muss Ghost-Zustände verstehen.

Empfohlene Felder im myKilOS-Datenadapter:

```text
ghost_role_id
ghost_review_role_id
proposed_user_id
confirmed_user_id
assignment_state
notification_state
go_live_state
source_confidence
source_system
source_evidence_link
simulation_batch_id
```

myKilOS soll anzeigen können:

```text
Diese Aufgabe ist simuliert.
Vorgeschlagene Rolle: Projektlead.
Noch keinem echten Nutzer zugewiesen.
Quelle: Slack + Drive.
Beweisgrad: mittel.
Go-Live nicht freigegeben.
```

---

## 13. User-Identity-Mapping

Da myKilOS-User mit ClickUp, Gmail und interner ID angemeldet sind, braucht es eine Identity-Mapping-Schicht.

Empfohlene Mapping-Tabelle:

| Feld | Zweck |
|---|---|
| `mykilos_user_id` | interne User-ID |
| `clickup_user_id` | ClickUp-User |
| `google_workspace_email` | Gmail/Workspace-Identität |
| `airtable_user_id` | falls vorhanden |
| `role_primary` | Hauptrolle |
| `role_secondary` | Nebenrollen |
| `can_receive_live_tasks` | darf echte Aufgaben erhalten |
| `notification_mode_default` | Standard: silent/digest/live |
| `go_live_enabled` | User für Live-Betrieb aktiviert |

Wichtig:

```text
Nur bestätigte User mit go_live_enabled = true dürfen echte ClickUp-Aufgaben bekommen.
```

---

## 14. Go-Live-Gates

Eine Ghost-Aufgabe darf erst live gehen, wenn alle Bedingungen erfüllt sind.

Pflichtbedingungen:

```text
Projekt-ID vorhanden
Drive-Link vorhanden
ClickUp-Task korrekt gemappt
Ghost-Rolle gesetzt
echter User bestätigt
Benachrichtigungsmodus freigegeben
Quelle geprüft
Source Confidence = stark oder geprüft mittel
keine Konflikte aus Slack/Drive
Go-Live Ready = ja
```

Zusätzliche Bedingungen bei kritischen Aufgaben:

```text
Finance-relevant → Accounting bestätigt
Kundenrelevant → Projektlead bestätigt
Nachtrag → GF/Projektlead Review
Bestellung → Artikelcheck erledigt
Abschluss → Rechnung/Zahlung/Belege geprüft
```

---

## 15. Datenfluss

```text
Slack Export
→ Process Mining
→ Aufgaben-/Routinen-/Alert-Kandidaten
→ Ghost Tasks in ClickUp Testspace
→ Review in myKilOS
→ Rollenmapping
→ Go-Live-Gate
→ echte ClickUp-Aufgaben
```

Parallel:

```text
Drive Projektordner
→ Projektphasen- und Belegprüfung
→ Ghost Review Tasks
→ Drive-Lückenqueue
→ myKilOS Projektgesundheit
```

Und:

```text
Airtable / myKilOS Projektanlage
→ Projekt-ID, Kunde, Projekttyp, Teamrollen
→ ClickUp-Teststruktur
→ Drive-Template
→ myKilOS-Projektcockpit
```

---

## 16. Datenhygiene-Regeln

- Slack ist Signalquelle, nicht Wahrheit.
- Drive ist Akten-/Belegquelle, aber kann unvollständig sein.
- Airtable/myKilOS liefert Stammdaten und Projektanlage.
- ClickUp ist operative Arbeit, nicht Stammdatenquelle.
- Ghost Tasks sind nicht automatisch produktive Aufgaben.
- Jede Ableitung braucht Quelle und Beweisgrad.
- Unsichere Aufgaben bleiben in Review.
- Keine stillen Zuweisungen an echte Personen.
- Keine externen Systeme durch persönliche Simulation verändern.
- Alle erzeugten IDs protokollieren.

---

## 17. Risiken

| Risiko | Beschreibung | Gegenmaßnahme |
|---|---|---|
| Benachrichtigungs-Spam | echte User werden zu früh gepingt | Ghost-Rollen statt Assignees |
| falsche Zuständigkeit | Slack-Signal falsch interpretiert | Mapping Review |
| Altlastenflut | alte Slack-Aufgaben werden live importiert | Source Confidence + Go-Live Gate |
| Automationsfehler | Automationen erzeugen zu viel | Testspace + Automations Log |
| Vertrauensverlust | Team sieht Chaos | zuerst Shadow-Demo |
| Datenverwechslung | Projekt-ID/Drive-ID falsch | ID-Mapping zwingend |
| Tool-Wildnis | ClickUp wird neuer Slack-Ersatz | klare Systemrollen |
| Datenschutz | persönliche Kommunikation wird überdehnt | nur zweckgebundene Ableitung |

---

## 18. Testfälle

| Test | Erwartung |
|---|---|
| Ghost Task wird erstellt | keine Person erhält Benachrichtigung |
| Ghost Role gesetzt | keine ClickUp-Assignee nötig |
| Automation läuft | nur Custom Fields/Status ändern sich |
| Alert wird erzeugt | landet in Ghost Alerts, nicht bei echter Person |
| Real Assignee Proposed gesetzt | noch keine Live-Zuweisung |
| Go-Live Ready = nein | Aufgabe bleibt simuliert |
| Go-Live Ready = ja + User bestätigt | Aufgabe darf live gehen |
| Source Confidence = Konflikt | Aufgabe bleibt blockiert |
| Drive-Link fehlt | Go-Live blockiert |
| Projekt-ID fehlt | Go-Live blockiert |
| myKilOS liest Aufgabe | zeigt Simulation eindeutig an |
| User nicht go-live-enabled | keine echte Zuweisung |

---

## 19. Empfohlener Ablauf für Folge-Session

1. Dieses Dokument lesen.
2. Bestehendes ClickUp/myKilOS-Handoff prüfen.
3. Ghost Mode als verbindliche Sicherheitsphase in den Rollout aufnehmen.
4. Custom-Field-Schema für Ghost Mode konkretisieren.
5. ClickUp-Testspace `00_TESTSPACE_STUDIO_OS_SIMULATION` planen.
6. Ghost-Rollenliste finalisieren.
7. myKilOS-Datenadapter um Ghost-/Assignment-State erweitern.
8. Automationsregeln in „silent“ und „live“ trennen.
9. Go-Live-Gates als QA-Kriterien formulieren.
10. Testfälle in Codex-/QA-Handoff übernehmen.
11. Erst nach bestandener Simulation echte User zuweisen.

---

## 20. Codex-/Agenten-Auftrag

Die nächste Coding- oder Setup-Session soll:

```text
Implementiere einen Ghost-/Shadow-Betrieb für den ClickUp-Rollout von myKilOS 8.
Alle aus Slack, Drive, Airtable oder myKilOS abgeleiteten Aufgaben, Routinen,
Meilensteine und Alerts müssen zuerst als Ghost Tasks in einem isolierten
ClickUp-Testspace entstehen. Verwende Ghost-Rollen und Custom Fields statt
echter Assignees. Keine echte Person darf im Ghost Mode gepingt werden.

Baue die Datenadapter-Logik so, dass myKilOS 8 zwischen ghost, proposed,
confirmed und live unterscheiden kann. Aufgaben dürfen erst nach bestandenen
Go-Live-Gates echten ClickUp-Usern zugewiesen werden.
```

---

## 21. Harte Nicht-tun-Regeln

- Keine echten Assignees im Ghost Mode.
- Keine @Mentions echter Personen.
- Keine produktiven Benachrichtigungen.
- Keine produktiven Webhooks ohne Gate.
- Keine Migration von Slack-Aufgaben direkt in Live-ClickUp.
- Keine Annahme, dass Slack-Aufgaben automatisch wahr sind.
- Keine Zuweisung ohne Projekt-ID und Drive-Link.
- Keine Finance-/Kundenaktion ohne Review.
- Keine Automationen ohne Testlog.
- Kein Go-Live ohne bestätigtes User-Mapping.

---

## 22. Kurzfazit

Der Ghost Mode ist die Sicherheitsschicht zwischen Analyse und echtem Betrieb.

Er erlaubt, ClickUp vollständig aufzubauen, Routinen und Alerts realistisch zu simulieren und myKilOS 8 sauber anzubinden, ohne das Team durch ungeprüfte Aufgaben, falsche Zuständigkeiten oder Benachrichtigungschaos zu überlasten.

```text
Erst simulieren.
Dann prüfen.
Dann mappen.
Dann freigeben.
Dann live schalten.
```
