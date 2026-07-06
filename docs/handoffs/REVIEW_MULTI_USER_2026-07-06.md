# Multi-Agenten-Review — Multi-User-Branch (2026-07-06, Nacht-Konsolidierung)

```
Branch: feat/multi-user-login
Basis:  git diff origin/main...HEAD (28 Dateien, ~1263 Zeilen)
Review: 8 Finder-Winkel (Line-by-line, Removed-Behavior, Cross-File, Reuse,
        Simplification, Efficiency, Altitude, Conventions) + Deep-Dive-Verifikation
Stand:  Build grün, 1083/1083 Tests grün nach den Fixes
```

## ✅ Behoben in dieser Konsolidierung (Commit db02792)

### 1. 🔴 ECHTER BUG — Cross-User-Identitäts-Leck (3× unabhängig bestätigt)
`AppState.completeLoginAndRefresh()` rief immer `enrichResidentIdentity()` auf, die
`CurrentUserContext.current` liest. Dieser Prozess-Singleton wird nur in `AppState.init`
gesetzt und trägt nach einem Abmelden weiter die ALTE, abgemeldete userID. Bei einem
Bewohner-Wechsel hätte der Live-Login des nächsten Bewohners dessen Mail an die alte
stabile userID gebunden → beim nächsten Neustart bekäme er die privaten Daten des
Vorgängers. **Fix:** bei Bewohner-Wechsel nur Mail persistieren + Marker aufheben +
Neustart, KEINE Live-Anreicherung; die Auflösung passiert sauber im nächsten Boot.

### 2. Eigener Fehl-Fix zurückgerollt — clientID/clientSecret bei disconnect()
Ein früherer Fix dieser Session ("Datenleck-Falle #6") ließ `clear()` auch
`clientID`/`clientSecret` löschen. Review zeigte: das sind team-weite OAuth-App-
Zugangsdaten (Desktop-App-Registrierung), keine persönlichen Secrets — ein Rückkehrer
müsste sie sonst jedes Mal neu eintippen. Zurückgerollt.

