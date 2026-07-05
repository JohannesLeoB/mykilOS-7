# Briefkasten-Protokoll — Screenshots & Feedback

**Deal (Johannes, 2026-07-03):** Random Screenshots wandern in einen Briefkasten.
Auf Zuruf („schau in deinen Briefkasten") schaue ich rein und gebe Feedback.

## Regeln

1. **Neue Dateien → neues Feedback.** Nur die seit dem letzten Blick.
2. **Alte, schon besprochene Screenshots → nie wieder ungefragt lesen.**
   Sie haben ihr „gemeinsames Verständnis" geliefert. Nur auf ausdrücklichen Zuruf.
3. Jede gesehene Datei wird im **Ledger** (unten) notiert: Name/Datum + Kernbefund.
   So weiß jede Session — egal welches Gerät oder Konto — was schon verstanden ist.

## Schlitz (entschieden 2026-07-03)

- **Chat-Upload:** Johannes wirft alles direkt in den Chat. Kein Drive-Ordner nötig.

## Triage bei jedem spontanen Einwurf (Pflicht)

Bei jedem spontanen Drop frage ich **kurz** (eine Zeile, nie mehr):

> **„Feedback/Idee — oder brennt's?"**

- **Feedback / Dateien / Ideen** (Default, z. B. Duschgedanke): ich verbuche im Ledger
  bzw. Ideen-Topf und **störe den laufenden Takt nicht** — weitergearbeitet wird am
  aktuellen Faden, der Einwurf wartet geduldig.
- **ES BRENNT 🔥**: alles stehen lassen, sofort da.
- Wenn der Kontext es eindeutig macht (z. B. „BUG!!!" oder ein beiläufiges „nur als
  Inspo"), darf die Frage entfallen — im Zweifel immer fragen.

Sinn: Johannes darf jederzeit einwerfen, ohne den Takt zu stören — die Triage
sortiert, nicht der Zeitpunkt.

## Ledger — gesehene Einwürfe

| Datum | Einwurf | Kernbefund (gemeinsames Verständnis) |
|---|---|---|
| 2026-07-03 | 3× GitHub mobil (IMG_5834–5836) | Repo-Drift aufgedeckt: mykilos8/V10-Branches + 11 Tags existierten, mein lokaler Stand war 7.7.2-blind → fetch-Reflex geboren |
| 2026-07-03 | 4× iPhone-Homescreen (IMG_5837–5840) | Clockodo/Drive/Maps/Slack/ClickUp nativ auf dem iPhone → Dirigent-statt-Container-Doktrin |
| 2026-07-03 | 3× MacBook-Fotos (photo.jpeg ×3) | mykilOS 10.0.0-**alpha5 läuft lokal, nicht gepusht** (Galerie, Kataloge/Aufgaben-Fangfläche, Drive-Spinner „6/37" = Container-Schmerz) |
| 2026-07-03 | 1× MacBook-Foto (Claude-Session) | Zwei parallele Claude-Sessions auf dem MacBook sichtbar; Warnung verankert: Satelliten-Ordner NIE in mykilOS-7/mykilOS6 anlegen |
| 2026-07-03 | 1× iPhone Dateien-App (IMG_5845) | Google Drive sitzt als Speicherort in der iOS-Dateien-App → Briefkasten-Einwurf so bequem wie iCloud; Ordner direkt dort anlegbar |
| 2026-07-03 | 1× Bestandsküchen-Foto (Concept Case) | Ersttermin-Szenario: Versteh-Demo auf echtem Foto; 8 Sensor-Ideen in den Topf; LiDAR/AR = Kernargument für native App; Drive-Upload bleibt RAIL-gesperrt (STERN-3) |
| 2026-07-03 | 5× Maßband-Live-Test (IMG_5846–5850) | Johannes misst real 1,2m/1,23m an eigener Zeile; Erstaufnahme+Strom/Wasser aus Fotos komponiert; Kette Foto-Aufmaß→schaetze-Engine erkannt; Drei-Toleranzen-Doktrin (cm/2cm/mm) verankert |
| 2026-07-04 | Inspo-Wurf iPad+Pencil (Text) | 5 Funken in den Topf (Skizze-auf-Foto, Redlining, Unterschrift, Scribble→Versteh, Zeichenbrett-Rolle); bewusst NICHT vertieft — Takt gehalten |
| 2026-07-04 | 1× iPad-Homescreen-Foto | Onshape+Freeform+Kurzbefehle+Drive/Slack an Bord → Dirigent-These auch am iPad; ältere Gen ohne LiDAR → Zeichenbrett ja, RoomPlan nein |
| 2026-07-04 | 2× Laser-Recherche-Screens (MacBook) | DISTO-Bruecke von heute Abend bereits von Johannes weiterrecherchiert; Hersteller-Apps koennen Mass-aufs-Foto → einsammeln statt nachbauen; iPad-7-Peilung bestaetigt; Hustadt als reales Zielprojekt sichtbar |

## Kommunikations-Regel (Johannes, Nacht 03./04.07.)

Kein voreiliges „Gute Nacht"/Abschieds-Framing. Die Session endet, wenn Johannes
es sagt — nicht, wenn ein Bericht fertig ist. Berichte enden offen und auf Empfang.

## Auslieferungs-Regel (Johannes, 04.07. ~12:10)

**„Ich bin Laie, ich brauche da immer etwas mehr Hilfe."** Ab jetzt bei jedem
fertigen Baustein (nicht nur am Nacht-Ende): Zip in den Chat mit dem aktuellen
`App/MyMini`-Code **plus** einer `EINFUEGEN.md` in einfacher Sprache. Wenn
Terminal-Befehle nötig sind (selten — die meisten Auslieferungen sind reines
Finder-Drag-and-drop, kein Terminal): als klar nummerierte, einzeln
kopierbare Liste, so knapp wie möglich.

**Reibungspunkt, den Johannes benannt hat:** er tippt hier vom iPhone/iPad,
muss Befehle aber auf dem Mac ausführen — aktuell per AirDrop über die
iPhone-Notizen-App, umständlich. Kein technischer Fix von meiner Seite
möglich (kein direkter Mac-Zugriff) — aber: wo immer ein Terminal-Befehl
vermeidbar ist (z. B. durch Drag-and-drop statt `git clone`), vermeiden.
Wo unvermeidbar: genau EIN Befehl pro Zeile, nichts davor/danach in derselben
Zeile, damit Copy-Paste (über welchen Umweg auch immer) nichts Falsches
mitnimmt — direkter Auslöser dieser Regel war ein Bridging-Header, der
versehentlich einen `git clone`-Befehl aus dem Chat abbekam und den Build
brach.

## Mission-Control-Relais (Johannes, 04.07. ~16:15 — „so dribbeln wir die Pille weiter")

**Die bessere Antwort auf denselben Reibungspunkt, live entdeckt beim
Xcode-Neuaufsetzen:** Auf dem Mac läuft ohnehin eine Mothership-Claude-Session
(„Mission Control") mit echten Händen am Dateisystem. Der Satellit hat keine —
aber er kann **fertig formulierte Aufträge** liefern, die Johannes nur noch
per Copy-Paste an Mission Control durchreicht. Erster erfolgreicher Einsatz:

> „Entpacke die Datei mykilOS-mobile-KOMPLETT.zip aus meinen Downloads und
> kopiere alle Dateien daraus in den Quellordner meines neuen Xcode-Projekts
> myMini — dorthin, wo die ContentView.swift der Vorlage lag. Vorhandene
> Dateien ersetzen. Sag mir danach den genauen Ordnerpfad."

**Regel ab jetzt:** Wo eine Lieferung Dateisystem-Arbeit auf dem Mac braucht
(entpacken, kopieren, verschieben, Pfade finden), enthält die `EINFUEGEN.md`
zusätzlich einen **fertigen Mission-Control-Satz** in Anführungszeichen —
deutsch, präzise, endend mit einer Rückmelde-Aufforderung („Sag mir
danach…"), damit Johannes das Ergebnis zurücktragen kann. Anforderungen:

- **Selbsterklärend ohne unseren Chat-Kontext** — Mission Control kennt
  diese Session nicht; alles Nötige (Dateiname, Quellort, Zielbeschreibung)
  muss im Satz selbst stehen.
- **Beschreibend statt pfad-hart**, wo der Satellit den echten Pfad nicht
  kennen kann („dorthin, wo die ContentView.swift der Vorlage lag") — Mission
  Control sitzt vor Ort und findet ihn.
- **Nie destruktiv formuliert** — kein „lösche", höchstens „ersetze
  vorhandene Dateien"; Aufräumen entscheidet Johannes mit Mission Control.

**Ehrliche Grenze:** Xcode-GUI-Schritte (Häkchen, Signing-Team,
Berechtigungs-Tab, ⌘R) kann auch Mission Control nicht klicken — die bleiben
als knappe Mensch-Schritte in der `EINFUEGEN.md`. Das Relais ersetzt die
Dateisystem-Fummelei, nicht die zwei Klicks in Xcode.

| 2026-07-04 | 2× Ofen + Typenschild (Rundgang-Demo) | Live-Beweis ③: BEJUBLAD eindeutig identifiziert (Serial-Match im Ersatzteilhandel), Geräteakte in <2 Min — Typenschild-Pfad BEWIESEN |
