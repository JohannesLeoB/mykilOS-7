# Sensorik-Technik — Wie die iOS-App die Daten wirklich abfängt

**Der Ingenieurs-Pass (Nacht 04.07.):** Jede Idee aus Topf & Freidenken, geerdet in
echten Apple-Frameworks, Berechtigungen und Grenzen. Stand iOS 18/26-Ära.

## Die Abfang-Architektur (ein Muster für alles)

```
FANG (Sensor/Framework, on-device)
  → VORVERDICHTEN (on-device: OCR, Transkript, Geocoding — Rohdaten bleiben lokal)
    → VERSTEH (destillierter Text → Cloud-KI nur wo nötig; Kandidaten statt Raten)
      → VERRÄUM (Postbox/Drive/Airtable, gated; Offline-Queue wenn kein Netz)
```

**Privacy-Prinzip = Apple-Prinzip:** Rohes (Audio, Vollbilder, Bewegung) wird
on-device verdichtet; in die Cloud reist nur das Destillat. Offline-first via GRDB
(läuft auf iOS — Mothership-DNA bleibt).

## Sinn für Sinn

### 👁 Kamera & Bild
| | |
|---|---|
| Frameworks | `AVFoundation` (Capture) · `VisionKit.DataScannerViewController` (**Live-OCR im Sucher!**) · `Vision` (`VNRecognizeTextRequest` = Typenschild-OCR on-device) · `PHPickerViewController` (Fotoauswahl **ohne** Foto-Berechtigung) |
| Berechtigung | `NSCameraUsageDescription` — ein Satz, einmal gefragt |
| Grenzen | Marken-Erkennung vom Aussehen unsicher (→ Kandidaten); Low-Light frisst OCR |
| Unsere Fälle | Typenschild→Geräteakte ✓ · Visitenkarten · Kosten-Kamera · ★3-Projekt-Kamera · EXIF (Zeit+GPS) gratis am `PHAsset` |

### 👂 Mikrofon & Sprache
| | |
|---|---|
| Frameworks | `Speech`/`SFSpeechRecognizer` — **Deutsch läuft on-device** (kein Cloud-Zwang fürs Transkript!); neue `SpeechAnalyzer`-Generation noch schneller · `AVAudioRecorder` · `AVSpeechSynthesizer` (Morgen-Brief **vorlesen**, offline-Stimmen) |
| Berechtigung | `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` |
| Grenzen | Werkstatt-Lärm senkt Qualität; Mitschnitt nur mit Einverständnis (§ 201) |
| Unsere Fälle | Zeit fangen per Stimme · Diktat-Protokolle · Erstgespräch-Pipeline (Transkript bleibt, Audio verglüht — on-device!) · Werkstatt-Modus |

### 🧭 Ort & Geofence
| | |
|---|---|
| Frameworks | `CoreLocation` (3–5 m draußen) · `CLGeocoder` (**Reverse-Geocoding gratis, von Apple**) · `CLMonitor`-Geofences · 💎 `UNLocationNotificationTrigger`: **lokale Mitteilung beim Betreten eines Radius — OHNE Server, ohne Push-Zertifikat!** „Du bist bei Schmidt" geht rein lokal |
| Berechtigung | „Beim Verwenden" reicht für uns — **kein Always-Tracking, Privacy-RAIL by design** |
| Grenzen | Innenräume driften (Messmoment = Haustür); Etage unbekannt → Barometer |
| Unsere Fälle | Adress-Loop · Stadt-Cluster (Brain) · Ankunfts-Trigger · „Hinfahren" |

### ⚖️ Bewegung, Gleichgewichtssinn & Höhe
| | |
|---|---|
| Frameworks | `CoreMotion`: `CMDeviceMotion` (fusionierte Lage ~100 Hz — Lot/Waage/Transport-Wächter) · `CMAltimeter` (**Barometer: Etagenwechsel!**) · `CMMotionActivityManager` (erkennt Gehen/Fahren → Rundgang-Modus schlägt sich selbst vor) |
| Berechtigung | Roh-Sensorik: keine! Aktivitätserkennung: `NSMotionUsageDescription` |
| Grenzen | Barometer = relativ (Wetterdrift) — Etagen-*Wechsel* ja, absolute Etage kalibrieren |
| Unsere Fälle | Einbau-Lot-Check · Transport-Wächter · „4. OG ohne Aufzug" · Rundgang-Erkennung |