### 3. Doku-Lücke (CLAUDE.md-Regel) — Abmelden nicht im Benutzerhandbuch
`docs/BENUTZERHANDBUCH.md` Abschnitt „Identität & Private Area" um die Abmelde-Funktion
ergänzt (Regel: „Jede neue oder geänderte Funktion wird sofort dokumentiert").

## 📋 Bewusst VERTAGT (real, aber kein aktiver Bug — braucht Sichtprüfung/Migration, kein Nacht-Blind-Fix)

### A. ChatMemoryStore-Präfix-Trick → sollte echte userID-Spalte sein (KONVERGENT: Simplification + Altitude + Reuse)
Der stärkste Cleanup-Fund, von 3 Winkeln unabhängig. `ChatMemoryStore` isoliert per
Storage-Key-Präfix (`"<userID>::<scopeKey>"`) statt per additiver `userID`-Spalte wie
alle vier anderen Stores (v25/v26/v27). Funktioniert + getestet, aber: erfordert einen
Sonder-Backfill-SQL-Block (`LIKE '%::%'`), einen fragilen impliziten Vertrag (`scopeKey`
darf nie `::` enthalten) und bricht das sonst einheitliche Muster. **Richtig wäre:**
Migration v28 mit nullable `userID`-Spalte + `.filter(Column("userID") == uid)`, dann
fällt der ganze Storage-Key-Übersetzungs-Code weg und `chatMemorySummaries` wird ein
sechster Eintrag in `MultiUserBackfill.isolatedTables`. **Warum vertagt:** Migration
mitten in der Nacht ohne Live-Prüfung ist genau das Risiko, das wir vermeiden. Sauberer
Einzel-Strang für die nächste Session.

### B. MultiUserBackfill wächst mit Sonderfällen (Altitude)
Generische Tabellen-Liste + `activeTimer`-Sonderfall + jetzt `chatMemorySummaries`-
Sonderfall. Jeder neue Store, der den Präfix-Trick kopiert, erzeugt einen weiteren
Sonderblock. Löst sich großteils mit Fund A auf (echte Spalte → generischer Eintrag).

### C. "local"/"shared"-Sentinel-Duplikation (Reuse, Simplification)
`TimerStore` nutzt `"local"` als Fallback für fehlende userID, `ChatMemoryStore` `"shared"`
— zwei Namen für denselben Zweck, plus die `trimmed.isEmpty ? "local"`-Regel an ~3
Stellen dupliziert. Zentraler Sentinel in `CurrentUserContext` wäre sauberer.

### D. 5 Stores duplizieren userID-Injection (Reuse)
`ChatStore`/`AssistantNotesStore`/`AssistantTasksStore`/`TimerStore`/`ChatMemoryStore`
wiederholen `init(db:userID:)` + Filter nahezu wörtlich. Ein `UserScopedStore`-Protokoll
würde die 5 Kopien auf eine Implementierung sammeln. Größerer Refactor, eigener Strang.

### E. MultiUserBackfill läuft bei jedem Boot (Efficiency)
Ungeschützt durch einen „bereits gelaufen"-Marker — nach dem ersten Lauf sind garantiert
0 Zeilen betroffen, aber es laufen trotzdem 7 `UPDATE ... WHERE userID IS NULL`-Scans pro
Boot des Primary. Billiger: Keychain-Flag `backfillDone` neben `devicePrimaryAccount`.
Kleiner, sicherer Fix — Kandidat für die nächste Session (braucht aber einen Test).

### F. AppState.init — lange order-abhängige Sequenz (Simplification)
9 Schritte mit „muss NACH X stehen"-Kommentaren statt struktureller Absicherung. Ein
extrahiertes `resolveActiveUserID(database:)` würde die Reihenfolge kapseln.

## 🟡 Latente Konsistenz-Smells (dokumentiert, tritt in Produktion nicht auf)
- **TimerStore:** Drafts mit rohem `userID`, ActiveTimer mit normalisiertem `effectiveUserID`
  — divergiert nur bei `userID == nil`, was im Produktionspfad nie vorkommt (AppState
  übergibt immer explizit die aufgelöste ID; Deep-Dive bestätigt).
- **AppRelaunch:** `sleep 1; open -n` — theoretisches Race, wenn der alte Prozess >1s zum
  Beenden braucht. Bestehender Mechanismus, nicht neu in diesem Branch.
- **clearSignedOut schreibt ""** statt zu löschen (Protokoll kennt kein delete) — funktional
  korrekt (`isSignedOut` prüft nicht-leer), aber impliziter Vertrag.

## ✅ Geprüft und ENTWARNT (Deep-Dive widerlegte Erst-Verdacht)
- **Store-Konstruktions-Reihenfolge:** alle 5 Stores werden in `AppState.init` NACH
  `CurrentUserContext.set(finalUserID)` mit EXPLIZITEM `userID` gebaut — kein Default-Risiko.
- **SQL-Injection in MultiUserBackfill:** `isolatedTables` ist hartcodierte Compile-Time-
  Whitelist, Nutzdaten laufen über gebundene Parameter. Sicher.
- **Race ensureDevicePrimary/loadWithMigration:** beides synchron in `@MainActor init`,
  strikt sequenziell. Kein Race.
- **loadWithMigration-Riegel:** greift korrekt für Zweit-Bewohner; „kein Primary verankert"
  ist dokumentierter Erstkonfigurations-Zustand, kein Leck.

## Empfehlung für die nächste Session
Reihenfolge nach Wert/Risiko: **E** (Backfill-Marker, klein+sicher) → **A**+**B**
(ChatMemoryStore echte Spalte, löst gleich zwei Funde, braucht Live-Prüfung nach Migration)
→ **C**/**D**/**F** (Refactors, wenn Kapazität). Alles davon ist Qualität, kein Bug —
die App ist nach dem Cross-User-Leak-Fix funktional korrekt und isoliert.
