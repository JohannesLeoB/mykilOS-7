# mykilOS mobile — v0-Spezifikation

**Destilliert aus der Gründungsnacht 2026-07-03/04.** Das Referenzdokument, aus dem
gebaut wird. Alles hier ist entweder **live bewiesen** (markiert ✓), **bestätigt
entschieden** (★) oder **bewusst offen** (○).

---

## 1. Was mykilOS mobile ist

**Der Satellit des macOS-Motherships:** leicht, konzentriert, im Feld. Er fängt
Momente, die das Mothership strukturell nicht sehen kann, und verräumt sie
RAIL-rein. Kein zweites Mothership, kein Nachbau nativer Apps — ein **Dirigent**
mit dem Projekt-Graphen im Kopf. ★

**Zielbild:** native iOS/iPadOS-App (SwiftUI, ein Code, zwei Formate: iPhone =
Momente-Fänger, iPad = Baustellen-Cockpit). Team-only 5–8 Nutzer via TestFlight,
nie App Store. ★ — **v0 ist Claude + Connectoren** und läuft heute. ✓

## 2. Der Kern-Loop

**Fang → Versteh → Verräum.** ✓ (mehrfach live: Briefing, Küchen-Erstaufnahme,
Foto-Aufmaß, Ideen)

- **Fang:** Stimme, Foto, Tipp, Maßband-Wert, Ort.
- **Versteh:** Entity-Auflösung nach `07_VERSTEH_KERN.md` — Kaskade
  (Projektnummer → exakter Name → Kandidaten-Karte → Rückfrage), Homonym-Schutz,
  **nie raten**. ✓ (am #Schmid-Fund geschärft)
- **Verräum:** Deep-Link (lesen/springen) oder Postbox (schreiben, append-only,
  gated Karte→Bestätigung).

## 3. Datenquellen-Doktrin

| Quelle | Rolle | Beweis |
|---|---|---|
| **Registry** (Airtable-Graph / Git-Kopie) | **Graph** — wer gehört zu wem, IDs, Links | ✓ |
| **Drive** | **Puls** — was lebt gerade (`modifiedTime`), Dokumente, Kanon-Ordner | ✓ (Root-Peilung: 2 Projekte, die die Registry nicht kannte) |
| **Kalender/Mail** | Kontext — nur über Versteh-Kern gefiltert (Anker lügen) | ✓ |
| **Airtable gesamt** | „Milchstraße" — schema-tolerant lesen, Bedeutung > Layout ★ | |

Drive-Kanon (01 INFOS/02 CAD/03 PRÄSENTATION, 01–09) = **Heuristik**: junge
Projekte unprovisioniert, alte mit Alt-Schema-Resten. Zustand ehrlich anzeigen. ✓

## 4. Die vier Sterne (Feature-Kern)

### ★1 Zeit fangen — Code fertig, wartet auf Johannes' Andock-Schritt
Real gebaut und in `App/MyMini/` committed (2026-07-04):
- **Fang → Versteh** erkennt jetzt echte Dauer-Angaben im Freitext (Regex „Zahl+h/std"),
  erfindet nichts mehr (vorher: fest verdrahteter Demo-Platzhalter „4h/CAD für Heinz").
- **Fang → Verräum**: `PostboxStore` schreibt lokal, throws-basiert, neustart-fest
  (`Documents/postbox.json`), live auf Johannes' iPhone bestätigt.
- **Verräum → Adapter-Base**: `AirtableClockodoPostbox` (reine Feld-Abbildung, gespiegelt
  vom Mothership-Original `ClockodoAdapterWriter.swift`@`9742b59`, nur gelesen) +
  `AirtableClockodoPostboxClient` (echter POST) + `KeychainAirtablePostboxCredentialsStore`
  (eigener, gerätelokaler Schlüsselbund-Eintrag) + `PostboxView`/`AirtablePostboxSettingsView`
  (sichtbare Liste, manueller Sync-Knopf pro Zeit-Eintrag, nie automatisch).
- **Ehrlichkeitsgrenze bewusst gezogen:** kein Projekt/keine Kostenstelle/kein Start-Ende
  wird erfunden — nur Datum/KW/DauerH/Status=„Vorgebucht"/Quelle=„Satellit" werden gesendet,
  der Rest bleibt leer für die menschliche Prüfung vor der echten Clockodo-Buchung.
- **Nur Zeit-Einträge synchronisieren.** Ideen bleiben lokal (Ziel-Heimat offen, Punkt 2 unten).

**Zwei echte Andock-Punkte, die nur Johannes entscheiden/tun kann** (Code steht, feuert nicht von selbst):
- Ein echter Airtable-PAT in den Settings (`AirtablePostboxSettingsView`) — Token
  landet ausschließlich im iPhone-Schlüsselbund.
- „Satellit" ist ein neuer Quelle-Wert (bisher nur „Timer" vom Mac-Widget). Der
  Client legt ihn per `typecast` automatisch an — braucht aber Johannes' Okay,
  bevor der erste echte Sync läuft, oder er trägt den Wert vorher selbst in
  Airtable ein.

Echter Clockodo-POST bleibt **dauerhaft ausgeschlossen** (Mothership-Code-Kommentar,
wörtlich). Finale Buchung = Handarbeit in Clockodo. ★

### ★2 Glance-Cockpit — bewiesen
Puls (Zählkarten) + **„Gerade heiß"** (Drive-`modifiedTime`-Ranking, ein API-Griff
für den ganzen Root ✓) + Projektliste mit Suche + Deep-Links. Prototyp publiziert. ✓
Vierte Puls-Kachel „Postbox" (04.07.) — zeigt die Zahl offener Einträge, immer
antippbar. Behebt eine echte Lücke: vorher war die Postbox nur erreichbar,
solange die Fang-Karte einen Link dazu zeigte (nur bei nicht-leerer Postbox).

### ★3 Feld-Sensor — Baufreigabe erteilt (04.07.), komplett gebaut, ungetestet
Kamera-Fänge → Projektordner/Pipeline. Johannes hat die volle Baufreigabe
gegeben. Gebaut: echte Kamera-Aufnahme, Karte→Bestätigung (Projekt nie
geraten, Kanon-Ziel-Picker, EXIF-Zeit, Best-Effort-Standort), neustart-feste
lokale Ablage, Übersicht mit Swipe-Löschen, echter Google-Sign-In
(`GoogleOAuthPKCEService`, ASWebAuthenticationSession+PKCE, iOS-eigener
Custom-Scheme statt Mothership-Loopback), echter Drive-Upload-Client
(`GoogleDriveUploadClient`, sucht/erstellt Kanon-Unterordner, multipart-Upload).
**Noch offen:** Johannes' iOS-OAuth-Client-ID (Google Cloud Console) + die
resultierende URL-Scheme im Xcode-Projekt eintragen. **Danach ist der erste
echte Sync-Versuch zugleich der erste echte Test**, ob `drive.file`-Scope
wirklich in vorhandene Projektordner schreiben darf — im Mothership-Code
selbst nie live bestätigt (Details: `playbooks/03_feld-foto-verraeumen.md`).
Ein 403 dort wäre ein Befund, kein Bug. ○→◐

### ★4 Claude im Gespräch — jetzt echt im Cockpit (2026-07-04)
Das Bindegewebe; auf mobile ist das Gespräch die Oberfläche. `AssistantChatView`
(App/MyMini) ruft die echte Anthropic Messages API direkt vom Gerät auf
(`claude-sonnet-5`, Keychain-Key, kein Server dazwischen) — Systemprompt trägt
den echten, aktuellen Projekt-Registry-Snapshot (Nummer als Wahrheit, Lehre aus
„Freitext-Anker lügen"). Reiner Lese-Blick: schreibt nirgends, kein eigener
Fang-Kanal. Einstieg über Sprechblasen-Icon im Glance-Cockpit-Toolbar. Wartet
auf Johannes' eigenen Anthropic-API-Key in den Einstellungen — Code steht,
feuert nicht ungefragt. **Verlauf jetzt neustart-fest** (`ChatHistoryStore`,
gleiches Muster wie `PostboxStore`, `Documents/chatverlauf.json`) statt nur im
Speicher — plus Papierkorb-Knopf mit Bestätigungsdialog zum Löschen. ★

### Fähigkeiten-Panel (§14-Pflicht erfüllt, 04.07.)
`VerbindungenView` (Antennen-Icon im Glance-Cockpit-Toolbar) zeigt beide
Verbindungen (Airtable Postbox, Claude Assistent) an einer Stelle statt
verstreut — Status + Ein-Tipp-Zugriff zum Trennen. Ersetzt nicht die
bestehenden Schnellzugriffe in `PostboxView`/`AssistantChatView`, ergänzt sie.

## 5. Feld-Werkzeuge (aus den Live-Tests der Nacht)

- **Foto-Erstaufnahme:** Bestandsfoto → strukturierte Aufnahme (Stil, Bestand,
  Anker, Wasser-/Stromposition **ungefragt aus dem Bild gelesen** ✓).
- **Foto-Aufmaß → Kostenschätzung:** Maßband-App-Werte + Fotos → komponierte
  Freitext-Beschreibung → **V10-`schaetze`** (läuft live im Mothership) →
  Min/Mitte/Max. Kette existiert Ende-zu-Ende. ✓ (Johannes' 1,2 m/1,23 m-Test)
- **Drei-Toleranzen-Doktrin ★:** iPhone ±cm = Schätzung · RoomPlan ±2 cm =
  CAD-Rohbau · **Laser (DISTO) mm = Werk.** Nie mischen. iPhone-Maße erreichen
  NIE die Fertigung.
- **Abnahme-Diktat:** Freisprech-Mängelaufnahme → nummeriertes Protokoll (○ Ziel-
  Ablage hängt an ★3).
- **Gewerke-Briefe:** eine Aufmaß-Quelle → gefilterte Briefe je Handwerker,
  Termin-Abgleich via Kalender (○ Versand gated, nicht v0).

## 6. Sensor-Roadmap (phasiert)

| Phase | Fähigkeiten | Voraussetzung |
|---|---|---|
| **v0 — jetzt** ✓ | Foto-Verstehen, Foto-Aufmaß-Komposition, Briefing, Ideen/Zeit fangen (Postbox), OCR Typenschilder | keine |
| **v0.5 — Kurzbefehle** | Action-Button „Baustellen-Moment" (Foto+Sprachnotiz+Projekt → Chat), Geofence-Trigger via Kurzbefehle-Automation | 30 Min Einrichtung, kein Code |
| **v1 — native App** | **RoomPlan/LiDAR-Aufmaß** (Raum→3D→CAD-Zubringer), **AR-Anker** (Wasser/Strom/Abfluss räumlich), Fahrstuhl-vs-Inselplatten-Check, **DISTO-Bluetooth-Brücke** (mm vom Laser), Geofence nativ, gesprochener **Morgen-Brief** (AirPods/CarPlay) | Xcode; Verteilung: Developer-Account (99 €/J) erst bei TestFlight ★ |

Die Sensor-Fälle sind das stärkste Argument für die native App: **die App ist der
Schlüssel zum Sensorium** — Claude in der Tasche hat keine Hände an LiDAR & Co.

## 7. Sicherheit & Verfassung (unverhandelbar)

- **Zwei-Basen-Doktrin:** Tank A (`mykilOS-7`) für immer read-only; Tank B einzige
  Schreibbasis. Trennung nach **Repo**, nicht Branch. ★✓ (Wächter `aim.sh` getestet)
- **Grenze = Tank, nicht Konto/Gerät/Session** (2-Max-Account-Parallelbetrieb). ★
- **Geerbte RAILs:** externe Writes nur gated Karte→Bestätigung→Audit · Clockodo/
  Sevdesk nie direkt (Postbox) · Airtable nie DELETE · Drive read-only · ClickUp nur
  Testspace · per-User isoliert · Aufgaben nur Mensch→Mensch · alte geteilte Base
  (`appkPzoEiI5eSMkNK`) nie anfassen, nicht mal lesen.
- **Reality-Check-Ritual** vor jedem Thematisieren (fetch → Version → „gepusht
  oder lokal?" → erst dann reden). ✓ (fing heute drei Stände Drift + alpha5-lokal)
- **Privatsphäre-Linie:** Kalender-/Mail-**Inhalte** nie in Artifacts backen
  (Projekt­namen ja, Privates nein). Briefe mit Kalenderinhalt nur im privaten Chat.

## 8. Team-Modell (geerbt vom Mothership)

Persönliches Cockpit, geteilte Instrumente: per-User-Keychain, private Postboxen,
nichts kreuzlesbar. Für 5–8 Nutzer bereits gedacht und gebaut — der Satellit
übernimmt es unverändert.

## 9. Offene Weichen (ehrlich)

1. **★3-Schreibpfad** (Feld-Uploads) — braucht Johannes' Postbox-Entscheidung. ○
2. **Ideen-Topf-Zielheimat** (Airtable-Tabelle?) — v0 läuft über Tank B.
   Verfeinerte Lesart (externe Bestätigung, Freund, 2026-07-04): vermutlich
   **mehrere** Kategorietabellen statt einer (Ideen, Feature-Kandidaten,
   Sensor-/Device-Cases, Wächter-Fälle, Planungs-Assistenten, Feld-Capture,
   Logistik, Kalkulation, Portfolio/Beweisführung) — Frage bleibt trotzdem
   offen, nichts entschieden. **Zwischenlösung gebaut (04.07.):** Idee-Einträge
   in `PostboxView` haben jetzt einen `ShareLink` — exportierbar übers
   iOS-Share-Sheet (Notizen, Nachricht, egal wohin), statt bis zur
   Airtable-Entscheidung nutzlos zu warten. ○
3. **Dauerhaftes Tank-B-Repo** — GitHub-Anlage braucht Johannes (Integration
   durfte nicht). ○
4. **Airtable-Staub-Kartierung** — Flugroute fertig (`06_…FLUGROUTE.md`), wartet
   auf frische Session (Freigabe-Kanal hier defekt). ○
5. **Adress-Lücke** („Hinfahren"-Links) — vermutlich via Airtable-Kunden. ○

## 10. Bewiesene Momente dieser Nacht (das Fundament)

Briefing Schmidt in Sekunden ✓ · Freitext-Anker lügen (#Schmid=#Schneider) ✓ ·
Registry-Drift (Drive kannte 5 Projekte mehr) ✓ · Kanon=Heuristik ✓ ·
`modifiedTime`=Puls ✓ · Foto-Erstaufnahme mit Wasser/Strom ✓ · Foto-Aufmaß→
Engine-Kette ✓ · Herzschlag-Prototyp in der Hand ✓ · Dreitakt von Johannes
selbst vorgeführt ✓.
