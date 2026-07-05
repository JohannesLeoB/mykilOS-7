# Berechtigungen — die eine verbindliche Liste

Bisher standen die nötigen Info.plist-Einträge verstreut in den einzelnen
EINFUEGEN.md-Lieferzetteln. Ein unabhängiger Review-Pass (04.07.) hat gezeigt,
dass genau dadurch einer durchgerutscht wäre (Kontakte — stand nur im
Visitenkarten-Lieferzettel, nirgends in docs/). Ab jetzt: **diese Datei ist
die eine Wahrheit.** Jede neue Berechtigung wird hier eingetragen, im selben
Commit wie das Feature.

## Aktuell nötige Info.plist-Einträge (Xcode → Ziel myMini → Tab "Info")

| Schlüssel | Xcode-Anzeigename | Wofür | Texts-Vorschlag |
|---|---|---|---|
| `NSCameraUsageDescription` | Privacy – Camera Usage Description | Feld-Fotos, Visitenkarten/Lieferschein-OCR, Barcode-Scanner, alle AR-Werkzeuge, RoomPlan | "mykilOS mobile nutzt die Kamera für Projekt-Fotos, Texterkennung, Scanner und AR-Werkzeuge." |
| `NSMicrophoneUsageDescription` | Privacy – Microphone Usage Description | Sprich-Aufnahme, Abnahmeprotokoll-Diktat, Raumakustik-Check | "mykilOS mobile nutzt das Mikrofon für Diktate und den Raumakustik-Check." |
| `NSSpeechRecognitionUsageDescription` | Privacy – Speech Recognition Usage Description | On-device-Transkription der Diktate | "mykilOS mobile wandelt Gesprochenes direkt auf dem Gerät in Text um." |
| `NSContactsUsageDescription` | Privacy – Contacts Usage Description | Visitenkarten-Kamera → Kontakt anlegen | "mykilOS mobile legt neue Kontakte aus fotografierten Visitenkarten an." |
| `NSLocationWhenInUseUsageDescription` | Privacy – Location When In Use Usage Description | Einmaliger Standort-Schnappschuss (Feld-Foto-EXIF, "Diesen Ort merken") — Apple verlangt diesen Schlüssel auch als Begleiter des Always-Schlüssels | "mykilOS mobile speichert auf Wunsch den Aufnahmeort von Projekt-Fotos." |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Privacy – Location Always and When In Use Usage Description | Standort-Wächter (Geofencing, Off-by-default-Toggle) | "mykilOS mobile erkennt, wenn du bei einem gemerkten Projekt-Standort bist, um Zeit vorzuschlagen — nur wenn du das im Fähigkeiten-Panel einschaltest." |
| `NSBluetoothAlwaysUsageDescription` | Privacy – Bluetooth Always Usage Description | Laser-Messgeräte-Kopplung (Off-by-default-Toggle) | "mykilOS mobile sucht nach Bluetooth-Messgeräten (Laser), nur wenn du das im Fähigkeiten-Panel einschaltest." |

## Ausdrücklich NICHT nötig

- `NSPhotoLibraryUsageDescription` — alle Kamera-Flows sind Live-Kamera
  (`sourceType = .camera`), nie Fotoalbum-Zugriff. Bewusstes ★3-Design:
  das Foto wird im Moment geboren, nie nachsortiert.
- Eigene Schlüssel für ARKit/RoomPlan/CoreMotion — laufen über die
  Kamera-Berechtigung bzw. brauchen (CoreMotion/Wasserwaage) gar keinen
  Consent-Dialog.

## Regel

Neue Berechtigung = neuer Tabelleneintrag hier, im selben Commit wie das
Feature, plus der Hinweis im EINFUEGEN.md des Lieferpakets. Der Lieferzettel
allein reicht nicht — der geht im Chat-Verlauf verloren, diese Datei nicht.
