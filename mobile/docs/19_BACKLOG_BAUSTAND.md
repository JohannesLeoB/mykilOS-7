# Backlog-Baustand — "Bau alles, was du nicht von mir brauchst"

**Auftrag (Johannes, 04.07. ~13:15):** volle Architekten-Freigabe für alles aus
`journal/IDEEN_CHRONOLOGISCH.md`, das KEINE externe Entscheidung/Konto/Hardware
von Johannes braucht. Dieses Dokument ist die laufende Bilanz — was gebaut ist,
was bewusst noch aussteht und warum. Ideen-Nummern verweisen auf
`journal/IDEEN_CHRONOLOGISCH.md`.

## Kriterium: was zählt als "brauche ich nicht von dir"?

- ✅ **Baubar ohne Johannes:** on-device Frameworks (Kamera, Mikrofon/Speech,
  Vision/OCR, CoreLocation, CoreMotion, Contacts) — reine Geräte-Berechtigungen,
  kein externes Konto, keine Konsole, keine Hardware-Kopplung.
- ❌ **Braucht Johannes weiterhin:** externe OAuth-Konten (Google Calendar/
  Contacts/Gmail — eigener Client wie bei ★3), Bluetooth-Hardware (Laser,
  ColorReader, FLIR — er muss sie besitzen/koppeln), Airtable-Business-
  Entscheidungen (Ideen-Topf-Zielheimat), alles, was ★3 selbst noch offen hat
  (seine iOS-Client-ID).

## Gebaut (04.07., diese Sitzung)

| Idee(n) | Was | Datei(en) |
|---|---|---|
| — (★1/★2/★3/★4-Fundament) | siehe `08_HANDOFF_NAECHSTE_SESSION.md` | — |
| Kern-Versprechen "Sprich oder tippe" | Sprich-Aufnahme, on-device Speech (Deutsch), Transkript → bestehende Versteh-Pipeline | `SpracheZuTextService`, `SprachaufnahmeView` |
| #28 Visitenkarten-Kamera → Kontakte | On-device Vision-OCR, Karte→Bestätigung (editierbar, nie automatisch), Schreiben in iOS-Kontakte (Contacts-Framework, reine Geräte-Berechtigung) | `VisitenkartenOCR`, `KontaktSchreiber`, `VisitenkarteBestaetigungView` |
| #43 Beleuchtungs-Check (statt #58/#42) | Foto → CoreImage-Helligkeitsanalyse (`CIAreaAverage`) → hell/mittel/dunkel + Empfehlung — genau die in #43 selbst schon vorgezeichnete EV-Kategorie ("kein Lux-API bei iOS"). **Bewusst OHNE #42 Sonnenverlauf/Azimut und OHNE #58 Planungs-Assistent-Empfehlungslogik** — Sonnenstand-Astronomie von Hand ist fehleranfällig und ohne geprüfte Bibliothek nicht verlässlich verifizierbar; das bleibt zurückgestellt, nicht weil Johannes gebraucht wird, sondern weil es mehr Sorgfalt braucht als eine Nacht-Session leisten kann. Neuer Sammelort `WerkzeugeView` (Toolbar-Icon, wächst mit weiteren eigenständigen Vor-Ort-Werkzeugen) | `HelligkeitsAnalyse`, `BeleuchtungsCheckView`, `WerkzeugeView` |
| #32 Barcode/QR-Scanner | Live-Scan (VisionKit `DataScannerViewController`, on-device) → sofort ins lokale, neustart-feste Scan-Log. **Bewusst OHNE WorkBasket-Abgleich** (kein WorkBasket-Sync auf mobile existiert) — ein ehrlicher Rohdaten-Log (Wert, Symbologie, Zeitpunkt), kein vorgetäuschter Treffer/Fehltreffer gegen Schiffsdaten. `isSupported`/`isAvailable`-Check mit ehrlichem Fallback-Zustand für nicht unterstützte Geräte/iOS-Stände | `BarcodeTreffer`, `BarcodeLogStore`, `BarcodeScannerBridge`, `BarcodeScannerScreen`, `BarcodeLogListView` |
| #51 Wasserwaage (herausgelöst) | Gyroskop-Wasserwaage für geraden Horizont — CoreMotion-Neigungsmesser (Pitch/Roll), Punkt + Gradzahl, grüne Rückmeldung bei ±0,5°. **Bewusst OHNE den ARWorldMap-Rückkehr-Teil von #51** (Vorher-Standort-Wiederfinden ist ein eigener, größerer AR-Baustein, hier bewusst nicht mitgebaut) — braucht keine Info.plist-Berechtigung | `WasserwaageSensor`, `WasserwaageView` |

