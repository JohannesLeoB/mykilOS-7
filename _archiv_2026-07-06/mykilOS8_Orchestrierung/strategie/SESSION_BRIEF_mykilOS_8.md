# Session-Brief → mykilOS Claude-Code-Session
### Ziel: mykilOS 8 — die ClickUp-Integration, aufsetzend auf mykilOS 7

*Von: Analyse-/Strategie-Session (Claude.ai) · Stand: 29.06.2026 · Zweck: Kontext-Übergabe. Kurz gehalten — Details liegen in den referenzierten Artefakten. **Baseline = die aktuelle mykilOS-7-Codebasis** (an ihr orientieren, nicht an älteren Plänen). Die hier beschriebene ClickUp-Integration ist der definierende Schritt, der mykilOS 7 zu **mykilOS 8** macht.*

---

## Was diese Session war
Wir haben den **kompletten Slack-Export** (Jan 2025 – Jun 2026, 229 Channels, 12.465 Nachrichten, 3.789 Dateien) und die **Google-Kontakte** tiefenanalysiert, einzelne Projektverläufe vollständig gelesen, daraus die **echten Projekt-Routinen** abgeleitet und einen Plan **mykilOS ⇄ ClickUp** entworfen, der als mykilOS 8 umgesetzt werden soll.

Ergebnis-Artefakte (read-once Historien-Ports + Pläne):
- `mykilos_slack_port.json` — 169 Projekte (Phase, Ort, Lead, Budget, Issues, Preis-Beobachtungen), Lieferanten, Team, Kontakt-Matches.
- `mykilos_project_routines.json` — 11-Phasen-Modell mit Erkennungs-Signalen, gemessene Übergangsdauern, Routinen je Typ, pro Projekt die erkannte Phasen-Timeline.
- `mykilos_clickup_build.json` — Space/Ordner/Status/Felder/Templates/Automationen + 169 Seed-Tasks.
- `mykilOS_Betriebssystem_Strategie.md` — die volle 3-teilige Strategie (ausführliche Quelle der Wahrheit).

## Verhältnis zu mykilOS 7
mykilOS 7 trägt bereits die Live-Integrations-Grundlage (Google-OAuth/PKCE, Drive, Airtable, Clockodo, Sevdesk) als **read-only Historien-Ports**. **mykilOS 8 fügt ClickUp hinzu — und zwar als das einzige Read-Write-System.** Leitbild: *ClickUp = wo Arbeit passiert (Verb), mykilOS = wo Arbeit verstanden wird (Substantiv).* Alle bestehenden Ports bleiben read-only; ClickUp ist die operative Ebene, die mykilOS orchestriert (liest **und** schreibt).

## Was wir über das Studio gelernt haben (nur das Build-Relevante)
- **Geschäft:** Innenausbau gehoben — Küche, Ankleide, Bad, Schränke, Sideboards + in fast jedem Projekt eigene **Lichtplanung** (oft KNX/DALI). Privat-Vollprojekt ist der Kern (~8 Monate), daneben Gewerbe, Kleinauftrag, Service, Intern.
- **Identität eines Projekts = zwei Schlüssel:** der `kunde`-Token aus dem Channel-Namen (`phase_ort_kunde_lead`) **und** die **Kundennummer (Kdnr)** aus dem Dokumentensystem (`AN-MK_A_YYYY-MM-NNNN-Kdnr-NNNNN` = Angebot, `AB-MK` = Auftrag, `SR-MK` = Schlussrechnung). Beide zusammen sind die kanonische Projekt-/Kunden-Identität.
- **Aufgaben leben heute als @-Mentions in Slack** — das faktische To-do-System, das versickert. Ziel von v8: das in ClickUp überführen.
- **Lebenszyklus & Engpässe** sind in `routines.json` quantifiziert. Drei Wartezonen: Anfrage→Aufmaß (~46 T), Kundenentscheidung (~27 T), Mängel-Auslauf (~44 T). Größter unkontrollierter Verzögerer: **Fremdgewerke/bauseits** (Elektriker, Architekt, Bauträger). Lieferanten-Qualität ist ein echtes Signal (z. B. Bartels).
- **Logistik:** Sammelpunkt **Degela-Lager**. **Preis-Logik:** EK + Montage (~84,50 €/h) + Kleinteilepauschale; Licht = Liste − Rabatt (~45 %).

