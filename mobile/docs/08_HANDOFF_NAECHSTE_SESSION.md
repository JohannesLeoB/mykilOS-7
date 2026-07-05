# HANDOFF — für die nächste mykilOS-mobile-Session

**Stand: Ende der Gründungssession, 2026-07-03 spät. Mothership-Peilung: `dababdb`.**

## Zustand in einem Absatz
Mission steht: Zielbild entschieden (native iOS/iPadOS-App, Team 5–8, TestFlight,
nie App Store), Zwei-Tank-Doktrin + Wächter getestet, ★1 bestätigt & baufertig
(Adapter-Base `appuQDCFGLmjo2L6T` → Zeitbuchungen), Live-Beweise ①+② erbracht
(Briefing funktioniert; Freitext-Anker lügen; Drive-Kanon ist Heuristik;
`modifiedTime` = Aktivitäts-Gold), Herzschlag-Prototyp publiziert (31 echte
Projekte, echte Drive-Sprünge), Versteh-Kern spezifiziert, Briefkasten-Protokoll
mit Triage aktiv. Tank B: nur im Scratchpad + als Zip bei Johannes.

## Sofort-Aufgaben der nächsten Session (Reihenfolge)
1. **Tank B wiederherstellen:** Johannes wirft die Basis-Zip in den Chat →
   `git clone mykilos-mobile-repo.bundle` (volle Historie). README + diese Datei lesen.
2. **Reality-Check-Ritual** (docs/02 §IV): fetch auf Tank A, Version peilen,
   „gepusht oder lokal?" fragen.
