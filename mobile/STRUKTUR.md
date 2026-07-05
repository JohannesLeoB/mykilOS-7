# STRUKTUR — was jeder Ordner enthaelt

Der Quellcode liegt in `myMini/`, thematisch in nummerierte Ordner sortiert.
Die Nummern geben eine grobe Lese-Reihenfolge (Fundament zuerst).

| Ordner | Inhalt |
|---|---|
| **00-App** | App-Start (`myMiniApp`), Wurzel (`ContentView`), iPad-Layout (`IPadRootView`, `IPadProjekteView`) |
| **01-DesignSystem** | Farben/Token (`MykColor`), deutsche Fehlertexte (`Fehlertext`), Teilen-Helfer (`TeilenAnsicht`) |
| **02-Cockpit** | Herzschlag-Startseite (`GlanceCockpitView`), Hot-Projekt-Karte, Fang-Karte |
| **03-Projekte** | Projekt-Modell + Store, Zeile, Info-Modus, gefuehrter Auftrag |
| **04-Postbox** | Fang-Ablage (Zeit/Ideen) |
| **05-FeldFotos** | Kamera, Foto-Modell + Store, Bestaetigung, Liste, Foerder-Beweispaket |
| **06-Sprache** | Diktat (Speech-to-Text), Morgen-Brief (Sprachausgabe) |
| **07-Kontakte** | Kunden-Verzeichnis, Visitenkarten-OCR -> Kontakt |
| **08-Wareneingang** | Lieferschein-OCR, Wareneingangs-Log |
| **09-Werkzeuge** | Werkzeug-Sammlung: Beleuchtung, Wasserwaage, Farbtemperatur, Raumakustik, Abnahmeprotokoll, Sonnenverlauf, Foto-Bemassung, Anleitungen |
| **10-Barcode** | QR-/Barcode-Scanner + Log |
| **11-AR-RoomPlan** | AR-Massband, AR-Anker/Gewerke, RoomPlan-Aufmass, Grundriss-Export, Planmodelle |
| **12-Laser** | Bluetooth-Laser-Empfaenger, Leica-Protokoll, Dekoder-Kaskade, Adapter |
| **13-Kreativ-Firefly** | Kreativ-Studio, Referenzkuechen, Firefly-Prompt + Render-Client |
| **14-Copilot** | Satellit-Copilot (Tool-Use), Claude-Client, Chat |
| **15-Vertrag** | Vertrags-Signatur (SHA-256-Siegel) |
| **16-Service** | Service-Anfragen an Hersteller (vorbefuellte Mail) |
| **17-Standort** | Geofence-Waechter, Standort-Sensor, Aufenthalte |
| **18-Google** | Google OAuth + Drive-Upload |
| **19-Airtable** | Airtable-Clients (Kunden, Postbox) |
| **20-Kopplung** | Satellit-Kopplung (Paket, Import, Sicherheit, Bindung), Feldbericht |
| **21-Verbindungen** | Verbindungs-/Faehigkeiten-Panel |
| **Resources** | `projekte.json` (Registry-Schnappschuss vom Schiff) |

## docs/

Design- und Schnittstellen-Dokumente. Besonders wichtig — die **Vertraege**
zwischen Satellit und Mothership:

- `23_MOTHERSHIP_ANTENNE.md` — Schiff -> Satellit (projekte.json-Felder)
- `24_RUECKKANAL.md` — Satellit -> Schiff (Feldbericht)
- `25_KOPPLUNG.md` — verschluesseltes Kopplungs-Paket + PIN
- `26_GERAETE_KOPPLUNG_STRATEGIE.md` — persoenlich/geteilt, Kosmos, Rollen
- `27_MOTHERSHIP_FAMILIENBRIEF.md` — die Familie auf einen Blick
