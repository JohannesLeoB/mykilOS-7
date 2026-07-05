# START HIER — mykilOS Satellit, iPad-Weiterbau

*Dieses Paket ist ein vollstaendiger, sofort GO-faehiger Startpunkt fuer eine
neue Claude-Code-Session, die den iPad-Teil der mykilOS-Satelliten-App
weiterbaut. Alles drin: Code, Regeln, Vertraege. Einfach droppen und loslegen.*

## Was ist das?

Der **Satellit** = die native SwiftUI-App fuers Feld, Gegenstueck zur
**Mothership** (mykilOS Mac-App). **iOS und iPad sind EINE universelle App,
EIN Codebase** - kein getrennter iPad-Fork. Der Code liegt in `Code/`
(alle `.swift` + `projekte.json`), die Design-/Schnittstellen-Dokumente in
`docs/`.

Philosophie: agile Augen und Haende im Feld, die nie ohne Bestaetigung
schreiben. Die Mothership traegt Wissen + Keys, der Satellit erfasst und
schlaegt vor. Zwei-Wege-Familie - siehe `docs/27_MOTHERSHIP_FAMILIENBRIEF.md`.

## Stand (was schon da ist)

Sehr viel: Feld-Kamera, Fang/Postbox, Barcode, Wasserwaage, AR-Massband/
Anker/RoomPlan, Foto-Bemassung (Pencil), Vertrags-Signatur, Service-Anfragen,
Kreativ-Studio mit Firefly-Render, Sonnenverlauf, Laser-Empfaenger,
Satellit-Copilot (Tool-Use), gefuehrter Auftrag, Kopplung, Zwei-Wege-Antenne.

**iPad-Fundament ist schon gelegt** (Startpunkt fuer dich):
- `ContentView.swift` schaltet per `horizontalSizeClass` um: iPhone =
  einspaltiges `GlanceCockpitView` (unveraendert), iPad = `IPadRootView`.
- `IPadRootView.swift` = NavigationSplitView (Sidebar + Detail), Sektionen
  Herzschlag/Projekte/Copilot/Werkzeuge/Kontakte/Verbindungen.
- `IPadProjekteView.swift` = Zweispalter (Projektliste links + gefuehrter
  Auftrag rechts).

## Deine Aufgabe: iPad-Feinschliff

Bau die iPad-Erfahrung aus - Vorschlaege (Prioritaet oben):
1. **Werkzeuge zweispaltig** (Liste links, Werkzeug rechts) wie bei Projekte.
2. **Aufmass-Fokus mit Apple Pencil** - Foto-Bemassung + RoomPlan gross und
   pencil-first auf dem iPad.
3. **Querformat-Feinschliff** + Stage Manager / mehrere Fenster.
4. **Tastatur-Kurzbefehle** (Cmd-Navigation zwischen Sektionen).
5. **Detail-Platzhalter** huebscher gestalten (leere Detailspalte).

## Regeln (NICHT verhandelbar) -> siehe REGELN.md

Kurzform: Karte->Bestaetigung, keine geratenen APIs, ASCII-only in
String-Literalen (Compile-Falle!), `MykColor`-Token, throws-Writes mit
deutschen Fehlertexten, alle Renderstates, Secrets nur Keychain, Clockodo
privat. Lies REGELN.md, bevor du die erste Zeile schreibst.

## Koordination mit iOS + Mothership

- **Die Vertraege sind die Schnittstelle:** `docs/23` (Antenne, Ship->Sat),
  `docs/24` (Rueckkanal, Sat->Ship), `docs/25` (Kopplung), `docs/26`
  (Geraete-Strategie), `docs/27` (Familienbrief). Halte sie ein, dann
  passt alles zusammen, ohne dass ihr euch ins Gehege kommt.
- **iOS-Layer nicht umbauen:** die iPhone-Ansicht (`GlanceCockpitView` und
  die einspaltigen Views) bleibt wie sie ist - du ADDIERST die iPad-Schicht
  (adaptive Weiche steht schon). So kollidiert iPad-Arbeit nicht mit
  iPhone-Arbeit.

## Loslegen

1. Neues iOS-App-Xcode-Projekt "myMini" (SwiftUI, Storage None) ODER
   bestehendes oeffnen.
2. Alle Dateien aus `Code/` in den Quellordner (projekte.json ins Target).
3. Im Target unter "Supported Destinations": **iPad aktivieren**.
4. Info.plist: 7 Berechtigungen (siehe `docs/20_BERECHTIGUNGEN.md`).
5. Bauen. Am iPad(-Simulator) testen.

Viel Spass, kleiner iPad-Satellit. Die Familie wartet auf dich.
