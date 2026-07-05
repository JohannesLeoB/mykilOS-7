# Deep-Link-Matrix — wie der Dirigent in die nativen Apps springt

**Prinzip (Live-Beweis ① bestätigt): Deep-Links auf IDs bauen, nie auf Namen.**
Status-Legende: ✅ live verifiziert · 📘 dokumentiertes Standard-Muster (noch nicht
von uns am Gerät getestet) · ❌ geht nicht → Postbox.

## Hinspringen (lesen/navigieren)

| Ziel | Link-Muster | Status |
|---|---|---|
| Drive-Ordner | `https://drive.google.com/drive/folders/<folderID>` | ✅ echte URLs aus der Live-API (Schmidt-Beweis); öffnet am iPhone die Drive-App |
| Drive-Datei | `https://drive.google.com/file/d/<fileID>/view` | 📘 Standard-Muster |
| Google Maps Route | `https://www.google.com/maps/dir/?api=1&destination=<adresse-urlencoded>` | 📘 offizielles Maps-URL-API; öffnet die Maps-App |
| Apple Maps (Fallback) | `https://maps.apple.com/?daddr=<adresse>` | 📘 |
| ClickUp Task | `https://app.clickup.com/t/<taskID>` | 📘 Universal Link, öffnet die App |
| ClickUp Liste | `https://app.clickup.com/<teamID>/v/l/<listID>` | 📘 — Schmidt hat noch keine `clickUpListID` (M3 offen) |
| Slack Kanal | `https://<workspace>.slack.com/archives/<channelID>` | 📘 |
| Gmail Thread (Web) | `https://mail.google.com/mail/u/0/#all/<threadID>` | 📘 — am iPhone landet das im Browser, nicht sicher in der Gmail-App |
| Kalender-Termin ANLEGEN | `https://calendar.google.com/calendar/render?action=TEMPLATE&text=…&dates=…` | 📘 — **exakt das Muster, das das Mothership schon nutzt** (`SuggestCalendarEventTool`, URL → Browser, kein API-Write). Geerbtes, gesegnetes Muster. |

## Schreiben (vorbefüllt) — die ehrliche Wand

| Wunsch | Realität | Weg |
|---|---|---|
| „4h CAD für Heinz" fertig in Clockodo-App übergeben | ❌ kein Prefill-Deep-Link | **Postbox**: Adapter-Base `appuQDCFGLmjo2L6T` → Zeitbuchungen (existiert, s. Star Map) |
| Foto in Drive-Projektordner legen | ❌ Drive read-only (RAIL) | **Postbox-Kanal ★3 — ungeklärt, wird nicht gebaut** |
| ClickUp-Task anlegen | teils (App öffnen ja, Prefill nein) | gated Karte → Connector-Write (nur Testspace) |

**Merksatz:** Springen ist billig, Schreiben ist heilig.
