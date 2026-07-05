# REGELN — mykilOS Satellit (iOS/iPad)

Diese Regeln gelten fuer JEDE Session, die an der Satelliten-App baut.
Nicht verhandelbar - sie sind aus echten Fehlern dieses Projekts destilliert.

## 1. Karte -> Bestaetigung
Der Satellit schreibt oder sendet NIE etwas automatisch. Jede Aktion nach
aussen (Upload, Mail, Buchung, Vertrag) laeuft ueber eine Karte, die der
Mensch bestaetigt. Vorschlagen ja, hinterruecks handeln nie.

## 2. Ehrlichkeit ueber alles
- Keine geratenen API-Details/Endpunkte/Protokolle. Wenn etwas nicht
  verifiziert ist, heisst es "generisch/unbestaetigt" und wird sichtbar so
  gekennzeichnet (Vorbild: Leica-Laser = verifiziert, andere = "bitte
  pruefen"). Lieber ehrlich "noch nicht" als eine still falsche Zahl.
- Keine erfundenen Daten als Platzhalter - lieber ein ehrliches "kommt vom
  Mothership".

## 3. Compile-Fallen (haben schon zweimal zugeschlagen)
- **ASCII-only in String-LITERALEN.** Keine typografischen Anfuehrungs-
  zeichen (aus einer anderen Tastatur) in `"..."` - sie brechen den Build in
  der Uebertragung. In Kommentaren ok, in Strings NIE.
- **Section-Form:** `Section { } header: { Text("...") } footer: { }` -
  NIEMALS `Section("Titel") { } footer:` (ist ungueltig).
- **Explizite imports** fuer jeden benutzten Framework-Typ (CoreLocation,
  QuickLook, CoreBluetooth ...).

## 4. Design-Token
Farben nur ueber `MykColor.*` (brand/ink/muted/line/card/paper/ok/crit/
drive/plum/ocker/sage). Keine hartkodierten `Color(...)` in Views.

## 5. Persistenz
- `@Observable`-Store, JSON in Documents, **`throws`-Writes**, Fehler ueber
  `Fehlertext.deutsch(error)`.
- **Rueckwaertskompatibel:** neue Codable-Felder als Optional ODER mit
  `decodeIfPresent(...) ?? default` - sonst crasht das Laden bestehender
  JSON-Dateien (echter Stolperstein: FeldFoto).
- Cold-Start-Denke: schreiben -> neue Instanz -> lesen -> identisch.

## 6. Renderstates
Jede datenladende View hat alle Zustaende: leer / laedt / Fehler /
keine-Berechtigung. Quelle sichtbar machen.

## 7. Datenschutz & Secrets
- Tokens/Keys NUR im Keychain. Nie in Code, Chat, Repo, Logs.
- **Clockodo ist nutzer-privat** - nie teamweit, nie in geteilten Logs.
- Harte NO-GOs: Sevdesk nie lesen/schreiben; die geteilte Airtable-Base
  `appkPzoEiI5eSMkNK` nie anfassen; Airtable-Eintraege NIE loeschen/direkt
  ueberschreiben (nur Status/Archiv-Feld).

## 8. Prozess
- Kleine, klare Commits (ein Baustein = ein Commit).
- iOS und iPad = EIN Codebase (universelle App). Die iPhone-Ansicht nicht
  umbauen; die iPad-Schicht additiv (adaptive Weiche via horizontalSizeClass).
- Die Vertraege in `docs/23`-`27` sind die Schnittstelle zur Mothership -
  einhalten, nicht umgehen.
