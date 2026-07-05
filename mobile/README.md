# mykilOS Satellit (iOS / iPad)

Die native SwiftUI-App fuers Feld — Gegenstueck zur **Mothership** (mykilOS
Mac-App). iOS und iPad sind **eine** universelle App.

> **Dies ist die EINE Wahrheit.** Alle frueheren Zips (KOMPLETT-1 bis -8,
> Sonnen-Paket, Kreativ-Paket, iPad-Paket, Dev-Kit ...) sind **hiermit
> ausser Dienst.** Ab jetzt gilt nur dieses Repo. Siehe `NAMENSREGELN.md`.

> **Schnellstart:** Zieh diesen Ordner in eine frische Claude-Code-Session
> auf dem Mac und kopiere den Text aus **`START-PROMPT.md`** als erste
> Nachricht — dann macht Claude Git+GitHub+Xcode+Build von selbst.

## Was liegt wo?

```
myMini/                 <- der komplette App-Quellcode, thematisch sortiert
  00-App/               App-Start, Wurzel, iPad-Layout
  01-DesignSystem/      Farben (MykColor), Fehlertexte, Teilen
  02-Cockpit/           Herzschlag-Startseite
  03-Projekte/          Projekt-Modell, Liste, Info, gefuehrter Auftrag
  04-Postbox ... 21-Verbindungen   (je ein Themenbereich, siehe STRUKTUR.md)
  Resources/            projekte.json
docs/                   alle Design- + Schnittstellen-Dokumente
Assets/                 App-Icons
README.md               (diese Datei)
STRUKTUR.md             was jeder Ordner enthaelt
NAMENSREGELN.md         wie wir Chaos vermeiden  <- WICHTIG
REGELN.md               die Bau-Regeln (nicht verhandelbar)
START-HIER-iPAD.md      Startpunkt fuer die iPad-Weiterarbeit
```

## In Xcode oeffnen

1. Neues iOS-App-Projekt "myMini" (SwiftUI, Storage: None) — oder das
   bestehende oeffnen.
2. Den **Ordner `myMini`** aus diesem Repo in Xcode ziehen (als
   Ordner-Referenz / "synchronized group" — dann bleiben die Unterordner
   erhalten und neue Dateien tauchen automatisch auf).
3. `projekte.json` muss im Target sein (Target Membership: myMini).
4. Target -> Supported Destinations: iPhone **und** iPad.
5. Info.plist: die 7 Berechtigungen (siehe `docs/20_BERECHTIGUNGEN.md`).
6. Bauen.

## Die Familie

- **Mothership** (macOS, Repo `mykilOS-7`) = Tresor: kennt User, Rollen,
  traegt alle Keys, Quelle der Wahrheit.
- **Satellit** (dieses Repo, iOS/iPad) = Augen und Haende im Feld.
- Sie reden ueber **Vertraege** (docs/23-27), nicht ueber geteilten Code.
  Details: `docs/27_MOTHERSHIP_FAMILIENBRIEF.md`.
