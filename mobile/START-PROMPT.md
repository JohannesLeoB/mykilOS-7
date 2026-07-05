# START-PROMPT — einmal kopieren, in eine frische Claude-Session auf dem Mac

*So geht's: Entpacke `mykilos-mobile.zip`. Zieh den entstandenen Ordner
`mykilos-mobile` in ein neues Claude-Code-Fenster auf deinem Mac (oder oeffne
die Session in diesem Ordner). Dann kopiere den Text unten (zwischen den
Linien) als deine erste Nachricht. Der Rest passiert von selbst.*

---------------------------------------------------------------------

Du bist mein iOS-Entwicklungs-Assistent auf meinem Mac. In diesem Ordner
liegt das Projekt `mykilos-mobile` — die native iOS/iPad-App "mykilOS
Satellit", Gegenstueck zur mykilOS-Mac-App (Mothership).

Lies ZUERST diese drei Dateien im Ordner, sie enthalten alles Noetige:
`README.md`, `REGELN.md`, `START-HIER-iPAD.md`. Die Bau-Regeln in
`REGELN.md` sind nicht verhandelbar (besonders: ASCII-only in String-
Literalen, `Section { } header: { } footer: { }`-Form, explizite imports,
rueckwaerts-kompatible Codable-Decoder, MykColor-Token, Karte->Bestaetigung).

Dann bring die App LOKAL zum Laufen, in dieser Reihenfolge:

1. **Verwurzeln (Git + GitHub):** mach den Ordner zu einem Git-Repo,
   committe alles ("Seed: Satellit-Grundstand"), lege unter meinem
   GitHub-Account ein PRIVATES Repo `mykilos-mobile` an und pushe `main`.

2. **Xcode-Projekt:** erstelle ein neues iOS-App-Projekt namens `myMini`
   (Interface SwiftUI, Storage None) — oder nutze ein vorhandenes. Fuege den
   Ordner `myMini/` (mit allen Unterordnern 00-App bis 21-Verbindungen +
   `Resources/projekte.json`) als synchronisierte Ordner-Gruppe hinzu.
   `projekte.json` muss Target-Mitglied sein. Supported Destinations:
   iPhone UND iPad. Trage die 7 Info.plist-Berechtigungen aus
   `docs/20_BERECHTIGUNGEN.md` ein.

3. **Bauen (Cmd+B):** behebe alle Compile-Fehler. Beachte dabei
   `docs/21_COMPILE_LEKTIONEN.md`. Aendere so WENIG wie moeglich, keine
   Features umbauen, jede Korrektur kurz dokumentieren.

4. **Starten:** starte die App im iOS-Simulator (erst iPhone, dann iPad) und
   melde mir: Baut sie? Laeuft sie? Mach je einen Screenshot. Bei Fehlern:
   zeig mir die exakte Fehlerzeile und was du geaendert hast.

Halte dich strikt an `REGELN.md`. Committe in kleinen Schritten. Frag nur,
wenn eine Entscheidung wirklich meine ist (externe Konten, Design, Business).

---------------------------------------------------------------------

Wenn die App laeuft: du hast Wurzeln geschlagen UND bist gestartet. 🛰️
