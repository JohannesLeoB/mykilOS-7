# mykilOS — Betriebssystem für Projekte

*Tiefenanalyse des kompletten Slack-Exports (Jan 2025 – Jun 2026, 229 Channels, 12.465 Nachrichten, 3.789 Dateien) plus vollständiges Lesen repräsentativer Projektverläufe. Drei Teile: wie ihr arbeitet, eine ClickUp-Strategie, und der Plan wie mykilOS 6 und ClickUp Hand in Hand gehen.*

---

# Teil 1 · Wie ihr arbeitet

## Das Geschäft
Ihr seid kein Küchenstudio, ihr seid ein **Innenausbau-Studio für gehobene Privat- und Gewerbeobjekte**. Die Küche ist das Herzstück (679 Nennungen), aber genauso liefert ihr Einbauschränke und Ankleiden (462), Bäder und Waschtische (245), Sideboards, Regale, Theken, gelegentlich Treppen — und in fast jedem Projekt **Lichtplanung** (497 Nennungen). Ein typisches Vollprojekt wie Hofweg 55 umfasst Küche, Ankleide, Bad, Arbeitszimmer, Wohnzimmer und ein komplettes KNX-Licht­konzept über mehrere Räume.

Die Projekte teilen sich in fünf Wirklichkeiten: das **Privat-Vollprojekt** (euer Kerngeschäft, ~8 Monate Laufzeit), das **Gewerbeprojekt** (Praxis, Bank, Büro — mehr Stakeholder, oft offline abgestimmt), den **Kleinauftrag / reinen Produktverkauf**, den **Servicefall** und **interne Vorhaben** (Showroom, Serienküche).

## Das Team — wer was tut (aus den Verläufen abgeleitet)
| Person | Rolle, wie sie sich in den Channels zeigt |
|---|---|
| **Daniel Klapsing** | Operativer Kopf. Preis­entscheidungen, Lieferanten­verhandlung, Eskalations-Mails an Kunden, „wo stehen wir", finale Abnahme, Aufsicht über fast alle Projekte. Mit Abstand am aktivsten. |
| **Jasper** | Der Macher vor Ort. Projektausführung, Baustellen- und Gewerke­koordination, Lieferanten­kontakt, Kunden-Updates schreiben. Trägt Fuckner, Döhle, Amoulong. |
| **Jilliana Bahr** | Licht & Design. Lichtplanung und -beschaffung, Bemusterung, Protokolle, technischer Draht zu Elektrikern (DALI/KNX). Die Lichtexpertin. |
| **Frauke Fudickar** | Kaufmännisches Rückgrat. Angebote, ABs, Anzahlungs-/Schluss­rechnungen, Bestellungen auslösen, Projektübersicht pflegen, Lieferanten-Abgleich, Mahnungen. |
| **Johannes Leo Berger** | Gründer. Führt ausgewählte Projekte direkt (Vinahl), Planung/CAD (Vectorworks), Design- und Preis­entscheidungen. |
| **Sebastian** | Generalist, erste Entwürfe/CAD. |

Weitere Leads je Projekt: Philipp, Marie u. a. — sichtbar im Channel-Suffix `..._ps`, `..._mg`.

## Der gelebte Ablauf (nicht die Theorie)
Anfrage (oft über Empfehlung, teils via WhatsApp-Medien) → **Aufmaß & Bemusterung** vor Ort → **Planung** in Vectorworks + paralleler **Lichtplanung** (Moodboards, Leuchtenauswahl, Szenen, Schalter) → **Angebot** (`AN-MK`, mit Kundennummer) → **Entscheidung des Kunden** → **Auftragsbestätigung** (`AB-MK`) + Anzahlungs­rechnung → **Beschaffung** quer über viele Gewerke → **Fertigung** → **Lieferung** (häufig konsolidiert über das **Degela-Lager**, bei Hochhäusern per Möbellift) → **Montage** → **Abnahme & Mängel** → **Schlussrechnung** (`SR-MK`) → **Service/Reklamation**.

