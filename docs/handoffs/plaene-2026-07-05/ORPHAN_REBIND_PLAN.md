# Implementierungsplan — Orphan-Rebind (Stufe 1a)

*Erstellt 2026-07-05 (read-only Planungs-Agent), Torwächter-geprüft. Durabel gesichert
aus dem Session-Scratchpad. Baut den Personalausweis fertig (Rebind-Zweig + Keychain-Anker)
und faltet den Claude-`.local`-Bug ein.*

**Ausgangsbefund:** Stufe 1 (Personalausweis-Fundament) ist bereits gebaut: `ResidentIdentity`,
`ResidentIdentityStore` (inkl. `static userID(forEmail:db:)`), Migration `v24_resident_identity`,
`enrichResidentIdentity()` + Bootstrap-Hook, Nicht-Leer-Invariante, Ganzsekunden-Cold-Start-Test.
Das Schlüssel-Inventar (1b) erkennt den Claude-`.local`-Orphan, kann ihn aber nicht heilen.
**Der REBIND-Zweig fehlt bewusst — genau dieser Auftrag.** `ensureUserID` hat heute
`ensureUserID(db:)` OHNE `googleEmail` (ProfileStore.swift:73); der einzige Call-Site
(AppState.swift:313) läuft VOR der Google-Hydration → der Parameter wäre dort toter Code.

---

## 1. Ist-Zustand (Datei:Zeile)

**Reihenfolge in `AppState.init` (Sources/MykilosApp/Data/AppState.swift):**
- **Z.313** `ProfileStore.ensureUserID(db:)` — synchron, kennt die Google-Mail NICHT.
- **Z.318** `CurrentUserContext.set(userID)` — prozessweiter Anker für Keychain-Default-Inits.
- **Z.319-327** Per-User-Stores mit explizitem `userID:` (Google/Clockodo/ClickUp/Sevdesk/Airtable).
- **Z.319** `GoogleAuthService.init` hydratisiert `currentUser` SYNCHRON aus dem Keychain
  (`try? tokenStore.loadUserInfo()`, GoogleAuthService.swift:34-35) → ab hier ist die Mail da, wenn schon eingeloggt.
- **Z.381** `KeychainClaudeCredentialsStore()` — OHNE `userID:` → Default `CurrentUserContext.current`;
  der einzige Store ohne explizites userID → landet ggf. unter `.local`.
- **Z.534-542** (bootstrap): nach `refreshUserInfoIfNeeded()` läuft `enrichResidentIdentity()` und
  persistiert `googleEmail → userID` in `residentIdentity`.

**`currentGoogleUser`:** (a) synchron im `GoogleAuthService.init` aus Keychain-Cache; (b) frisch bei
`startAuthorization`; (c) via `refreshUserInfoIfNeeded`. Forwarding `AppState.currentGoogleUser` (:136).

**GRDB-Version:** aktuell **v24** (GRDBDatabase.swift:483/496). Nächste frei = v25.
**Stufe 1a braucht KEINE Migration** (Schema steht).

**Claude-Bug:** Store schreibt per `perUser("claude", userID:)`, liest per
`PerUserKeychainMigrator.loadWithMigration`. Der Migrator migriert NUR von `legacy(base)`
= `com.mykilos6.claude`, **NICHT von `com.mykilos6.claude.local`** (PerUserKeychainService.swift:96-106).
Wer Claude in einem Build verbunden hat, in dem der Store zur Schreibzeit `CurrentUserContext.current == nil`
sah, hat den Key unter `.local` — vom Migrator nie gefunden.

---

## 2. Soll-Änderungen

### Teil C — Claude-`.local`-Fix (RISIKOARM, ZUERST, eigener Commit)
- **C1** AppState.swift:381 → `KeychainClaudeCredentialsStore(userID: userID)` (konsistent zu den 5 Geschwistern).
- **C2 (der eigentliche Fix): Migration `.local` → per-User.** Option 1 (empfohlen):
  `loadWithMigration` (PerUserKeychainService.swift:96-106) um `com.mykilos6.<base>.local` als
  ZWEITE Migrationsquelle erweitern — nur wenn aktive userID ≠ `"local"` (sonst Selbst-Migration/Loop).
  **Append-only:** `.local`-Eintrag NICHT löschen, nur nachziehen (Muster wie Legacy). Repariert Claude
  UND jede künftige Base an einer Stelle. Bestehende Tests bleiben grün (rein additiver Quell-Fallback).

### Teil A — Zweiter `ensureUserID` NACH Google-Hydration (Rebind)
- **A1** `ProfileStore.ensureUserID(db:, googleEmail: String? = nil)` (additiv, Default `nil` hält alle
  Call-Sites + 8 Tests grün). Neuer Fall GANZ AM ANFANG: wenn `googleEmail` non-nil UND `.trimmed`
  nicht leer UND `ResidentIdentityStore.userID(forEmail:db:)` liefert alte UUID → diese zurückgeben +
  `userProfile` per `existing.withUserID(alteUUID)` rebinden (nur schreiben bei Abweichung).
  Nicht-Leer-Invariante hier doppelt prüfen (`email.trimmed.isEmpty == false`).
