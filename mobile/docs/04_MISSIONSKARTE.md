<!-- Erstellt 2026-07-03 durch Fable-Ultracode-Kartierung (6 Domaenen read-only + Synthese). Mothership-Peilung: dababdb. -->

# mykilOS mobile — Missionskarte

## Nordstern (ein Satz)

mykilOS mobile ist der Satellit des macOS-Motherships — er fängt Feldmomente (Fang → Versteh → Verräum) und dirigiert die schon vorhandenen nativen iPhone-Apps RAIL-rein, statt sie nachzubauen; die Verfassung lautet unverändert **minimal · functional · smart · beautiful**.

---

## Die Planeten (Mothership + geteilte Integrationen)

**Mothership mykilOS V10** (macOS, SwiftUI, local-first, GRDB). Kernprinzip „Verbindung statt Fähigkeit": der echte Schneider-Auftrag läuft EINMAL komplett durch — Fragebogen → Kunde+Projekt → GRDB-persistierter WorkBasket → ein Klick „Zum Angebot" (lokale beschriftete MYKILOS-PDF-Vorschau) → Cash-Zeile „Kalkuliert (Warenkorb)". Stand: **10.0.0-alpha4**, Blocks A–H gebaut, **894+ Tests grün**, DMG signiert. **Offen: Block I = Live-Abnahme (Schneider-Lauf durch Johannes gegen Screenshots), dann Block J = 10.0.0 final.** Rückfallebenen: 9.0.0, 8.8.0-SAFETY, v7.0.0-Goldstand.

Die geteilten Integrationen sind fast durchgängig read-only mit hart verdrahteten RAILs:

| Planet | Draht | RAIL (hart) |
|---|---|---|
| **Airtable** (System-of-Record, `appuVMh3KDfKw4OoQ`) | READ (Registry) + WRITE nur append-only in 2 Schaltzentrum-Tabellen (Code-Whitelist) | NIE DELETE/PATCH bestehender Records; geteilte Base `appkPzoEiI5eSMkNK` tabu; Daniels Artikel-Base `appdxTeT6bhSBmwx5` nur lesen |
| **Google Drive** (PROJEKTE, 31 Ordner) | READ-only + EIN gated Write (Fragebogen-PDF, `drive.file`) mit NO-GO-Guard | Angebots-PDF NICHT nach Drive — lokal ablegen; geteilter Root read-only |
| **Google Kalender** | READ-only (Opt-in-Tool) | Termine nur via Karte→Browser-URL, nie direkter API-Write |
| **Gmail** | READ-only (Opt-in-Tool + Cache) | Mail SENDEN bewusst NICHT in V10; nie kreuzlesbar |
| **ClickUp** | READ-only, code-fertig; wartet auf Listen-IDs (M3) | Nur Testspace `90128024109` + Ghost-Personas; Ghost→Live nicht V10 |
| **Clockodo** | READ-only live, per-User-Keychain | Kein direkter POST — nur private Airtable-Postbox mit Bestätigung; jeder nur eigene Daten |
| **Slack** | READ-only, indirekt (destilliertes `studio_brain.json`, kein Live-Call) | Nur lesen/destillieren, keine Writes |
| **Sevdesk** | READ-only (Ist-Umsatz); B6 wartet auf M4 | „NIE als Assistant-Tool"; Schreiben nur perspektivisch via Postbox (V11+) |
| **Claude/Anthropic** | BIDIR, live (einzige Zwei-Wege-Weiche) | Opt-in für Tool-Daten; externe Writes nur Karte→Bestätigung→Audit |

---

## Der Satellit (die vier Sterne, Container → Dirigent)