## Architektur-Konsequenzen für mykilOS 8 (auf der 7er-Bibliothekarin aufbauend)
1. **ClickUp als neue Integration** — die einzige mit Schreib-Pfad. Provisioning (Outbound-Write) und Status (Read) als getrennte Operationen modellieren.
2. **ExternalMappingRegistry-Spine = `kunde`-Token + Kdnr.** Jeder externe Datensatz (Slack-Channel, Drive-Ordner, Airtable-Record, ClickUp-Task, Kontakt) hängt über diese Identität am Projekt-Knoten. Registry um **Kdnr als zweiten kanonischen Schlüssel** neben dem Token erweitern.
3. **Projekt-Knoten = Hub.** Trägt: Phase (aus ClickUp), Kunde (Airtable/Kdnr), Dokumente (Drive), Historie (Slack), Zeit/Geld (Clockodo/Sevdesk), Aufgaben/Routine (ClickUp).
4. **Provisioning-Flow (der einzige Outbound-Write):** neues Projekt in mykilOS → ClickUp-Task anlegen, Typ-Template anwenden, Felder vorbefüllen (Ort, Lead, Budget, Kdnr, Token, Slack-Channel, Drive-Ordner) → Status zurücklesen. **Dieser Schreib-Pfad muss werfen** (kein `try?`-Verschlucken — V5-Lehre gilt hier verschärft).
5. **Phasen-/Routine-Modell** aus `mykilos_project_routines.json` als kanonisches Lifecycle-/State-Modell übernehmen (11 Phasen + Übergangsdauern). Die vier Engpässe speisen das Signal **Risiko/Engpass**.
6. **Dokument-Konvention** (`AN-MK` / `AB-MK` / `SR-MK` + Kdnr) beim Verknüpfen von Drive-Dateien an Projekte parsen und honorieren.
7. **Seed:** Die drei JSON-Ports als einmaliger Historien-Import zum Befüllen/Validieren der Registry — nicht als laufende Kopie.

## Nächste Schritte für die Code-Session
1. Auf der aktuellen **mykilOS-7-Codebasis** aufsetzen; ClickUp-Konnektor als neue Integration mit getrenntem, werfendem Provisioning- und Lese-Pfad ergänzen → Release-Ziel mykilOS 8.
2. ExternalMappingRegistry um `Kdnr` als zweiten kanonischen Schlüssel erweitern.
3. Lifecycle-/State-Modell aus `routines.json` in die Domain ziehen (Phasen + Risiko-Signale).
4. Historien-Import-Skript für die drei JSON-Ports (read-once), mit Lücken-Report.

## Was unverändert gilt (Nicht-Verhandelbares)
- Externe Quellen sind read-only Historien-Ports — **Ausnahme: ClickUp** (read-write, weil operative Ebene).
- **Jeder Write wirft** — kein stilles `try?`. Gilt verschärft für den ClickUp-Provisioning-Pfad.
- Echte Persistenz (GRDB/SQLite, versionierte Migrationen) — kein `.inMemory`, kein UserDefaults-als-DB.
- **Airtable bleibt System-of-Record für Kunden/Projekte.** mykilOS speichert Mapping + Kontext, keine Kopien.
- Design-Tokens Pflicht, CI als harte Merge-Gate.

*Fragen/Schärfen → zurück an die Analyse-Session. Diese Datei ersetzt den früheren versionsneutralen Brief.*