- **A2** Zweiter Aufruf in `AppState.init`: **Mail-Hydration VOR die Store-Konstruktion (Z.319) ziehen**
  (schlank `KeychainGoogleTokenStore(userID: firstID).loadUserInfo()`), Rebind rechnen, DANN alle
  Per-User-Stores EINMAL mit der ENDGÜLTIGEN UUID bauen. Kein Doppel-Bau. `CurrentUserContext.set(rebound)`
  bevor die Stores gebaut werden. **Der erste `ensureUserID` (Z.313) + `set` (Z.318) bleiben** — Boden für die Hydration.

### Teil B — Keychain-Anker-Spiegel (überlebt db.sqlite-Löschung, gehört mit A in EINEN Commit)
- **B1** Anker (`googleEmail`→`userID`) ZUSÄTZLICH im Keychain: eigener schlanker
  `KeychainIdentityAnchorStore` (Form wie `KeychainClaudeCredentialsStore`), Service `com.mykilos6.identity`,
  Account = normalisierte VOLLE Mail (nie Domain), Wert = userID. **NICHT ins `KeyIntegration`-Enum**
  (trägt kein Secret; die „genau 6"-Invariante des Inventars bräche sonst).
  Liegt in **MykilosServices** (ProfileStore darf Keychain sehen, MykilosKit nicht).
- Schreiben in `enrichResidentIdentity()` (AppState.swift:223) nach `residentIdentity.save`, non-fatal (`try?`).
- Lesen im Rebind (A1): erst DB-Anker (`ResidentIdentityStore.userID(forEmail:)`), bei Miss Keychain-Anker.
  Nicht-Leer-Invariante auch hier.

---

## 3. Risiken (Kritiker-Befunde)
- **Reihenfolge in init (break[3]):** Ändert der Rebind die userID, müssen `CurrentUserContext` + alle
  Stores + `googleAuth` auf die ALTE UUID zeigen. → Mail-Hydration vor Store-Bau ziehen, EINMAL bauen.
- **Leer-Mail-Anker (missing[2]):** leerer Key/Account = geteilter Rebind-Magnet. → `.trimmed.isEmpty == false`
  an ALLEN 3 Stellen (Rebind-Lookup, Keychain-Anker schreiben+lesen, enrich-Guard existiert). Volle Mail, nie Domain.
- **Ganze db.sqlite weg (missing[3], häufigster Fall):** reiner DB-Anker heilt Neuinstallation NICHT → Teil B.
- **Doppel-Anlage:** Rebind gibt ALTE UUID zurück + rebindet Single-Row `id="local"` (Upsert, keine neue Zeile).
- **Keychain-Migrations-Datenverlust:** `.local` wird gelesen + nachgezogen, NIE gelöscht (append-only).
- **Cold-Start-Bit-Exaktheit (missing[1]):** Ganzsekunden-Timestamps (`Date(timeIntervalSince1970: 1_800_000_000)`).

---

## 4. Cold-Start-Tests (echte Datei-DB, Ganzsekunden, volle Mail)
- **T1 — Rebind statt Verwaisung:** residentIdentity mit `johannes@mykilos.com`+`ALT-UUID-001` schreiben,
  userProfile leer → `ensureUserID(db:, googleEmail:"johannes@mykilos.com")` == `ALT-UUID-001`.
  Kontrollen: ohne Mail → frische UUID; `""`/`"   "` → frische UUID (Nicht-Leer-Invariante).
- **T2 — Keychain-Anker überlebt db.sqlite-Löschung:** FakeKeychain-Anker `mail→ALT-UUID`, frische DB ohne
  Record → Rebind fällt auf Keychain-Anker zurück == `ALT-UUID`. Volle Mail; Domain-only liefert nichts.
- **T3 — Claude `.local`→per-User erhält Verbindung:** `apiKey`+`model` unter `com.mykilos6.claude.local`
  schreiben, `KeychainClaudeCredentialsStore(keychain: fake, userID:"AKTIVE-UUID").load()` != nil →
  `.connected`; Wert danach AUCH unter `...claude.AKTIVE-UUID`, `.local` bleibt. Negativ: aktive userID
  == `"local"` → keine Selbst-Migration.

---

## 5. Reihenfolge / Scope
**Umfang klein-mittel, in einem Rutsch baubar.** Empfohlen nach Risiko: **C zuerst (separat, risikoarm)**
→ **A** (heikelste Stelle: init-Reorder) → **B** (baut auf A). **A+B logisch in EINEN Commit**
(Rebind ohne Keychain-Anker heilt den häufigsten Reset-Fall nicht). **C trennbar.** Keine GRDB-Migration nötig.

### Kritische Dateien
- `Sources/MykilosServices/Database/ProfileStore.swift` (ensureUserID rebind-fähig, Z.73)
- `Sources/MykilosApp/Data/AppState.swift` (zweiter Aufruf + Claude-userID Z.313-381; Anker-Schreiben Z.223)
- `Sources/MykilosServices/Google/PerUserKeychainService.swift` (loadWithMigration + `.local`-Quelle, Z.90-108)
- `Sources/MykilosServices/Claude/ClaudeAuthService.swift` (KeychainClaudeCredentialsStore, Z.30-64)
- `Sources/MykilosServices/Database/ResidentIdentityStore.swift` (userID(forEmail:db:) Rebind-Lookup, Z.67)
