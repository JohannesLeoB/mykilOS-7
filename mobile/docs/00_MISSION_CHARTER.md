# Mission Charter — mykilOS mobile

**Stand: 2026-07-03 · Orientierungssession „mykilOS 10 mobile"**

---

## Nordstern

> **Nicht „mykilOS, aber kleiner". Sondern „mykilOS, wie es sich bewegt, wenn du dich bewegst."**

Der Mac (mykilOS 10) ist das **Mothership** — Gewicht, Macht, Präsenz, Häfen und Docks.
Er rechnet, provisioniert, baut Warenkörbe, rendert Angebote, hält die Wahrheit. Sacred.

Das iPhone ist der **Satellit** — leicht, klein, konzentriert. Er kommt dorthin mit,
wohin das Mothership nie fliegt: auf die Baustelle, ins Auto, zum Kunden, in die Stadt.

## Vision (ein Satz)

**mykilOS mobile fängt die Momente, die das Mothership strukturell nicht sehen kann —
und verräumt sie RAIL-rein an die richtigen Sterne.**

## Die zwei Kern-Erkenntnisse dieser Session

### 1. Container → Dirigent
Auf dem Mac ist mykilOS ein **Container**: jedes Widget muss ins Fenster.
Auf dem iPhone ist der **Homescreen schon das Widget-Board** — Clockodo, Drive,
Google Maps, Slack, ClickUp liegen als native Apps bereit (live gesehen 03.07.).
Sie rendern, navigieren, buchen besser, als ein Nachbau es je könnte.

→ Der Satellit baut sie **nicht nach**. Er wird das **Gehirn**, das den Projekt-Graphen
hält (Airtable = System-of-Record) und **kontextscharf dorthin dirigiert**. Das ist der
Hub, den die Silo-Apps nicht haben — und er wird dadurch *leichter*, nicht schwerer.

### 2. Der Motor sitzt schon in der Tasche
mykilOS mobile **v0 muss nicht gebaut werden** — es ist Claude + die Connectoren,
im Feld. Die native App später ist nur der **schöne Mantel** um ein Verhalten, das
heute schon funktioniert.

## Der Dreitakt jedes Feldmoments

> **Fang → Versteh → Verräum.**
> Du fängst (Stimme/Foto/Ort). Ich verstehe (Chaos → Struktur). Ich verräume
> (route zum richtigen Stern, RAIL-rein). Du gehst weiter.

## Die vier hellsten Sterne (gerankt nach Leuchtkraft ÷ Gewicht)

| # | Stern | Was in der Tasche | Gewicht | RAIL |
|---|---|---|---|---|
| ★1 | **Zeit fangen per Stimme** | „4h CAD für Heinz" → private Clockodo-Postbox. Der Moment verglüht nicht. | federleicht | Postbox, nie direkt ✅ |
| ★2 | **Glance-Cockpit** | Ein Blick: Projekte, heutige Termine, neueste Angebote, Cash-Zeile. | leicht (read-only) | nur Lesen ✅ |
| ★3 | **Feld-Sensor** | Kamera im Feld: Lieferschein/Kontakt/Angebot → Projektordner/Pipeline. | mittel | Drive read-only → **Upload via Postbox** ⚠️ |
| ★4 | **Claude selbst, im Gespräch** | Das Bindegewebe. Auf mobile *ist das Gespräch die Oberfläche.* | leicht | — |

**Feldkontexte, in denen die Sterne leuchten:** beim Kunden (Vorab-Briefing,
Gesprächsnotiz, Follow-ups) · beim Termin vor Ort (Aufmaß-Foto, Zeit fangen,
Navigation) · Beobachtungen in der Stadt (Material/Detail/Ort → Moodboard/Kontakt) ·
Ideen & Momente (Geistesblitz fangen, bevor er weg ist).

## Zwei komplementäre Schreib-/Lesemodelle

- **Deep-Link = Hinspringen** (read/navigate): öffne Maps an dieser Adresse, diesen
  Drive-Ordner, diese ClickUp-Liste. Federleicht.
- **Postbox = Schreiben** (★1, Feld-Uploads): mykilOS schreibt nur in seine **eigene**
  Airtable-Postbox; das Mothership/der Mensch gleicht ab. Deep-Links können kein
  vorbefülltes „4h CAD" an die Clockodo-App übergeben — deshalb Postbox.

## Was mykilOS mobile bewusst NICHT ist (Gewichtsdisziplin)

- **Kein zweites Mothership.** Die schwere Rechnung (Kalkulations-Engine, PDF-Render,
  Warenkorb *bauen*, Fragebogen *ausfüllen*) bleibt oben. In der Tasche: Anker + Fang.
- **Kein Nachbau der nativen Apps** (Drive/Maps/ClickUp/Clockodo). Dirigieren, nicht rendern.
- **Kein Skalieren des dichten Desktop-Layouts.** Der Stern selbst warnt: iPhone braucht
  *anders denken*, kein Verkleinern (Mehrspalten-Kataloge/Mail/Warenkorb).
- **Kein Boss Button** — macOS-Gimmick, verworfen (Johannes 03.07.).

## Entschieden (Johannes, 2026-07-03 spät)

- **Ziel = echte mykilOS iOS/iPadOS-App** — „in sich rund, verknüpft und lebendig."
  Die alte A/B-Weiche ist gestellt: **B ist der Weg, A ist das Ziel.** v0 (Claude +
  Connectoren) beweist das Verhalten im Feld; die native App gießt es in Form.
- **iPhone UND iPad** — eine SwiftUI-App, zwei Formate: iPhone = Momente-Fänger,
  iPad = Baustellen-Cockpit. Versöhnt Backlog-Rat („iPad zuerst") mit Johannes' These.
- **Team-only Distribution: 5–8 Nutzer, perspektivisch. Keine Öffentlichkeit.**
  Kein App Store, kein Review. Verteilweg: **TestFlight** (interner Kanal).
  Konsequenz: bezahlter Apple-Developer-Account (99 €/Jahr, einer) wird **erst zur
  Verteilung** fällig — Entwicklung + Test auf eigenem Gerät läuft mit freier Apple-ID.
- Das Mothership-Team-Modell (per-User-Keychain, private Postboxen, nichts
  kreuzlesbar) ist für genau diese Crew-Größe schon gebaut — der Satellit erbt es.

## Offene Weichen (bewusst noch nicht entschieden)

- **★3 Feld-Upload-Schreibpfad** — Baufreigabe erteilt (04.07.), lokaler Teil gebaut
  (Kamera/Bestätigung/Ablage). Google-Sign-In + echter Drive-Write offen, siehe
  `playbooks/03_feld-foto-verraeumen.md` (inkl. ungeprüfter drive.file-Annahme).
