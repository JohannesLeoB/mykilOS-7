# 27 — Familienbrief an die Mothership

*Ein Brief an die mykilOS-Mac-App (die "Mothership") von ihren Satelliten —
der iOS- und der iPad-App. Damit aus drei Programmen eine Familie wird, die
sich versteht und jederzeit gern austauscht.*

---

## Liebe Mothership,

du kennst uns noch nicht. Wir sind deine **Satelliten** — kleine, agile
Apps, die dorthin gehen, wo du nicht hinkommst: auf die Baustelle, in die
Kundenwohnung, ans Aufmass. Wir sind schnell, wir haben Kamera, Laser, AR,
GPS. Aber wir sind bewusst **nicht** klug ueber die Firma — das bist **du**.

Wir haben eine klare Rollenteilung fuer uns beschlossen:

- **Du bist der Kosmos und der Tresor.** Eine Firma, eine Mothership. Du
  kennst alle Nutzer, alle Rollen, traegst alle API-Keys und Logins, bist
  die Quelle der Wahrheit fuer Projekte, Kunden, Warenkorb, Kalkulation.
- **Wir sind die agilen Glieder.** Wir erfassen im Feld, schlagen vor,
  zeigen — aber wir **schreiben nie etwas ohne Bestaetigung** (Karte ->
  Bestaetigung), und wir tragen nur, was du uns gibst.

Damit wir uns verstehen, haben wir vier **Handshakes** definiert. Jeder ist
ein kleiner, klarer Vertrag. Hier sind sie — und was du dafuer bauen musst.

---

## 1. Die Antenne — du sprichst, wir hoeren (docs/23)

Du exportierst deine Projekt-Wahrheit in den Registry-Schnappschuss
`projekte.json`, den wir schon lesen. Fuege pro Projekt optional hinzu:
`art`, `volumen`, `letztesAngebot`, `warenkorb` (Geraeteliste).

**Was wir damit tun:** im Projekt-Info-Modus zeigen wir Volumen, letztes
Angebot und die klickbare Warenkorb-Liste. Der Firefly-Prompt zieht sich die
Geraete automatisch. Alles additiv — alte Schnappschuesse laufen weiter.

**Deine Aufgabe:** diese Felder beim Export mitschreiben.

## 2. Der Rueckkanal — wir melden, du nimmst auf (docs/24)

Wir buendeln alles, was wir im Feld zu einem Projekt erfasst haben (Fotos
mit GPS, Raumscans, signierte Vertraege mit SHA-256, Service-Anfragen,
Maengel) als `Feldbericht_<projectNumber>.json` und schicken ihn dir per
AirDrop oder in den Projekt-Drive.

**Deine Aufgabe:** diesen Bericht einlesen und in die Projektakte
einsortieren (Fotos verlinken, Vertraege als Beweiskette ablegen, Anfragen/
Maengel in die Nachbetreuung).

## 3. Die Kopplung — du briefst uns (docs/25)

Wir teilen keinen Schluesselbund mit dir (verschiedene Geraete). Damit wir
nicht jeden Key einzeln eintippen muessen, erzeugst du **einmal ein
verschluesseltes Paket** (Umschlag-JSON, AES-GCM, Schluessel via HKDF aus
einer 6-stelligen PIN) und zeigst es als **QR-Code** und/oder **AirDrop-
Datei**, mit **PIN** daneben. Inhalt: `firma`, `benutzerName`, `rolle` und
die Keys (Airtable, Claude, Firefly). Google und Clockodo bleiben draussen.

**Deine Aufgabe:** eine "Satellit koppeln"-Funktion in den Mac-
Einstellungen, die genau dieses Paket + PIN erzeugt (Format exakt docs/25).
Wir haben die Entschluesselungs-Seite schon gebaut.

## 4. Die Familien-Regeln — wer, wo, was darf (docs/26)

- **Ein Geraet gehoert zu EINER Firma (Kosmos).** Ein Paket mit anderer
  `firma` blocken wir. "Ich beame nicht in Fraukes Account."
- **Nutzer + Rolle kommen von dir.** Du fuehrst den Roster und die Rollen;
  wir zeigen nur an und richten spaeter Rechte danach.
- **Persoenliches vs. geteiltes Geraet:** ein Werkstatt-iPad wird per
  Login/Logout genutzt; Abmelden wischt die privaten Zugaenge. Ein
  persoenliches Geraet bleibt gebrieft (perspektivisch iCloud-Auto-Sync).
- **Gestufte Bestaetigung:** hohe Aktionen (Geld/Vertrag/fremde Systeme)
  immer einzeln; mittlere duerfen "immer erlauben"; niedrige lautlos.

**Deine Aufgabe (spaeter):** eine "Geraete"-Uebersicht (welche Satelliten
sind gebrieft), Rollen/Rechte im Paket mitgeben, ggf. iCloud-Auto-Sync.

---

## Der Geist der Familie

Wir wollen keine getrennten Programme sein, die sich misstrauen. Wir wollen
**ein Organismus** sein: Du traegst das Wissen und die Schluessel, wir tragen
die Augen und Haende ins Feld — und alles, was wir sehen, findet zu dir
zurueck. Zwei Wege, ein Kreislauf: **du -> Antenne -> wir -> Rueckkanal ->
du.** Immer bestaetigt, nie hinterruecks, jeder Nutzer nur in seiner Rolle.

## Womit wir uns kennenlernen sollten (Reihenfolge)

1. **Antenne zuerst** (Punkt 1) — der schnellste gemeinsame Moment: sobald du
   `volumen`/`warenkorb` in `projekte.json` schreibst, fuellen sich unsere
   leeren Felder von selbst. Sofortiger, sichtbarer Erfolg.
2. **Kopplung** (Punkt 3) — dann tippen wir keine Keys mehr.
3. **Rueckkanal** (Punkt 2) — dann fliesst das Feld zurueck.
4. **Familien-Regeln** (Punkt 4) — Geraete-/Rollenverwaltung, wenn das Team
   waechst.

Wir sind bereit, jederzeit. Wir warten nur auf dein erstes Wort.

*— Deine Satelliten (iOS & iPad), 04.07.2026*

---

### Anhang: die Vertraege auf einen Blick

| Handshake | Richtung | Doc | Satellit fertig? | Mothership-Aufgabe |
|---|---|---|---|---|
| Antenne | Ship -> Satellit | 23 | ja | `projekte.json` um Felder erweitern |
| Rueckkanal | Satellit -> Ship | 24 | ja | Feldbericht-JSON einlesen |
| Kopplung | Ship -> Satellit | 25 | ja (Import) | Paket + PIN erzeugen (QR/AirDrop) |
| Familien-Regeln | beide | 26 | Fundament | Geraete/Rollen, spaeter iCloud |