### Batch 2 (04.07., Fortsetzung desselben Auftrags)

| Idee(n) | Was | Datei(en) |
|---|---|---|
| #33 Lieferschein-Verbucher | On-device Vision-OCR auf Paketlabel → Tracking-Nummer/Absender-Vorschlag (editierbar) → Projekt explizit gewählt → Wareneingangs-Log. **Bewusst OHNE WorkBasket-Abgleich** — gleiche "Rohdaten-Log"-Haltung wie beim Barcode-Scanner, kein Sync-Kanal, daher auch kein Fake-Sync-Knopf. Dritter Kamera-Modus in der Fang-Karte, neue Puls-Kachel „Pakete" | `LieferscheinOCR`, `WareneingangsEreignis`, `WareneingangsLogStore`, `LieferscheinBestaetigungView`, `WareneingangsLogListView` |
| #52 Förderungs-Beweispaket (Teilmenge) | **Nur der erreichbare Teil:** Feld-Fotos per Toggle oder nachträglichem Kontextmenü als „förderrelevant" markieren, datiertes Bündel je Projekt über das System-Share-Sheet teilen. **KEIN ARWorldMap-Rückkehr-Teil** (bleibt wie unten weiter zurückgestellt) und **kein generierter PDF-Bericht** (das wäre ein sinnvoller, aber eigener nächster Schritt) — das hier ist ehrlich „Fotos teilen". Technischer Stolperstein bewusst gelöst: `FeldFoto` bekam ein handgeschriebenes `init(from decoder:)`, damit das neue Feld bestehende `feldfotos.json`-Dateien nicht zum Absturz bringt | `FeldFoto` (+Feld), `FeldFotoStore` (+`setzeFoerderrelevant`), `FeldFotoBestaetigungView`, `FeldFotoListView`, `FoerderBeweispaketView` |
| #41 Farbtemperatur-Check | Foto → grobe Kategorie warm/neutral/kühl aus dem R/B-Kanal-Verhältnis (`CIAreaAverage`, gleiche Technik wie Beleuchtungs-Check). **Ausdrücklich KEINE kalibrierte Kelvin-Messung** — iOS hat keinen Farbtemperatur-Sensor, ein `UIImagePickerController`-Foto liefert keinen Zugriff auf Weißabgleich-Gains einer Live-Kamera-Session; das wäre ein eigener, größerer Umbau der Kamera-Architektur, kein kleiner Zusatz | `FarbtemperaturAnalyse`, `FarbtemperaturCheckView` |
| #10 Morgen-Brief gesprochen | Lautsprecher-Knopf im Herzschlag-Header liest Begrüßung + Projektanzahl + offene Postbox-/Feld-Foto-Zahlen laut vor (`AVSpeechSynthesizer`, Deutsch). Reine Sprachausgabe, kein Mikrofon — keine neue Info.plist-Berechtigung nötig | `MorgenBriefSprecher`, `MorgenBriefText` |
| #11 Abnahmeprotokoll per Diktat | Nummeriertes Mängelprotokoll je Projekt — Diktat (dieselbe `SprachaufnahmeView` wie die Fang-Karte, kein Doppelbau) + optionales Foto pro Eintrag, Text bleibt danach editierbar. Anzeige-Nummer aus der Listenposition, nicht persistiert (keine Nummerierungs-Bugs nach Löschen). Größter Baustein dieser Batch, eigene Zip-Lieferung | `MangelEintrag`, `AbnahmeprotokollStore`, `AbnahmeprotokollView` |

### Batch 3 (04.07., Fortsetzung)