**Kern-Doktrin:** Auf dem Mac ist mykilOS ein *Container* (jedes Widget muss ins Fenster). Auf dem iPhone ist der Homescreen schon das Widget-Board — die nativen Apps (Clockodo, Drive, Maps, Slack, ClickUp) rendern/navigieren/buchen besser als jeder Nachbau. Der Satellit wird das **Gehirn, das den Projekt-Graphen hält (Airtable = System-of-Record) und dirigiert.** Zwei Modelle: **Deep-Link = Hinspringen** (read/navigate, federleicht) · **Postbox = Schreiben** (eigene Airtable-Postbox, Mothership/Mensch gleicht ab).

- **★1 Zeit fangen per Stimme** — „4h CAD für Heinz" → private Clockodo-Postbox (Airtable). Federleicht, hellster Stern. Tabellen liegen bereit (Clockodo-Nutzer/-EW-/-Buchungen). RAIL: nie direkt in Clockodo. *Postbox-Architektur noch offen.*
- **★2 Glance-Cockpit** — ein Blick: Projekte, heutige Termine, neueste Angebote, Cash. Read-only, unkritisch. Die 8 Mothership-Widgets werden **destilliert, nicht gespiegelt.**
- **★3 Feld-Sensor (Kamera → Postbox)** — Lieferschein/Kontakt/Angebot fotografieren → Projektordner/Pipeline. ⚠️ **Einzige noch ungelöste RAIL-Stelle:** Drive bleibt read-only, ein erlaubter Postbox-Upload-Kanal fehlt.
- **★4 Claude im Gespräch** — das Bindegewebe; auf mobile ist das Gespräch selbst die Oberfläche. Trägt die v0-These. Faktisch heute schon funktionsfähig.

**Was Mobile NICHT ist (harte Nicht-Ziele):** kein zweites Mothership (Kalkulations-Engine, PDF-Render, Warenkorb-Bau bleiben oben) · kein Nachbau der nativen Apps · kein Verkleinern des dichten Desktop-Layouts · kein Boss Button (verworfen).

---

## Der Kompass (Vision, RAILs, Reality-Check-Ritual)

**Vision:** minimal (Schärfe statt Länge, verdrahten statt bauen) · functional (ein Faden läuft real durch, grüne Tests ≠ fertig) · smart (schon Gebautes zu einem Faden verdrahten) · beautiful (zählt am ersten echten Kundendokument, Abnahme live gegen Screenshots).

**RAILs (Verfassung des Satelliten, geerbt via Kopie statt Draht):**
- **§I Zwei-Basen-Doktrin:** Trennung nach *Repo, nicht Branch*. Tank A (mykilOS-7) = READ-ONLY für immer. Tank B (mykilos-mobile) = einzige Arbeitsbasis.
- **§II Treibstoff-Trennung:** in Tank A nur lesende git-Befehle; Schreib-Ops ausschließlich mit explizitem `git -C <Tank-B>`; kein gemeinsames Remote.
- **§II-b Konto-Hopping:** die Grenze ist der Tank, nicht Konto/Gerät/Session (Johannes springt zwischen 2 Max-Accounts, teils parallel). Jedes Gehirn schreibt nur in seinen Tank; geteilte Welt nur lesen/append-only. Preis = Drift → `fetch` Pflicht.
- **Geerbt:** main heilig (kein Force-Push) · externe Writes nur gated Karte→Bestätigung→Audit · Sevdesk/Clockodo nie direkt (nur Postbox) · Airtable nie DELETE · Drive read-only · ClickUp nur Testspace · Per-User-Isolation · Aufgaben nur Mensch→Mensch · Kosten als Design-Kriterium.

**Reality-Check-Ritual (§IV, vor jedem Thematisieren, lieber 8× zu viel):** 1) `fetch` auf Tank A — hat sich der Himmel verschoben? 2) frischesten Branch + Version identifizieren, 3) mit Johannes abgleichen: gepusht oder nur lokal? 4) erst DANN reden — kein 7.7.2-Gespenst in die Planung lassen. *(In dieser Kartierung angewendet.)*

---

## Der Treibstoff (zwei Tanks + Voraussetzungen, inkl. ehrliche Apple-Realität)

