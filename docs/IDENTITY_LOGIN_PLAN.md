# Identity, Login & Keychain — Plan

**Ausgangsfrage (User, 2026-06-27):** *"Ich habe beim Start der App mindestens
acht mal den Screen, dass ich mein Passwort und Schlüsselbund freigeben muss.
Ich will nur einen einzigen Login in mykilOS 6 mit Nutzer-ID, und dann sind
alle Passwörter und Sub-Logins drin."*

Zwei getrennte Probleme stecken in dieser einen Beobachtung — sie brauchen
unterschiedliche Lösungen, daher dieser Plan in zwei Teilen.

---

## Teil 1: Die 8 Prompts — Root Cause ist die Code-Signatur, nicht die Architektur

### Diagnose

mykilOS 6 legt **7 getrennte Keychain-Einträge** an, einen pro Integration:

| Service-Identifier | Datei |
|---|---|
| `com.mykilos6.google` | `KeychainGoogleTokenStore.swift` |
| `com.mykilos6.clockodo` | `KeychainClockodoCredentialsStore.swift` |
| `com.mykilos6.clickup` | `KeychainClickUpCredentialsStore.swift` |
| `com.mykilos6.sevdesk` | `KeychainSevdeskCredentialsStore.swift` |
| Airtable-Service (analog) | `KeychainAirtableCredentialsStore.swift` |
| Claude-API-Key | `ClaudeAuthService`-Keychain-Backing |
| (Google-OAuth-PKCE-Zwischenstand, falls separat) | `KeychainStore.swift` |

Das ist für sich genommen **nicht** das Problem — macOS fragt pro
Keychain-Service normalerweise nur **einmal**, dann merkt es sich "diese App
darf auf diesen Service zugreifen" dauerhaft, verknüpft an die
Code-Signatur der App.

**Der eigentliche Grund für die wiederholten Prompts:** `build_and_run.sh`
signiert das Bundle bei fehlender stabiler Identität **ad-hoc**
(`codesign --sign -`). Eine Ad-hoc-Signatur erzeugt bei **jedem Build einen
neuen Hash** — macOS sieht das technisch als eine *komplett neue App* und
fragt deshalb bei jedem einzelnen Keychain-Service erneut. Bei 7 Services
× jeder Rebuild = genau das beobachtete Verhalten. Das Script kennt das
Problem bereits und dokumentiert die Lösung in einem Kommentar, den der User
bisher nicht umgesetzt hat.

### Sofort-Fix (kein Code, nur einmalige macOS-Einrichtung)

1. **Schlüsselbundverwaltung** öffnen (Spotlight → "Schlüsselbundverwaltung").
2. Menü **Zertifikatsassistent → Ein Zertifikat erstellen…**
3. Name: **exakt** `mykilOS Local Signing` (das Script sucht nach genau
   diesem String).
4. Identitätstyp: **Selbstsigniertes Stammzertifikat**.
5. Zertifikatstyp: **Codesignatur**.
6. Erstellen, fertig.

Ab dem nächsten `mykilos-run` erkennt `build_and_run.sh` das Zertifikat
automatisch (`/usr/bin/security find-identity -v -p codesigning`) und
signiert damit statt ad-hoc — die Signatur bleibt über Rebuilds hinweg
stabil, macOS fragt pro Service nur noch **einmal**, dauerhaft.

**Das ist die Lösung mit dem höchsten Hebel und null Code-Aufwand** — bitte
zuerst ausprobieren, bevor an Teil 2 gearbeitet wird.

---

## Teil 2: Ein einziger mykilOS-Login statt 7 getrennter Verbindungen

Das ist die größere, architektonische Frage — kein Bug, sondern ein
Produktentscheid mit echten Trade-offs. Hier nur der Plan, **keine
Umsetzung ohne deine Entscheidung zu den Optionen unten.**

### Was "ein Login" technisch bedeuten könnte