| Idee(n) | Was | Datei(en) |
|---|---|---|
| #49 Raumakustik-Check (verkleinert) | 3 Sekunden Mikrofon-Pegel (`AVAudioRecorder`, Metering) → grobe Kategorie ruhig/normal/laut. **Bewusst KEINE Nachhallzeit-Messung** — die bräuchte einen kontrollierten Sweep-Ton plus kalibriertes Mikrofon, um nicht stillschweigend falsche Werte zu liefern; gleiche Descoping-Haltung wie Beleuchtungs- und Farbtemperatur-Check. Kein Text wird verarbeitet oder gespeichert, nur der Pegel | `RaumakustikMesser`, `RaumakustikCheckView` |

### Batch 4 (04.07., nach expliziter Rückfrage)

Johannes' Antwort auf die Geofencing-Rückfrage: **"Nein, alles was Datenschutz
angeht immer bewusst zu Toggles."** Nachgefragt (AskUserQuestion), da
zweideutig — Antwort: **bauen, aber als Off-by-default-Toggle**.

| Idee(n) | Was | Datei(en) |
|---|---|---|
| #9/#62 Standort-Wächter | Geofence-Projektvorschlag + passiver Zeit-Fang, **Off-by-default-Toggle** im Fähigkeiten-Panel (`VerbindungenView`) — startet AUS, iOS fragt "Immer"-Standort erst beim Einschalten, ein Antippen widerruft sofort inkl. aller überwachten Orte (§14-Doktrin: Opt-in/sichtbar/widerrufbar/auditierbar, alle vier Mechanismen erfüllt). **Kein Adress-Datensatz existiert in der Registry** — deshalb self-teaching statt Fremddaten: Projekt aufklappen → "Diesen Ort merken" (einmaliger GPS-Schnappschuss, `EinmaligerOrtsSensor`, Projekt ist beim Merken schon explizit gewählt). `CLLocationManager`-Region-Monitoring (max. 20 Regionen, iOS-Limit) erkennt danach Betreten/Verlassen — auch im Hintergrund. Abgeschlossener Aufenthalt → Karte→Bestätigung im Herzschlag-Bildschirm ("Als Zeit in die Postbox"), **nie automatisch**. **Bewusst OHNE Kalender-Kreuzcheck** (der Teil von #62 bräuchte Google-Calendar-OAuth wie #61, bleibt draußen). **Nicht live testbar von hier** — echtes Hintergrund-Wecken über Stunden/App-Neustart durch iOS ist ein manueller Beta-Check wie beim ★3 Drive-Upload. **Braucht eine neue Info.plist-Berechtigung** (`NSLocationAlwaysAndWhenInUseUsageDescription`) — einzige Ausnahme dieser Session, sonst kam jede Batch ohne neue Berechtigung aus | `ProjektStandort`, `ProjektStandortStore`, `StandortAufenthalt`, `StandortAufenthaltStore`, `GeofenceWaechter`, plus Wiring in `myMiniApp`, `ContentView`, `GlanceCockpitView`, `ProjectRow`, `VerbindungenView` |

### Batch 5 (04.07., auf Rückfrage "AR? Die smarten Kameras?") — echtes AR

