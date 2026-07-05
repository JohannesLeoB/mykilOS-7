# Google-Client-ID für myMini — der Nachmittags-Termin als Spaziergang

Ziel: eine iOS-Client-ID, damit der Satellit sich bei Google anmelden und
Feld-Fotos in die Projekt-Drive-Ordner syncen kann (★3, letzter Baustein).
Dauer: ~10 Minuten. Alles passiert im Browser auf dem Mac + zwei Klicks in
Xcode.

## Teil 1 — Google Cloud Console (Browser)

1. **console.cloud.google.com** öffnen, mit dem MYKILOS-Google-Konto
   anmelden (dasselbe, das das Mothership nutzt).
2. Oben links im **Projekt-Dropdown**: das Projekt wählen, das schon fürs
   Mothership existiert (dort liegen bereits OAuth-Clients für Drive & Co.).
   **Kein neues Projekt anlegen** — gleiches Projekt = Drive-API ist schon
   aktiviert und der Consent-Screen schon eingerichtet.
3. Links im Menü: **APIs & Services → Credentials** (deutsch: „Anmeldedaten").
4. Oben: **+ Create Credentials → OAuth client ID**.
5. **Application type: iOS** (wichtig — nicht „Desktop", nicht „Web").
6. Ausfüllen:
   - Name: `myMini`
   - **Bundle ID: `com.johannes.myMini`** (exakt so)
   - App Store ID / Team ID: leer lassen
7. **Create** → es erscheint die **Client-ID**, sie endet auf
   `.apps.googleusercontent.com`. Kopieren (Kopier-Symbol daneben) und
   z. B. in die Notizen legen.

Falls die Konsole zwischendurch nach einem „OAuth consent screen" fragt:
das heißt, es ist doch ein anderes/frisches Projekt — dann kurz Foto in
den Chat, das lotse ich dich in 2 Minuten durch.

## Teil 2 — Xcode (2 Klicks + 1 Einfügen)

Google verlangt fürs Zurückspringen in die App ein URL-Schema — das ist
die **umgedrehte Client-ID**:

- Client-ID: `123456-abcdef.apps.googleusercontent.com`
- URL-Schema: `com.googleusercontent.apps.123456-abcdef`
  (also: `com.googleusercontent.apps.` + der Teil VOR
  `.apps.googleusercontent.com`)

1. Xcode → blaues Projekt-Symbol → Ziel `myMini` → Tab **Info**.
2. Ganz unten: **URL Types** aufklappen → **+**.
3. Bei **URL Schemes** das umgedrehte Schema eintragen (sonst nichts
   ausfüllen).
4. ⌘R.

## Teil 3 — In der App

1. Verbindungen (Antennen-Symbol) → **Google Drive**.
2. Client-ID einfügen (die normale, NICHT die umgedrehte) → **Bei Google
   anmelden** → Google-Login im eingeblendeten Fenster.
3. Test: ein Feld-Foto aufnehmen → Fotos-Kachel → **Sync** beim Foto.

**Ehrliche Erwartung beim ersten Sync:** Das ist der allererste Live-Test
der `drive.file`-Annahme (Schreiben in einen VORHANDENEN Projektordner) —
die war selbst im Mothership nie live bestätigt. Wenn ein Fehler kommt
(besonders „403"): Foto in den Chat — das ist ein *Befund*, kein Bug, und
wir haben einen Plan B (Google Picker / breiterer Scope).