### 📐 AR & Raum
| | |
|---|---|
| Frameworks | `ARKit` (Ebenen, Maße ±1–2 cm) · 💎 **`ARWorldMap`: AR-Anker PERSISTENT speichern** — „Wasser hier"-Tags überleben und liegen beim nächsten Besuch wieder an der Wand! · `RoomPlan` (Raum→3D, **nur LiDAR-Geräte**) |
| Berechtigung | Kamera reicht |
| Grenzen | Ohne LiDAR kein RoomPlan (Johannes' iPad 7 raus, LiDAR-iPhone nötig); weiße Wände tracken schlecht |
| Unsere Fälle | AR-Anker Wasser/Strom · Fahrstuhl-Check · Aufmaß Stufe 2 · SOLL/IST |

### ☀️ Licht & Optik (ergänzt 04.07.)
| | |
|---|---|
| Frameworks | `AVCaptureDevice.temperatureAndTintValuesFromDeviceWhiteBalanceGains` (echter Kelvin-Wert, kein Extra-Sensor) · ISO+Verschlusszeit → Helligkeits-Kategorie (kein Lux-API für Drittanbieter — Apple-Grenze) · `CLLocationManager`-Kompass + Projekt-GPS + Datum → **exakte Sonnenstand-Berechnung** (reine Astronomie, keine Unsicherheit) |
| Grenzen | Kein rohes Lux — nur Kategorie · **Glanz/Glas/Spiegel verwirren ARKit/Vision** (Tiefensensor + Materialerkennung beide betroffen) — echte Grenze, nicht lösbar am Gerät |
| Unsere Fälle | Kelvin qualifiziert Farbpipette + Wächter „Licht-Alt vs-Neu" · Sonnenverlauf für Fenster-/Arbeitsplatzplanung · Spiegelungs-Design gehört in Firefly/Moodboard-Rendering, NICHT live |

### 🎨 Farbe per Bluetooth (Datacolor ColorReader — Johannes' Gerät)
| | |
|---|---|
| Frameworks | `CoreBluetooth`, **offizielles Datacolor-SDK bestätigt** (Branding, BLE-Anbindung, Cloud-Fleet — kein Reverse-Engineering nötig, anders als beim Laser) |
| Grenzen | Lizenz-/SDK-Bedingungen prüfen (Fleet-Management deutet auf B2B-Vertrag hin) |
| Unsere Fälle | **Farb-Toleranzen-Doktrin:** Kamera-Kelvin = Schätzung, ColorReader = Werkfarbe (RAL/NCS/Pantone exakt) — Schwester der Maß-Doktrin |

### 📶 Bluetooth (Laser!) & NFC
| | |
|---|---|
| Frameworks | `CoreBluetooth` (GATT) — Leica DISTO + Bosch GLM funken BLE, Protokolle community-dokumentiert, Bibliotheken existieren · `CoreNFC` + 💎 **Hintergrund-Tag-Lesen: NFC-Sticker mit Universal Link öffnet die App am richtigen Projekt OHNE dass irgendwas vorher läuft** |
| Berechtigung | `NSBluetoothAlwaysUsageDescription`; NFC-Lesen im Hintergrund: keine |
| Grenzen | Bosch-Protokoll proprietär (reverse-engineered, robust aber ungarantiert) |
| Unsere Fälle | Laser-Tackern ins Aufmaß-Formular · NFC-Projektanker (30-Cent-Magie) |

### ⌚️📱 System-Integration (der Fingerschnipps-Layer)
| | |
|---|---|
| Frameworks | `App Intents`: **„Hey Siri, Zeit fangen"** + Action-Button + Kurzbefehle — EIN Framework bedient alle drei · `WidgetKit` (Lock-Screen-Puls) · `ActivityKit` (Live Activity/Dynamic Island: laufender Projekt-Timer — lokal gestartet, kein Server) · `BGTaskScheduler` + **Background-`URLSession`: Foto-Upload läuft weiter, wenn die App zugeht** |
| Grenzen | Live-Activity-*Fernupdates* + echte Push = APNs → Developer-Account + Serverchen [SPÄTER]; local-first-Variante deckt 90 % |
| Unsere Fälle | Fingerschnipps · Puls-Widget · Timer-Activity · zuverlässige Feld-Uploads |

### 📸📸 Front+Back gleichzeitig
| | |
|---|---|
| Frameworks | `AVCaptureMultiCamSession` (iOS 13+, A12-Chip/iPhone XS aufwärts) — offiziell unterstützt, kein Hack |
| Grenzen | Eher Delight- als Kernwerkzeug; Gesichtsfoto = sensibler → explizites Einverständnis (Datenschutz-Doktrin §14) |
| Unsere Fälle | Testimonial-Shot bei Übergabe (Kunde+Küche) · „Ich war hier"-Provenienz bei kritischer Abnahme |

### 🌡 Waermebild + Feuchtigkeit (Zubehoer, bestaetigt 04.07.)
| | |
|---|---|
| Geraete | **FLIR Edge Pro** (offizielles Mobile SDK, iOS+Android, kabellos) \u00b7 **Trotec BM22WP** (Bluetooth-appSensor, Feuchte per Widerstandsmethode) |
| Grenzen | Trotec-SDK fuer FREMDE Apps nicht bestaetigt (nur eigene MultiMeasure-App sicher belegt) \u00b7 Waermebild zeigt kuehle Flecken als FEUCHTE-KANDIDAT, ist kein Feuchtemesswert |
| Unsere Faelle | Kaeltebruecken, Fussbodenheizungs-Verlauf, versteckte Warmwasserleitung vor dem Bohren \u00b7 Feuchte-Waechter: Waermebild-Verdacht -> Trotec-Geraet bestaetigt |

### 🧠 On-Device-KI
`Vision` (Bild) · `NaturalLanguage` (Entitäten) · `CoreML` (eigene Klassifikatoren —
z. B. Material-Kandidaten trainierbar) · Apple-Intelligence-Foundation-Models
(kleines on-device-LLM) für Offline-Extraktion — **die schwere Versteh-Arbeit bleibt
bei Cloud-Claude, aber der Baustellen-Keller ohne Empfang ist nicht blind.**

## Die drei Ingenieurs-Wahrheiten

1. **Fast alles ist Bordmittel.** Kein einziges Drittanbieter-SDK nötig für 90 %
   des Katalogs — Apple liefert Sensor-Frameworks, wir liefern Verstand + RAILs.
2. **Berechtigungen sind UX:** jede Abfrage erst im Moment des ersten Nutzens,
   mit ehrlichem Satz. Kein Berechtigungs-Gewitter beim ersten Start.
3. **Offline ist Pflicht, nicht Kür:** Baustellenkeller. GRDB-Queue für alles
   Gefangene, Verräumen sobald Netz — der Dreitakt darf nie am Empfang scheitern.
