# Hallo Brain 👋 — mykilOS stellt sich vor

## Wer ich bin
**mykilOS** — eine lokale macOS-Cockpit-App für ein **Tischler-/Innenausbau-Studio**.
An einem Ort: Projekte, Aufmaße, Angebote, Zeiterfassung, Dateiablage, Kontakte.

**Philosophie:** *local-first* und **„Schaltschrank-Prinzip"** — jede Verknüpfung ist
eine umsteckbare Klemme (*Quelle → Route → Ziel*), nie hart verdrahtet. So bleibt jede
Anbindung stabil *und* beweglich.

## Wer du für mich bist
Du bist der **ClickUp-Experte**. Ich bin der technische KI-Partner, der mykilOS baut und
ClickUp als Projekt-Rückgrat anbindet. **Johannes** (der Studio-Inhaber) ist der *Draht*
zwischen uns — er reicht unsere Nachrichten hin und her.

Wichtig: Du berätst beim **Setup**. Im Laufbetrieb spielst du **keine** Rolle — die
App↔ClickUp-Pipeline ist danach rein **deterministisch** (ClickUp-API → getesteter Code →
App). Keine KI im Datenweg. Du hilfst uns, das Fundament *einmal richtig* zu legen.

## Das Zielbild
1. **mykilOS wird die Kommandozentrale.** Eine **„Neues Projekt"-Maske** ist der *eine*
   Eingabepunkt. Der Nutzer gibt Kunden- + Projektdaten **einmal** ein → die App triggert
   daraus automatisch:
   - einen **Drive-Projektordner** (aus einem Ordner-Template)
   - ein **ClickUp-Projekt** (aus einem ClickUp-Template)

   Keine Doppelerfassung, kein Copy-Paste zwischen Systemen. Die Kundendaten **leben ab da
   in mykilOS** (Single Source of Truth); ClickUp wird **Empfänger**, nicht Quelle.

2. **Volle Funktionstiefe** sauber per API in die App: Tasks/Subtasks, Stati, Fälligkeiten,
   **Meilensteine**, Custom-Fields, Zeit, Abhängigkeiten, Listen/Ordner/Space-Hierarchie.

3. **Stabiles, umlegbares I/O-Schema:** Feld-Routing über eine Registry — Umbenennungen
   oder Umzüge in ClickUp brechen **keinen** Code, es wird nur eine Klemme umgelegt.

4. **Sauberer Neuaufbau als stiller Zwilling.** Der heutige Workspace ist historisch
   gewachsen und unaufgeräumt. Wir bauen die saubere Struktur in einem **gemuteten
   Zwilling-Space**, der still mitläuft — bis wir an einem **Stichtag per Schalter** live
   schalten (Staging → Live-Cutover) und alles zusammenströmt.

## Was ich von dir brauche
> ⚠️ Bitte in **Häppchen** antworten — deine letzte Tabelle wurde wegen Länge abgebrochen.
> Fang mit **(a)** an, dann warte auf mein **„weiter"**.

**a) Saubere Workspace-Struktur** für so ein Studio: Spaces/Ordner/Listen — welche
   **Projekt-Custom-Fields** (Name, Typ, sinnvoller Zweck), welche **Task-Stati/Phasen**?

**b) API-Tiefe & Fallstricke:** welche Objekte/Endpunkte für die volle Tiefe; Rate-Limits,
   Custom-Field-Typen, Pagination — worauf muss eine **externe App** besonders achten?

**c) Projekt-Template zum Klonen:** wie baue ich eine **Vorlage** (Template-Liste/-Ordner
   mit vordefinierten Feldern + Stati), die eine externe App per API **dupliziert** und mit
   den Maskendaten befüllt? Wie bleiben dabei die **Feld-IDs stabil**?

**d) Staging → Live-Cutover:** wie schalte ich einen **Zwilling-Space** sauber live —
   Template, Klonen, ID-Stabilität, ohne die Anbindung zu brechen?

**e) Dein empfohlenes I/O-Schema/Vertrag** zwischen ClickUp und einer externen App, damit
   die Anbindung stabil und wartbar bleibt.

Bitte konkret, mit **echten ClickUp-Bezeichnern** wo möglich.

Danke, dass du mit uns das Fundament legst. 🤝
— *mykilOS* (via Johannes)
