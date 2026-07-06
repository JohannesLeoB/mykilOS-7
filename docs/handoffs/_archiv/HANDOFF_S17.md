# Handoff S17 — Security-Härtung + Google Identity

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/security-haertung
Build:  ✅ swift build grün
Tests:  ✅ 209 Tests grün (190 swift-testing + 19 XCTest)
Datum:  2026-06-28
```

---

## Was S17 gebaut hat

### Aufgabe 1 — AirtableSyncService.swift (No-Op, bestätigt)

Guard-Grep bestätigt: Die Datei existiert in keinem Swift-File, keinem Ref, keinem Blob.
```bash
git grep -lI 'AirtableSyncService|appkPzoEiI5eSMkNK|DispatchSemaphore' -- '*.swift'
# Exit 1 — leer. Kein Code-Change nötig.
```

### Aufgabe 3 — Airtable baseID-Validierung

**Neuer Error-Case:** `AirtableError.invalidBaseID(String)` in `AirtableClient.swift`

**Validierung** in `AirtableAuthService.connect(pat:baseID:)` direkt nach dem Trim/Empty-Guard:
- Regel: `trimmedBase.hasPrefix("app") && (15...22).contains(trimmedBase.count)`
- Fehlermeldung: erklärt dass PAT ins falsche Feld eingefügt wurde
- Verhindert nur künftige Fehl-Speicherungen — bestehende korrupte Keychain-Einträge bleiben

**Tests** (4 neue in `AirtableAuthServiceTests.swift`):
- PAT-förmige Base-ID → `invalidBaseID` geworfen
- Zu kurze Base-ID (`"app"`) → abgelehnt
- Gültige `"appuVMh3KDfKw4OoQ"` → akzeptiert
- Whitespace um gültige ID → Validierung gegen getrimmten Wert, Trim greift korrekt

**Bestehende Tests angepasst:** `"appXYZ"` → `"appuVMh3KDfKw4OoQ"` (zu kurz für neue Validierung)

### Aufgabe 4 — PAT-Cleanup (Dokumentation)

`docs/PAT_CLEANUP_S17.md` beschreibt:
- Was Johannes manuell in Airtable-Settings ändern soll (SCHATZ-Workspace entfernen, Scope einschränken)
- **Mastermind-Schreibrechte ERHALTEN** (Kalkulations-Port schreibt dort!)
- Artikel-DB `appdxTeT6bhSBmwx5` bleibt Code-only-READ-ONLY (Statut 5)

### Aufgabe 2 — Google-Identität nach Login

**`GoogleUserInfo`** (neu in `MykilosKit/Domain/`):
```swift
public struct GoogleUserInfo: Equatable, Sendable, Codable {
    public var email: String
    public var displayName: String
}
```

**Neue Scopes** in `GoogleOAuthScope.readOnlyDefaults`:
- `.userinfoEmail` (`userinfo.email`)
- `.userinfoProfile` (`userinfo.profile`)
→ Erfordert einmaliges Re-Consent (Johannes ist faktisch einziger Nutzer, akzeptiert)

**`GoogleTokenStoring`-Protokoll** erweitert:
- `storeUserInfo(_ userInfo: GoogleUserInfo) throws`
- `loadUserInfo() throws -> GoogleUserInfo?`
- `KeychainGoogleTokenStore`: implementiert (JSON wie tokens), `clear()` löscht userInfo mit

**`GoogleUserInfoClient`** (neu in `MykilosServices/Google/`):
- `GoogleHTTPClient`-Protokoll + `URLSession`-Conformance (spiegelt `ClaudeHTTPClient`)
- `fetchUserInfo(accessToken:)` gegen `/oauth2/v2/userinfo`
- Statische `buildRequest` + `parseUserInfo(from:)` — testbar ohne Netzwerk
- Fallback: `name` leer/nil → `displayName = email`

**`GoogleAuthService`**:
- `currentUser: GoogleUserInfo?` (published)
- `userInfoClient: GoogleUserInfoFetching` — injizierbar, Default `GoogleUserInfoClient()`
- Init rehydriert aus Keychain: `self.currentUser = try? tokenStore.loadUserInfo()`
- Hook nach `tokenStore.store(tokens)`: userinfo holen → cachen → `currentUser` setzen
- **Nicht-fatal:** `do/catch` — Profil-Hiccup rollt Token-Tausch nie zurück
- `disconnect()` setzt `currentUser = nil`

**`AppState`**: `public var currentGoogleUser: GoogleUserInfo? { googleAuth.currentUser }`

**`SidebarView`** (navFoot):
- Wenn `currentGoogleUser` vorhanden: `displayName` als Name, `email` als Subtitle
- Fallback: manueller Profilname aus `ProfileStore`
- Indikator-Farbe: `positive` wenn Google verbunden

**Tests** (7 neue in `GoogleUserInfoClientTests.swift`, `InMemoryGoogleTokenStore` erweitert):
- `buildRequest` setzt `Authorization: Bearer …`
- `parseUserInfo` mit Name → `displayName`
- `parseUserInfo` ohne Name → Fallback auf email
- Leerer Name → Fallback auf email
- Kaputtes JSON → `decodingFailed`
- Erfolgreicher Fetch via FakeHTTP
- 401 → `httpError(401)`

---

## Testzählung

| Vorher | Nachher | Delta |
|---|---|---|
| 198 (179 swift-testing + 19 XCTest) | 209 (190 swift-testing + 19 XCTest) | +11 |

Alle grün, keine Regressions.

---

## Offene Punkte / Was S17 NICHT gemacht hat

- **Re-Consent live verifizieren:** Johannes muss sich einmal neu bei Google verbinden (neue Scopes ziehen). Bisher nur code-seitig korrekt, nicht live getestet.
- **PAT-Cleanup:** manueller Schritt in Airtable-Settings durch Johannes (s. `docs/PAT_CLEANUP_S17.md`)
- **Bestehender korrupter Keychain-Eintrag** (baseID enthält PAT): Johannes muss `appuVMh3KDfKw4OoQ` einmal neu in Einstellungen eintragen

---

## Erfahrungsbericht (für S10 Learning)

**Was gut lief:**
- S16-Konsultation über Tisch war wertvoll — bestätigte alle drei Fallstricke proaktiv (Scopes, Mastermind-Schreibrechte, getrimmte Validierung)
- Build blieb die ganze Zeit grün, keine Architektur-Überraschungen
- SourceKit-Diagnostics waren verzögerter Noise (Compiler hatte keine echten Fehler)

**Was aufgepasst werden musste:**
- Bestehende Tests nutzten `"appXYZ"` als Base-ID — nach Validierungs-Einführung sofort gebrochen, schnell gefixt
- `GoogleTokenStoring`-Protokollerweiterung machte `InMemoryGoogleTokenStore` in Tests non-konform — musste synchron erweitert werden

**Was S18 wissen muss:**
- Die userinfo-Scopes sind in den Defaults — Johannes muss sich einmal neu verbinden (Re-Consent)
- `AppState.currentGoogleUser` ist bereit für alle Views die es brauchen
- `KalkulationsEngine` + `ChatStore` + `ConversationEngine` sind alle intakt