Bis hierher waren "smarte Kameras" nur Foto-Analyse (OCR, Helligkeit,
Farbtemperatur) und ein 2D-Live-Scanner (Barcode). Diese Batch bringt
echtes ARKit/RoomPlan dazu — bewusst nur die Teile ohne Session-übergreifende
Anker-Persistenz (die bleibt beim #51-Rest/#53-Risiko, siehe unten).

| Idee(n) | Was | Datei(en) |
|---|---|---|
| #7-Fundament AR-Maßband | Allgemeines Punkt-zu-Punkt-Maßband statt nur "Fahrstuhl-Check" — ARKit-Raycast gegen geschätzte Ebenen, zwei Tipps ergeben eine Distanz, Reset-Knopf. Einzelne AR-Session, keine Anker-Persistenz nötig | `ARMassbandMesser`, `ARMassbandBridge`, `ARMassbandScreen` |
| #6 AR-Anker für Gewerke | Wasser/Strom/Abfluss/Sonstiges im Raum markieren (farbiger, beschrifteter Marker je nach gewähltem Typ), Screenshot der AR-Szene (`sceneView.snapshot()`) enthält die Marker direkt. Landet in der **bestehenden** `FeldFotoBestaetigungView` (Projekt-/Kanon-Ziel-Wahl wiederverwendet, kein Doppelbau) | `GewerkeTyp`, `ARAnkerBridge`, `ARAnkerScreen` |
| #5 RoomPlan-Aufmaß | Apples eigenes RoomPlan-Framework — Apple liefert die Scan-UI und 3D-Verarbeitung, wir wiren nur Start/Stopp + USDZ-Export + Speicherung (gleiches Zwei-Datei-Muster wie `FeldFotoStore`). Vorschau über das eingebaute `.quickLookPreview` (kein eigener 3D-Viewer nötig). LiDAR-Geräte-Check mit ehrlichem Fallback. **Das unsicherste Stück dieser Batch** — RoomPlans Delegate-Protokolle sind neuer/versionsabhängiger als klassisches ARKit; ein fehlender Protokoll-Stub wäre ein kleiner, von Xcode direkt vorgeschlagener Fix, kein grundlegendes Problem | `RoomPlanAufnahme`, `RoomPlanStore`, `RoomPlanCaptureBridge`, `RoomPlanCaptureScreen`, `RoomPlanListView` |

**Alle drei nicht live testbar von hier** — ARKit-Genauigkeit und RoomPlans
Verhalten hängen stark von Gerät/Umgebung ab, das bleibt ein bewusster
Beta-Check wie beim ★3 Drive-Upload. Keine neue Info.plist-Berechtigung
(ARKit/RoomPlan nutzen dieselbe Kamera-Berechtigung wie alles andere).

**#38 AR-Vorschau der geplanten Küche im echten Raum bleibt blockiert** —
nicht aus Sorgfalt und nicht durch Johannes' OAuth/Hardware, sondern weil
schlicht **kein 3D-Modell der geplanten Küche aufs Handy kommt**: es gibt
keine Export-Pipeline von VectorWorks/Onshape zu einem AR-platzierbaren
Format (USDZ/Reality) auf mobile. Das wäre ein eigenes, größeres Vorhaben
(Schiffs-Export-Format + Downlink-Kanal dafür), kein AR-Coding-Problem.

### Batch 8+9 (04.07., Weiterflug)

| Idee(n) | Was | Datei(en) |
|---|---|---|
| #38 Stufe 1: Planmodelle in AR | USDZ-Import (`.fileImporter`, security-scoped), Projekt explizit zugeordnet, Ansicht über natives AR Quick Look — frei im Raum platzierbar. **Bewusst OHNE automatische Raum-Ausrichtung** (Stufe 2 = eigenes Vorhaben, automatische CAD-zu-Scan-Registrierung ist ein Forschungsproblem). Johannes' Pipeline-Seite dokumentiert: VectorWorks → 3D-Export → Reality Converter → USDZ → AirDrop | `PlanModell`, `PlanModellStore`, `PlanModellView` |
| Abnahmeprotokoll-PDF | Nummerierte Mängel + Foto + Erfassungszeit als übergabefähiges A4-PDF, Seitenumbruch bei Platzmangel — der beim #11-Bau zurückgestellte Export, eingelöst nachdem der Grundriss-Export das `UIGraphicsPDFRenderer`-Muster etabliert hat | `AbnahmeprotokollPDFRenderer`, `TeilenAnsicht` (geteilt) |
| Förder-Beweispaket-PDF | Einreichfertiger KfW/BAFA-Bericht: Deckblatt + eine datierte Seite je Beleg (EXIF-Zeit, Standort falls erfasst, chronologisch). Der Roh-Bilder-Share bleibt daneben bestehen — der beim #52-Bau zurückgestellte PDF-Bericht, jetzt eingelöst | `FoerderBeweispaketPDFRenderer` |

Dazu `docs/20_BERECHTIGUNGEN.md` als **die eine verbindliche
Info.plist-Liste** (7 Einträge) — Anlass: ein unabhängiger Review-Pass
(04.07., 90 Dateien, alle View-Verdrahtungen geprüft, null Fehler, kein
toter Code) fand, dass `NSContactsUsageDescription` nur im
Visitenkarten-Lieferzettel stand, nirgends in docs/. Regel ab jetzt: neue
Berechtigung = Eintrag dort im selben Commit.

## Zurückgestellt (Sorgfalt, nicht Johannes)

- #42 Sonnenverlauf/Azimut-Berechnung und #58 Planungs-Assistent-
  Empfehlungslogik (beide auf #43 Beleuchtungs-Check aufbauend) — brauchen
  eine geprüfte Astronomie-Bibliothek bzw. deutlich mehr Verifikationszeit,
  um nicht stillschweigend falsche Werte zu liefern. Kein Blocker durch
  Johannes, bewusste Qualitätsentscheidung.
- #51-Rest (ARWorldMap-Rückkehr zum exakten Vorher-Standort) + #53 Geführte
  Perspektiven-Sequenz — echte ARKit-Weltanker-Persistenz ist ein größerer,
  eigenständiger Baustein mit mehr Fehlerfläche (Anker-Drift, Session-
  Wiederherstellung). **#52 selbst ist inzwischen in seiner erreichbaren
  Teilmenge gebaut** (siehe Batch 2 oben) — nur der AR-Teil bleibt hier
  zurückgestellt, das Dokument soll nicht so lesen, als wäre #52 komplett
  offen.
- #48 Front+Back gleichzeitig (`AVCaptureMultiCamSession`) — Johannes selbst
  hat das in der Nacht als "Delight statt Kernwerkzeug" eingeordnet. Anders
  als alle bisherigen Kamera-Bausteine ließe sich das nicht über die
  vorhandene `KameraAufnahmeView`-Brücke (`UIImagePickerController`) bauen,
  sondern bräuchte eine komplett eigene `AVCaptureMultiCamSession`-Architektur
  mit zwei Preview-Layern und Geräte-Support-Check — spürbar mehr
  Fehlerfläche für ein selbst als "nice-to-have" eingestuftes Feature. Bewusst
  zurückgestellt, nicht gebaut.

## Bewusst zurückgestellt — braucht Johannes

- #61 Kalender-Disambiguierung, jede Google-Calendar-Idee → Google-OAuth wie
  ★3, eigene Freigabe-Runde nötig (anderer Scope, andere Consent-Screen-Zeile)
- #14/#20/#63/#64 DISTO-Laser, ColorReader, FLIR, Trotec-Feuchtemesser →
  Bluetooth-Hardware, die Johannes besitzen/koppeln muss
- #2 Ideen-Topf-Zielheimat → Airtable-Business-Entscheidung, unverändert offen
- Alles, was echte Drive-/Airtable-Schreibrechte über die bereits gebauten
  ★1/★3-Kanäle hinaus bräuchte

## Nicht (mehr) sinnvoll ohne Schiffs-Daten

Einige Ideen setzen WorkBasket-/Kalkulations-Daten voraus, die nicht auf
mobile gespiegelt sind (kein Sync gebaut, bewusst außerhalb des v0-Rahmens):
Wächter-Blick-Fälle, die WorkBasket vergleichen (#36 Lieferweg-Match u. a.),
DeviceCatalog-Jackpot (#24), Kosten-Kamera-Feinschliff. Diese werden als
**Rohdaten-Log ohne Abgleich** gebaut, wo sinnvoll (siehe Barcode-Scanner
oben) — der volle "Vergleich gegen Schiffsdaten"-Teil bleibt ein späterer,
eigener Schritt (bräuchte einen WorkBasket-Sync-Mechanismus, der noch nicht
existiert).

## Stand nach Batch 5

Der "brauche ich nicht von dir"-Teil von `journal/IDEEN_CHRONOLOGISCH.md` ist
durchgearbeitet, inklusive der Geofencing-Rückfrage (jetzt Off-by-default-
Toggle) und einer vollen AR-Runde (Maßband, Gewerke-Anker, RoomPlan). Was
übrig ist, fällt in eine der vier Kategorien oben: Sorgfalt-Rückstellungen
(Sonnenverlauf, ARWorldMap-Rückkehr, Multi-Cam), echte Johannes-Blocker
(Google-OAuth, Bluetooth-Hardware, Airtable-Entscheidung), fehlende
Eingabe-Pipeline (#38 — kein 3D-Modell-Export existiert), oder
WorkBasket-Abhängigkeit. Kein Baustein wurde übersprungen, ohne hier
aufzutauchen.