3. **Staub-Kartierung fliegen** (docs/06): erster Airtable-Aufruf löst den
   Freigabe-Dialog aus → Johannes klickt „immer erlauben" → Route abfliegen.
   Wichtigste Frage: **Kundenadressen** (→ „Hinfahren"-Links).
4. **Dauerhaftes Repo** (Etappe 1): mit Johannes zusammen anlegen (2 Minuten,
   Klick-für-Klick-Führung; GitHub-Integration hier durfte keine Repos erstellen).

## Startprompt (für Johannes zum Einwerfen, mit Zip im Anhang)
> Neue mykilOS-mobile-Session. Anbei die Basis-Zip. Stelle Tank B aus dem
> Bundle wieder her, lies README + docs/08_HANDOFF, mach den Reality-Check —
> und dann flieg die Staub-Kartierung. Eiserne Regeln gelten: mykilOS-7 nur
> lesen, Schreiben nur in Tank B, keine externen Writes.

## Harte Limits (unverändert)
Schiff read-only · externe Welt read-only bzw. Postbox-gated · ★3 gesperrt bis
Schreibpfad entschieden · alte geteilte Base nie anfassen · Grenze = Tank, nicht Konto.

## Meilenstein erreicht — 04.07. 02:21

Erstes echtes Xcode-Projekt existiert: `myMini` (SwiftUI + SwiftData), lokal
auf Johannes' Mac unter `~/Claude/Projects/myMini/mykilos-mobile/`.
**Build Succeeded** — Standard-Apple-Template (ContentView/Item/myMiniApp),
noch kein eigener Code. Nächster Schritt: erster echter Screen (Glance-Cockpit
als SwiftUI, Übersetzung des HTML-Prototyps von Nacht 1). Historie (60 Commits)
liegt separat im Bundle — Verheiratung mit dem Xcode-Ordner steht noch aus,
nicht dringend.

## Meilenstein erreicht — 04.07. ~12:15 — alle vier Gründungs-Sterne stehen

Seit 02:21 komplett neu gebaut, committed, und **live auf Johannes' echtem
iPhone 17 Pro bestätigt** (nicht nur Simulator — der komplette Install-Loop
von CoreDeviceError 3002 über Entwicklungsteam-Vertrauen bis zur kaputten
Bridging-Header ist durchlaufen und gelöst):

- **★2 Glance-Cockpit** — `GlanceCockpitView` + `ProjectStore` (liest
  `projekte.json`, 31 echte Projekte) + `HotProjectCard`/`ProjectRow`/`MykColor`.
  Read-only, wie vorgesehen.
- **★1 Zeit fangen** — `FangCard` schreibt echt in `PostboxStore`
  (`Documents/postbox.json`, throws-basiert, neustart-fest). `FangKind.versteh()`
  erkennt echte Dauer-Angaben aus Freitext (Ehrlichkeitsfix, kein Platzhalter
  mehr). Sync-Client `AirtableClockodoPostbox`/`AirtableClockodoPostboxClient`
  gebaut (Feld-Form gespiegelt vom echten Mothership-Original
  `ClockodoAdapterWriter.swift`@`9742b59`, nur gelesen) — feuert nur manuell
  über `PostboxView`, wartet auf Johannes' eigenen Airtable-Token
  (`AirtablePostboxSettingsView`, Keychain) + sein Okay zum neuen
  Quelle-Wert „Satellit" (typecast).
- **★3 Feld-Sensor** — weiterhin bewusst **gesperrt**, keine Änderung.
- **★4 Claude im Gespräch** — `AssistantChatView` ruft die echte Anthropic
  Messages API direkt vom Gerät auf (`claude-sonnet-5`, Keychain-Key via
  `ClaudeSettingsView`), Systemprompt trägt den echten Projekt-Snapshot.
  Reiner Lese-Blick, kein Fang-Kanal. Einstieg: Sprechblasen-Icon im
  Glance-Cockpit-Toolbar.

**Zwei neue Referenz-Docs** (`17_FAMILIEN_INDEX.md`, `18_NICHT_VERWECHSLUNGEN.md`)
nach voller Reconciliation gegen eine unabhängige externe Synthese eines
Freundes von Johannes — inhaltlich nichts Neues gefunden, aber zwei fehlende
Organisationsformen ergänzt.

**Neue Standing Rule** (`03_BRIEFKASTEN_PROTOKOLL.md`): jeder fertige Baustein
wird ab jetzt als Zip + einfache `EINFUEGEN.md`-Anleitung ausgeliefert,
Terminal-Befehle nur wo unvermeidbar und dann als knappe Einzelzeilen-Liste
(Johannes ist bewusster Laie, Auslöser war ein Terminal-Befehl, der versehentlich
in eine Bridging-Header-Datei geriet).

**Kleine Politur** (04.07. ~12:20): Whitespace-Trimming bei allen Text-/Token-
Eingaben (Fang-Karte, Assistent-Eingabe, Projekt-Suche, Airtable-/Claude-Token),
Return-Taste sendet jetzt in Fang-Karte und Assistent (vorher nur der Knopf).

**Offene Andock-Punkte für Johannes** (Code steht, wartet bewusst):
1. Eigener Airtable-PAT in `AirtablePostboxSettingsView`.
2. Okay zum neuen Quelle-Wert „Satellit" (oder selbst in Airtable eintragen).
3. Eigener Anthropic-API-Key in `ClaudeSettingsView`.
4. ★3-Postbox-Entscheidung (Feld-Foto-Schreibpfad) weiterhin offen.
5. Dauerhaftes GitHub-Repo für Tank B weiterhin nicht bestätigt gepusht.

## Meilenstein erreicht — 04.07. ~13:00 — ★3 komplett gebaut (Baufreigabe erteilt), zwei echte Bugs in Selbst-Review gefunden

Johannes hat mitten am Tag (unterwegs, "mach so weit du kannst") die volle
Baufreigabe für ★3 gegeben. Komplett neu gebaut, alle Teile:

- **Lokal:** `KameraAufnahmeView` (echte Live-Kamera, kein Fotoalbum),
  `FeldFotoBestaetigungView` (Karte→Bestätigung: Projekt nie geraten, immer
  per Suche bestätigt; Kanon-Ziel-Picker Bestand/Rohbau/Mangel; EXIF-Zeit;
  Standort), `FeldFotoStore` (neustart-fest, JPEG-Datei + JSON-Manifest,
  Swipe-Löschen nur unsynchronisiert), `FeldFotoListView` (Übersicht).
  Kamera-Knopf in der Fang-Karte, fünfte Puls-Kachel „Fotos" (Puls-Leiste
  jetzt horizontal scrollbar wegen 5 Kacheln). `FangKind.fotoGesperrt` →
  `fotoHinweis` (freundlicher Verweis auf den echten Knopf statt „gesperrt").
- **Google-Sign-In:** `GoogleOAuthPKCEService` (ASWebAuthenticationSession +
  PKCE, iOS-eigener Custom-Scheme-Redirect statt Mothership-Loopback),
  `GoogleCredentialsStore` (Client-ID + Tokens im Schlüsselbund, nichts
  hardcodiert), `GoogleAccessTokenProvider` (Auto-Refresh),
  `GoogleSignInSettingsView`. Dritte Zeile in `VerbindungenView`.
- **Drive-Upload:** `GoogleDriveUploadClient` — sucht/erstellt den
  Kanon-Unterordner im Projekt-Drive-Ordner (ID kommt aus der Registry,
  `Project.driveFolderID` — keine zusätzliche Ordner-Discovery nötig), lädt
  dann per multipart hoch. Scope gebündelt wie im Mothership-Original:
  `drive.file` (Schreiben) + `drive.metadata.readonly` (Suchen).

**⚠️ Ungetestet, ein echtes technisches Risiko bleibt offen:** ob
`drive.file`-Scope wirklich reicht, um in einen VORHANDENEN Projektordner zu
schreiben, ist selbst im Mothership-Code nie live bestätigt worden (Recherche-
Befund, siehe `playbooks/03_feld-foto-verraeumen.md`). Der erste echte
Sync-Versuch in der App ist der erste echte Test dieser Annahme. Ein 403 dort
ist ein Befund, kein Bug — dann bräuchten wir Google Picker API oder eine
andere Freigabe-Form.

**Zwei echte Bugs in der Selbst-Review gefunden UND gefixt**, während
Johannes unterwegs war (bevor er sie beim echten Test gefunden hätte):
1. `ASWebAuthenticationSession` wurde nur lokal gehalten und sofort wieder
   freigegeben — der Google-Anmelde-Dialog wäre nie erschienen. Jetzt als
   Property gehalten.
2. Standort-Erfassung nutzte nur passives `CLLocationManager.location`
   (liefert ohne aktive Anfrage oft `nil`). Neuer `EinmaligerOrtsSensor` mit
   echtem `requestLocation()`-Delegate-Callback.
Nebenbei: form-urlencoded-Bodies härter gegen Sonderzeichen im Code/Token.

**Neuer, dritter offener Andock-Punkt für Johannes:**
6. iOS-OAuth-Client in der Google Cloud Console anlegen (Bundle ID
   `com.johannes.myMini`) + resultierendes URL-Scheme in Xcode eintragen
   (Anleitung liegt im zugehörigen Auslieferungs-Zip). **Das ist der
   Nachmittags-Termin mit Johannes** — sobald die Client-ID da ist, folgt
   sofort der erste Live-Test des Drive-Uploads.

---

## Meilenstein-Update (04.07. nachmittags): 9 Batches, Komplett-Paket, frisches Xcode-Projekt, Mission-Control-Relais

**Code-Stand: 96 Swift-Dateien + projekte.json (~8.000 Zeilen), alle in
`App/MyMini/`.** Ein unabhängiger Frischblick-Review (90 Dateien, jede
View-Verdrahtung gegen jeden Init geprüft) fand null Fehler und keinen toten
Code; sein einziger echter Fund (Kontakte-Berechtigung nur im Lieferzettel
dokumentiert) führte zu `docs/20_BERECHTIGUNGEN.md` — **die eine verbindliche
Liste aller 7 Info.plist-Einträge.** Neue Regel: jede neue Berechtigung landet
dort im selben Commit.

**Was seit dem ★3-Eintrag oben dazukam (Details: `docs/19_BACKLOG_BAUSTAND.md`):**
- Batch 1–3: Sprich-Aufnahme, Visitenkarten-Kamera→Kontakte, Beleuchtungs-Check,
  Barcode/QR-Scanner, Wasserwaage, Lieferschein-Verbucher, Förder-Beweispaket,
  Farbtemperatur-Check, Morgen-Brief gesprochen, Abnahmeprotokoll per Diktat,
  Raumakustik-Check — plus `WerkzeugeView` als Sammelort.
- Batch 4: Standort-Wächter (#9/#62) als Off-by-default-Toggle — Johannes'
  Doktrin-Antwort wörtlich: „Nein, alles was Datenschutz angeht immer bewusst
  zu Toggles."
- Batch 5: echtes AR — AR-Maßband, AR-Anker für Gewerke, RoomPlan-Aufmaß.
- Batch 6: Bluetooth-Laser-Fundament + Adapter-Registry für **11 Hersteller**
  (Leica/Bosch/Stanley/Hilti/DeWalt/Milwaukee/Makita/Einhell/Worx/Ryobi/Stier),
  alle `istProtokollVerifiziert=false` — Namens-Erkennung ja, Messwerte NEIN,
  bis echte Hardware da ist. Johannes hat sich noch auf kein Gerät festgelegt.
- Batch 7–9: 2D-Grundriss-Export (PDF+DXF) aus RoomPlan, Planmodelle-in-AR
  (USDZ-Import, VectorWorks-Pipeline Stufe 1), PDF-Berichte (Abnahmeprotokoll,
  Förder-Beweispaket), App-Icon (Orange, MY, Orbit-Punkt — `App/Icon/`).

**Aufmaß-Ehrlichkeit (wichtig für jede Folge-Session):** ±5mm auf 5m ist mit
Handy-AR/RoomPlan NICHT erreichbar (Sensor-Grenze, nicht Software) — nur ein
Bluetooth-Laser liefert das. Johannes' Vision dafür steht: RoomPlan-Grobscan →
geführter Laser-Kalibrier-Modus („bin ich mir bei der Steckdosen-Position
sicher?" bestätigen) → 2D-Zeichnung. Scan→2D ist gebaut; der
Kalibrier-Modus **wartet auf die Laser-Geräteentscheidung** — bewusst nicht
als leere UI vorgebaut.

**Werkzeug-Situation auf Johannes' Seite (Stand ~16:30):**
- Xcode-Projekt wurde nach Lösch-Unfall **frisch aufgesetzt** — Signing ✓,
  Bundle-ID `com.johannes.myMini` ✓. Erster Einfüge-Versuch scheiterte an
  fehlendem „Copy items if needed" (alle Dateien rot = tote Referenzen).
- Deshalb: **mykilOS-mobile-KOMPLETT.zip** (alle 96+1 Dateien + EINFUEGEN mit
  Berechtigungs-Tabelle) als das eine Paket statt vieler Einzel-Zips.
- **Mission-Control-Relais etabliert** (siehe `docs/03_BRIEFKASTEN_PROTOKOLL.md`):
  der Satellit formuliert fertige Copy-Paste-Aufträge für die Mothership-
  Session auf dem Mac, die die Dateisystem-Arbeit macht. Johannes ist nur noch
  Relais. Erster Einsatz lief.
- iPhone-Kopplung an den Mac stand noch aus („dazu gleich mehr") — Trust-Dialog
  fürs Entwickler-Zertifikat war erklärt (VPN & Geräteverwaltung → Vertrauen),
  Entwicklermodus auf dem iPhone ist AN. 7-Tage-Signatur-Ablauf (freie
  Apple-ID) ist ihm erklärt.

**Offen (unverändert bzw. neu):**
1. Johannes: Google-iOS-Client-ID (Nachmittags-Termin) → erster ★3-Live-Test.
2. Johannes: Laser-Geräteentscheidung → dann Mess-Protokoll + Kalibrier-Modus.
3. Erste Live-Tests aller AR-/RoomPlan-/Standort-/Laser-Bausteine (nichts davon
   war von hier testbar — erwartet: Nachjustieren, kein Neubau).
4. Stufe 2 Planmodelle (automatische Raum-Ausrichtung) bleibt bewusst offen.