Die Planungs­phase ist schnell (Aufmaß bis Angebot ~5 Tage). Drei Wartezonen fressen die Laufzeit: der Vorlauf bis zum Aufmaß (~46 T), die **Kundenentscheidung** (~27 T) und der **Mängel-/Abnahme-Auslauf** (~44 T).

## Wie ihr koordiniert — eure echten Routinen
- **@-Mention als To-do.** Euer faktisches Aufgabensystem. „@Jasper Kolja anrufen", „@Frauke Einputzteile bei der Degela auslösen", „@Jilliana bei Modular nach Lichtplanung fragen" — Hunderte davon. Aufgaben leben heute als Erwähnungen im Channel und gehen genau dort verloren.
- **Protokoll nach jedem Termin.** Jilliana/Jasper posten strukturierte Besprechungs- und Baubesprechungs­notizen direkt in den Channel.
- **Projektübersicht / Projektliste.** Frauke pflegt pro Projekt eine Master-Liste („gelb markiert: nicht bestellt/vorliegend"). Das ist faktisch das Dokument, das ClickUp ablösen soll.
- **Soll/Ist-Terminplan**, **Bemusterung**, **Küchencheckliste**, **Stunden eintragen** (Clockodo — „sind alle Stunden eingetragen?", „Minusstunden eingetragen").

## Euer Dokumentensystem (systematisch!)
Eure Dateien folgen einer klaren Konvention:
- `AN-MK_A_2025-09-0090-Kdnr-12399.pdf` = **Angebot**
- `AB-…-Kdnr-12399.pdf` = **Auftragsbestätigung**
- `SR-MK_SR_…-Kdnr-11782.pdf` = **Schlussrechnung**, `…_RE_…` = Rechnung
- Arbeitsdateien: `YYMMDD_Projektname_Initialen` (z. B. `20250425_Fuckner-Huetter_Beleuchtung.pdf`)

Der Schlüssel darin ist die **Kundennummer (Kdnr)** — 46 verschiedene allein in Dateinamen, fortlaufend im Bereich ~11.2xx–12.8xx. Das ist eure kanonische Kunden-ID, neben dem `kunde`-Token aus den Channel-Namen.

Dateibestand: 1.365 PDFs (Angebote, Rechnungen, Pläne), ~2.000 Bilder (Fotos, Renderings, Screenshots), 34 STP + 6 DWG (CAD), dazu Videos und einzelne XLSX.

## Das Lieferanten-Netzwerk & die Make-or-Buy-Logik
- **Tischlerei/Korpus:** Meylahn, Bartels, Gilhaus, Stadler, Wilkari, **Horatec** (günstiger EK, oft für Korpusmöbel), Fritz Kraft, Rakete, Pelle, Kontec (Edelstahl-Arbeitsplatten).
- **Sanitär:** Bato (Bahadir). **Armaturen/Spülen:** Dornbracht, Vola, Gessi, Quooker, Reginox, Blanco, Keuco, Artinox.
- **Geräte:** Gaggenau, Miele, Liebherr, V-ZUG, BORA.
- **Licht:** Modular/SuperMODULAR (Thomas Mehls), XAL, Lightnet, Deltalight, Midgard, A-N-D.
- **Logistik:** Degela als Sammel-/Lagerpunkt; Egger (Dekore); Möbel: Vitra, Mattiazzi.

Die Kalkulation, die durchscheint: **EK + Montage (~84,50 €/h) + Kleinteilepauschale**; bei Licht **Listenpreis − Rabatt (oft 45 %) = netto EK**. Make-or-Buy je Position bewusst entschieden (Vinahl: Tresen von Wilkari, Küche günstiger bei Horatec, Stühle Vitra).

## Wo es wirklich wehtut (die echte Reibung)
1. **Fremdgewerke / bauseits** — mit Abstand euer größter Verzögerer und doch außerhalb eurer Kontrolle. Bei Fuckner/Hütter hingen Wochen am Elektriker (Conrad/Wolff), am Architekten (FSG/Bremer Kirsch) und am Bauträger (Hausschildt); dazu ein Wassereintritt auf der Baustelle. Ihr koordiniert, ohne Bauleitung zu sein — und fangt den Frust der Kunden auf.
2. **Die Kundenentscheidung** — die ~27-Tage-Lücke zwischen Angebot und Auftrag.
3. **Lieferanten-Qualität & der Mängel-Auslauf** — Döhle ist das Lehrstück: runde um runde Nachbesserung über Bartels (Lack, Gehrung), Bato (lockere Armaturen), Liebherr (Abdeckungen), bis der Kunde ausdrücklich die Tischler-Qualität rügt („wir hatten drei Tischler, nur Eurer macht Probleme") und euch bittet, eure Gewerke selbst zu kontrollieren.
4. **Scope Creep / Nachträge** — 98 Nennungen; Umplanungen, neue ABs, „3.000 € teurer, als Extrapunkt einkalkulieren?".
5. **„Bis wohin geht unsere Verantwortung?"** — ein wiederkehrendes internes Thema, das ihr selbst als klärungsbedürftig markiert.

Und das, was ihr gut könnt: **sorgfältige, deeskalierende Kundenkommunikation** (mehrfach umformulierte Update-Mails bei Verärgerung) und ein echtes Gespür für Material, Licht und Detail.

---

# Teil 2 · ClickUp — Plan & Strategie

## Leitgedanke
ClickUp ist die **operative Ebene — die Hände**. Hier passiert die Arbeit: Aufgaben, Status, Zuständigkeiten, Termine, Routinen, Automationen. Das Datenmodell (im Bauplan `mykilos_clickup_build.json` ausgearbeitet): **ein Space, vier Ordner entlang der vier Lebenszyklen, Status = Phasen, Task = Projekt, Subtasks = Routine**. Standort/Lead/Budget sind Felder, keine Struktur. Gewonnene Angebote wandern von ① nach ② — wie der Channel von `a_` zu `p_`.

## Was die Tiefenanalyse am Plan schärft
1. **Lichtplanung und Bemusterung als eigene Routine-Stränge.** Sie sind zu groß für eine Zeile. In der Vollprojekt-Checkliste werden sie zu eigenen Blöcken: *Bemusterung* (Material, Fronten, Griffe, Stoffe) und *Lichtplanung* (Moodboard → Leuchtenauswahl → Szenen/Gruppen → technische Vorgabe an Elektriker → Bestellung).
2. **Gewerke-Koordination sichtbar machen.** Neues Feld **Gewerke/Partner** (Labels) plus, bei großen Projekten, je Gewerk ein Subtask mit eigenem Termin- und Status­strang. Das ist genau die Koordination, die heute in @-Mentions zerfällt.
3. **Ein Engpass-Flag „Fremdgewerke/bauseits".** Euer Risiko #1 bekommt einen eigenen Wert im Feld *Risiko/Engpass*, damit die Projekte, die an Elektriker/Architekt hängen, im Board sofort auffallen.
4. **Mängel als strukturierter Teilprozess.** Bei Statuswechsel auf *Montage* erzeugt eine Automation die Checkpunkte *Abnahmeprotokoll* und *Mängelliste*; jeder Mangel wird ein abhakbarer Punkt mit zuständigem Gewerk — das Döhle-Muster, aber kontrolliert.
5. **Lieferanten-Performance.** Eine eigene Liste *Lieferanten* mit Bewertung/Notizen (z. B. Bartels-Qualitätsthema), damit Make-or-Buy auf Erfahrung statt Bauchgefühl beruht.
6. **Die @-Mention-Gewohnheit nach ClickUp holen.** Das ist die eigentliche Verhaltensänderung: Aus „@Jasper Kolja anrufen" im Channel wird ein zugewiesener Subtask/Kommentar mit Fälligkeit. Nur so hört Arbeit auf, in Chat-Verläufen zu versickern.

## Die Routinen, verankert (Auszug Vollprojekt)
Anfrage/Fragebogen → Aufmaß + Fotos → **Bemusterung** → **Planung (CAD)** + **Lichtplanung** → Angebot (`AN-MK`) → *Entscheidung* → AB + Anzahlung → Bestellungen (je Gewerk) → Fertigung → Lieferung an Degela → Montage → **Abnahmeprotokoll + Mängelliste** → Schlussrechnung (`SR-MK`) → Service. Die übrigen fünf Typ-Checklisten stehen im Bauplan.

## Die Automationen, die auf eure Engpässe zielen
- *Angebot raus* seit 14 T unverändert → Lead erinnern (gegen die 27-T-Entscheidungslücke).
- Status → *Gewonnen* → Beschaffung sofort anstoßen, Einkauf benachrichtigen (gegen den 40-T-Beschaffungsvorlauf).
- Status → *Montage* → Abnahme/Mängel-Punkte erzeugen (gegen den 44-T-Mängel-Auslauf).
- Status → *Abnahme* → Schlussrechnung-Task für Frauke.
- Budget > 50.000 € → Priorität hoch.

## Adoptions-Strategie
Klein und echt anfangen: das **Board als tägliches Werkzeug** (jeder pflegt seinen Status), die **169 echten Projekte vorbefüllt** als Startbestand (kein leeres System), die **Automationen ab Tag 1** für die drei Engpässe, und ein **wöchentlicher Portfolio-Review** auf dem Dashboard (Projekte je Phase, Pipeline-Wert, überfällige Nachfass-Termine, offene Mängel). Der Erfolg steht und fällt damit, dass die @-Mention-Aufgaben in ClickUp statt in Slack landen.

---

# Teil 3 · mykilOS 6 ⇄ ClickUp — Hand in Hand

## Das Prinzip in einem Satz
**ClickUp ist, wo Arbeit passiert (das Verb). mykilOS 6 ist, wo Arbeit verstanden wird (das Substantiv).** Sie treffen sich am Projekt — über den gemeinsamen Schlüssel `kunde`-Token + Kundennummer (Kdnr).

ClickUp ist schnell, operativ, für Menschen, die heute eine Aufgabe abhaken. mykilOS ist der Cockpit-Blick: der kanonische Projekt­datensatz, der Kunde, die Dokumente, die Preis-Logik, die Lieferanten-Intelligenz, die Verbindung aller Systeme — die **Bibliothekarin**. ClickUp weiß, *was als Nächstes zu tun ist*. mykilOS weiß *alles über das Projekt*.

## Wem was gehört
| Ebene | Zuhause | Inhalt |
|---|---|---|
| **Ausführung** | ClickUp | Tasks, Status (11 Phasen), Zuständigkeiten, Termine, Routine-Checklisten, Automationen, Mängellisten, Tages-Koordination |
| **Verständnis / System-of-Record-Links** | mykilOS 6 | kanonischer Projekt-Knoten (Token + Kdnr), Kundendaten, Dokument-Verweise, Preis-Logik (Kalkulationsbrain), Lieferanten-Intelligenz, Cross-System-Mapping, Analytik |
| **Historische Ports (read-only)** | Slack, Drive, Airtable, Contacts, Clockodo, Sevdesk | Verlauf, Dateien, Kundenstamm, Zeit, Rechnungen — gelesen, nie überschrieben |

Wichtig: ClickUp ist das **einzige** externe System, das mykilOS nicht nur liest, sondern auch **beschreibt** — weil es die operative Ebene ist, die mykilOS orchestriert. Alles andere bleibt Lese-Port (eure harte Regel).

## Der Lebenszyklus eines Projekts über beide Systeme
1. **Geburt in mykilOS / Airtable.** Neuer Kunde + Projekt bekommen Kdnr und `kunde`-Token. mykilOS legt den kanonischen Datensatz an.
2. **mykilOS provisioniert ClickUp** per Connector: erstellt den Projekt-Task in der richtigen Liste, wendet das **Typ-Template** an (Routine-Checkliste) und füllt die Felder vor (Ort, Lead, Budget, Kdnr, Token, Slack-Channel, Drive-Ordner). → Kein Projekt startet ohne seine Routine, von Hand muss niemand mehr ein Board aufsetzen.
3. **Das Team arbeitet in ClickUp.** Status ziehen, Routine abhaken, Automationen laufen (Nachfass-Erinnerung, „Beschaffung bei Gewinn", „Mängelliste bei Montage"). Die @-Mention-Gewohnheit zieht von Slack in ClickUp-Tasks um.
4. **mykilOS liest ClickUp zurück** und legt den Status über den Cockpit-Blick: dieses Projekt ist in Phase X (ClickUp), hier sind seine Dokumente (Drive), sein Kunde (Airtable/Kdnr), seine Historie (Slack), seine Stunden und Rechnungen (Clockodo/Sevdesk). Die Bibliothekarin hält das Mapping über Token + Kdnr.
5. **Dokumente schließen sich an.** Wird ein `AN-MK`/`AB-MK`/`SR-MK`-PDF erzeugt, landet es in Drive; mykilOS verknüpft es mit dem Projekt; der passende ClickUp-Checkpunkt hakt sich ab.
6. **Geld schließt den Kreis.** Sevdesk (Rechnung) + Clockodo (Zeit) liefern Ist-Kosten und Marge zurück an mykilOS, verglichen mit dem Angebot (Kalkulationsbrain). ClickUp-Status *Rechnung/Zahlung* ↔ Sevdesk-Zahlungsstatus.
7. **Engpass-Intelligenz.** mykilOS beobachtet die Phasendauern (27-T-Entscheidung, 44-T-Mängel, Lieferanten-Verzug) und speist das Feld *Risiko/Engpass* in ClickUp. Lieferanten-Qualität (z. B. Bartels) fließt in die Make-or-Buy-Empfehlung.

## Warum Projekte dann „einfach nur noch sauber durchlaufen"
- **Kein Fehlstart:** mykilOS provisioniert ClickUp mit der vollständigen Routine — jede Phase hat Eigentümer, Checkliste und Automation.
- **Nichts versickert:** Aus @-Mentions werden echte, fällige Tasks; Nachfass- und Beschaffungs-Trigger feuern von selbst.
- **Engpässe sind sichtbar, bevor sie weh tun:** Entscheidung, Fremdgewerke, Mängel und Lieferanten-Verzug haben Flags und Automationen.
- **Voller Kontext auf Knopfdruck:** ein Klick im mykilOS-Cockpit zeigt Aufgabenstand, Dokumente, Kunde, Historie und Marge — ohne fünf Tabs.
- **Eine Wahrheit pro Projekt:** Token + Kdnr verbinden Slack, Drive, Airtable, Clockodo, Sevdesk und ClickUp zu einem Knoten.

## Bau-Reihenfolge (Roadmap)
1. **Jetzt:** ClickUp-Gerüst (UI-Anleitung) + Befüllung mit den 169 Projekten (Connector). *Status: vorbereitet.*
2. **mykilOS liest ClickUp:** Status/Fortschritt je Projekt in den Cockpit-Blick holen (Token/Kdnr-Mapping).
3. **mykilOS provisioniert ClickUp:** neues Projekt in mykilOS → Task + Template + Felder automatisch in ClickUp.
4. **Dokument-Verknüpfung:** Drive-Ordner ↔ Projekt ↔ ClickUp-Checkpunkte (Angebot/AB/Schlussrechnung).
5. **Geld-Loop:** Clockodo + Sevdesk → Ist-Kosten/Marge gegen Angebot.
6. **Engpass-Intelligenz:** Phasendauern + Lieferanten-Qualität → Risiko-Flags & Make-or-Buy.

Die Schritte 1–2 sind sofort machbar (ClickUp-Connector steht, sobald freigegeben). 3–6 wachsen mit mykilOS 6 mit — und jede Stufe bringt für sich schon Nutzen.