**Option A — Master-Passwort/App-Lock vor den bestehenden Keychain-Einträgen**
mykilOS bekommt einen eigenen Anmeldebildschirm (Passwort oder
Touch-ID/Apple-Watch via `LocalAuthentication`), der beim App-Start einmal
entsperrt. Die 7 Keychain-Einträge bleiben technisch bestehen (ändert nichts
an Sicherheit/Architektur), aber die App liest sie beim Start automatisch
nach erfolgreicher Entsperrung — der Nutzer sieht nur noch *einen* Prompt
(den eigenen App-Lock), nicht mehr die einzelnen macOS-Keychain-Dialoge
(die fallen mit Teil 1's Fix eh weg, sobald die Signatur stabil ist).
**Aufwand: mittel.** Setzt Teil 1 voraus, sonst doppelte Baustelle.

**Option B — Echtes Single Sign-On über einen Identity Provider**
Ein Account (z. B. Google Workspace SSO oder ein eigener mykilOS-Account)
wird zur einzigen Anmeldung; alle anderen Dienste (Clockodo, ClickUp,
Sevdesk, Airtable) bekommen ihre Tokens **nicht** mehr einzeln vom Nutzer,
sondern über eine zentrale Vermittlungsschicht (Backend nötig — bricht mit
"local-first, kein Sync-Backend in V1", siehe Team-Modell in CLAUDE.md).
**Aufwand: hoch, Architekturbruch.** Nicht ohne expliziten Strategiewechsel
empfehlenswert.

**Option C — Ein verschlüsselter "Vault" in mykilOS selbst**
Alle Tokens wandern aus 7 einzelnen Keychain-Einträgen in **einen**
einzigen, durch ein mykilOS-Master-Passwort verschlüsselten Container
(z. B. eine verschlüsselte SQLite/JSON-Datei, Schlüssel aus dem
Master-Passwort via PBKDF2 abgeleitet). Ein Login entschlüsselt den Vault,
danach sind alle Sub-Logins im Speicher verfügbar. **Aufwand: hoch** (neue
Crypto-Schicht, Migration aller bestehenden Keychain-Stores, eigenes
Bedrohungsmodell für den Vault selbst). Verstößt nicht gegen "nur Keychain"
— der Vault könnte selbst wieder im Keychain liegen (ein Eintrag statt 7).

### Empfehlung

1. **Teil 1 (Signatur-Fix) sofort umsetzen** — behebt das eigentliche
   Symptom (8 Prompts) fast vollständig, ohne Architekturrisiko.
2. **Danach beobachten:** Wenn nach dem Signatur-Fix nur noch *ein* Prompt
   pro Service beim allerersten Connect erscheint (erwartetes, normales
   macOS-Verhalten — vergleichbar mit jeder anderen Mac-App, die Keychain
   nutzt) — ist das Problem in der Praxis vermutlich schon gelöst, und
   Option A/B/C werden überflüssig.
3. **Falls danach immer noch zu viele Prompts/Reibung empfunden wird:**
   Option A (eigener App-Lock-Screen) ist der beste Kompromiss — löst das
   UX-Problem ("ein Login") ohne die local-first-Architektur zu brechen
   oder eine neue Crypto-Schicht zu bauen.
4. **Option B nur, falls mykilOS sich grundsätzlich Richtung Team-Backend/
   Cloud-Sync entwickeln soll** — das ist eine andere, größere Entscheidung
   als "weniger Prompts" und sollte nicht nebenbei mitentschieden werden.

### Offene Entscheidung für den User

Bevor hier Code geschrieben wird: **Bitte zuerst Teil 1 ausprobieren** und
zurückmelden, ob das Problem damit gelöst wirkt. Erst danach lohnt sich die
Entscheidung zwischen Option A/B/C — alles andere wäre Vorgriff auf eine
Anforderung, die sich durch den einfachen Fix vielleicht erübrigt.