- **Tank A — mykilOS-7 (Mothership):** ermöglicht Lesen der ganzen Sternenkarte; blockiert JEDES Schreiben, für immer. Heilig, READ-ONLY.
- **Tank B — mykilos-mobile:** eigenes Git-Repo im Scratchpad (Charter, Star Map, RAILs, Playbooks, `aim.sh` — null macOS-Code). Einziger Schreib-Ort. **Ephemer:** überlebt kein Container-Recycling; eigenes GitHub-Remote steht als nächster Zündschritt aus (braucht Johannes' Nicken).
- **Wrong-Star-Wächter `bin/aim.sh`:** Preflight vor jeder git-Schreibaktion — erkennt das Mothership am Toplevel-Basename ODER Remote-URL (bewusst nicht am Pfad-Teilstring, da der Scratchpad selbst „mykilOS-7" enthält). `write` auf Mothership → exit 1. **Grenze: Konvention, kein erzwungener Git-Hook — schützt nur, wenn aufgerufen.**

**Ehrliche Apple-Realität:** Johannes ist **privater Apple-ID-Nutzer, KEIN zahlender Developer.** Freies Signing (Xcode Personal Team) aufs eigene iPhone geht kostenlos, aber das Profil läuft nach **7 Tagen** ab und muss neu signiert werden. **KEIN TestFlight, KEINE Store-Verteilung, KEINE Push-Notifications** ohne Developer Program (99 USD/Jahr). Dieser Status ist real, aber in den Tank-B-Docs **noch nicht schriftlich verankert.**

---

## Die Kapsel (v0 Claude+Connectoren → später native App, Portier-Landkarte)

**Stufe v0 — Claude + Connectoren:** läuft heute, kein Xcode, kein Apple-Account, kein Port. Deckt Fang→Versteh→Verräum bereits ab.

**Stufe v1 — native iOS-App** (Voraussetzung: Xcode + Signing). Portier-Landkarte, per Grep verifiziert:

| Target | Mobil-Tauglichkeit |
|---|---|
| **MykilosKit** | 1:1 teilbar (Foundation-only, kein SwiftUI/GRDB) |
| **MykilosKalkulationsCore** | 1:1 teilbar (11 Dateien, nur Foundation) |
| **MykilosServices** | weitgehend tauglich (GRDB läuft auf iOS) — **einziger harter Blocker: `GoogleOAuthLoopbackRedirectServer.swift`** (localhost-Redirect ist Desktop-Muster → braucht `ASWebAuthenticationSession` + Custom-Scheme) |
| **MykilosDesign** | tauglich (kleine Prüfung auf macOS-only-APIs) |
| **MykilosWidgets** | teils tauglich (Anpassung nötig, auf Mac-Fenster ausgelegt) |
| **MykilosApp (Shell)** | **Neubau** — 13 AppKit-Dateien, voll aufs macOS-Fenstermodell |

⚠️ `Package.swift` deklariert aktuell **nur `platforms: [.macOS(.v14)]`** — die `.iOS`-Ergänzung müsste später, auf einem Branch, im heiligen Mothership passieren (nie main/v7.0.0).

---

## Die Navigation (Etappen in Reihenfolge, je mit Voraussetzung)

0. **v0 — Claude + Connectoren im Feld.** *Voraussetzung: keine.* Läuft heute (live gesehen 03.07.).
1. **Dauerhaftes Repo.** *Voraussetzung: Johannes' Nicken + GitHub-Tools.* Charter/Playbooks/Doku aus dem flüchtigen Scratchpad in eigenes Repo umziehen (getrennt von mykilOS-7). *Ausstehend — liegt bislang nur im Scratchpad.*
2. **Die vier Feld-Playbooks ausformulieren.** *Voraussetzung: Freigabe von Strang ①②③.* 01 Kunden-Briefing · 02 Zeit fangen · 03 Feld-Foto verräumen · 04 Idee fangen. *Skelett — Struktur steht, Inhalt fehlt.*
3. **Postbox-Schreibpfad festziehen.** *Voraussetzung: entschiedener Postbox-Kanal für ★3.* Deep-Link (lesen) + Postbox (schreiben) härten. *Offene Weiche.*
4. **Native iOS/iPadOS-App — DAS ZIEL (entschieden 2026-07-03).** *Voraussetzung: Verhalten in v0+Playbooks bewiesen, dazu Xcode + Apple-Signing.* „In sich rund, verknüpft und lebendig.“ Eine SwiftUI-App für iPhone (Momente-Fänger) + iPad (Baustellen-Cockpit). **Team-only: 5–8 Nutzer via TestFlight, nie App Store** — bezahlter Developer-Account (99 €/Jahr) erst zur Verteilung fällig. Rest der alten Etappe (Weiche A/B) ist damit entschieden: B = Weg, A = Ziel.

---

## Ehrliche Wahrheiten

- **v0 braucht KEINEN Apple-Account und läuft heute.** Der fehlende Developer-Account blockiert v0 gar nichts — erst ein späterer nativer App-Schritt stößt an die 7-Tage-/TestFlight-Grenzen.
- **Mothership zuerst.** Alle V10-UI-Blöcke (E/G/H) sind nur Build+Test-grün, **NICHT gegen Screenshots abgenommen** — dokumentierte P0-Lehre: Layout-Drift (Sidebar/Übersicht) ist mit grünen Tests nicht ausgeschlossen. **Block I ist das Gate, nicht Block J.**
- **Mobile ist leichte Parallele, nie Fokusräuber.** Kein zweites Mothership, kein Nachbau nativer Apps, kein Verkleinern des Desktop-Layouts — dirigieren statt rendern.
- **Die 10x-Keychain-Reibung (Per-User-Rollout + team-weiter Re-Consent) ist Mothership-Alpha, nicht Mobile-Problem** — und darf nie im Nacht-Automode ausgerollt werden.
- **Drei „Wahrheiten" im selben Repo:** ausgecheckter Branch steht auf 7.7.2, die gesamte V10-Arbeit inkl. `VERSION_10_PLAN.md` liegt nur auf `origin/feat/mykilos8-block-d-provisioning`, die repo-`CLAUDE.md` beschreibt noch 7.5. **Der Nordstern hängt an einem ungemergten Branch.** Jede Peilung ohne frisches `fetch` trifft veraltete Realität; lokale DMG-Builds bei Johannes können dem gepushten Stand voraus sein.
- **Tank B ist ephemer.** Ohne eigenes GitHub-Remote kann die ganze Missions-Basis bei Container-Recycling verloren gehen — „Rakete auf der Rampe, noch nicht im Orbit". `aim.sh` ist Konvention, kein erzwungener Hook.
- **★3 hat noch keinen Schreibpfad.** Drive ist hartes read-only-NO-GO, der Postbox-Kanal ist ungeklärt — Feld-Uploads dürfen bis dahin **nicht gebaut** werden. Deep-Links können kein vorbefülltes „4h CAD" an Clockodo übergeben; Schreiben hängt vollständig an der Postbox-Disziplin.
- **Datenquellen-Doppelung bleibt offen:** Airtable-CartStore vs. lokaler GRDB-WorkBasket laufen parallel (bewusst, aber Drift-Gefahr); Datenstrom-Handbuch-Zeile `WORKBASKET_INTAKE_PERSIST` fehlt noch — Handbuch und Code laufen bis dahin auseinander.
- **Offene Fragen, die nur Johannes beantworten kann:** Wann läuft der Schneider-Lauf (Block I) live durch und hält das Layout die Screenshot-Prüfung? Wann M3 (ClickUp-Listen-IDs) + M4 (sevdeskRef+Budget)? Wird `VERSION_10_PLAN.md` nach main gemergt, damit der Nordstern kanonisch auffindbar ist? Bekommt Tank B sein eigenes GitHub-Remote? iPad (Backlog-Rat) vs. iPhone (Johannes' Wille)?
