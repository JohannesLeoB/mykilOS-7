# mykilOS 6 Codex Workflow

## Zweck

Dieser Workflow definiert, wie Codex-Sessions im mykilOS-6-Repository
arbeiten sollen, damit Architektur-, Persistenz- und Qualitätsregeln aus
`CLAUDE.md` über Sessions hinweg konsistent bleiben.

## Vor jeder Session

1. `CLAUDE.md` lesen — Abschnitt "Wo wir stehen" zeigt den aktuellen Akt/Schritt.
2. Den zugehörigen `docs/handoffs/HANDOFF_AKT{n}_S{m}.md` lesen — dort stehen
   bekannte offene Punkte, die der letzte Schritt bewusst nicht gelöst hat.
3. `swift test` laufen lassen, bevor irgendetwas geändert wird — wenn das
   nicht grün ist, ist das der erste Auftrag, nicht das, was als Nächstes auf
   der Roadmap steht.

## Verbindliche Produktregeln (aus `CLAUDE.md` → "Absolute Regeln")

- **Persistenz:** Jeder Schreibvorgang `throws`. Niemals `try?` ohne
  begründenden Kommentar. `SaveState` ist in der UI sichtbar. Jedes neue
  persistierbare Feature braucht einen Cold-Start-Test (schreiben → neue
  Instanz → lesen → identisch).
- **Token-Disziplin:** Keine `.font(.system(...))`, kein `Color(red:...)`,
  kein lokales `Color(hex:)` — alles aus `MykilosDesign/Tokens.swift`.
- **Secrets:** Tokens/API-Keys/PATs nur im Keychain (`MykilosServices/Google/
  KeychainStore.swift` ist der generische Wrapper dafür) — nie in Code,
  Dateien, Repo, Logs.
- **Widgets:** reden nie direkt miteinander, nur über
  `StudioContext.emit()`. Signale sind Vorschläge, nie automatische Schreib-
  aktionen. Jedes Widget implementiert alle sechs Renderstates.
- **Architektur:** `MykilosKit` importiert nichts von uns (kein SwiftUI, kein
  GRDB). `MykilosServices` darf GRDB/Security/Network, aber kein SwiftUI.
  `MykilosWidgets` darf SwiftUI, aber kein GRDB direkt. Schreibvorgänge kommen
  nie aus Views, nur aus Stores/Services.

## Session-Ablauf

1. **Scope klein halten** — eine Session = ein in sich abgeschlossener
   Akt-Schritt, nicht ein ganzer Akt. Wenn eine Anforderung mehrere
   Akt-Schritte berührt, zuerst aufteilen und nur den ersten umsetzen.
2. **Bauen.** `swift build` muss am Ende clean sein — keine neuen Warnungen
   ignorieren, die nicht schon vorher dokumentiert waren.
3. **Testen.** `swift test` muss grün sein. Neue persistente Features
   brauchen einen neuen Cold-Start-Test im passenden Test-Target
   (`MykilosKitTests` für reine `MykilosKit`-Logik, `MykilosServicesTests`
   für GRDB/Keychain/Netzwerk-Code — letzteres mit In-Memory-/Test-Doubles
   statt echtem Keychain/Netzwerk, siehe `GoogleOAuthTests.swift` als Muster).
4. **Laufen lassen.** `./script/build_and_run.sh` baut einen echten
   `.app`-Bundle in `dist/` und startet ihn — das ist die "Run"-Action in
   `.codex/environments/environment.toml`. Für Flows, die echte Nutzer-
   interaktion brauchen (z. B. den Google-OAuth-Browser-Redirect), als
   manuellen Schritt im Handoff dokumentieren statt zu erzwingen.
5. **Handoff schreiben.** `docs/handoffs/HANDOFF_AKT{n}_S{m}.md` —
   mindestens: was entstanden ist, welche Tests neu sind, was bewusst nicht
   getestet werden konnte, was der nächste sinnvolle Schritt ist.
6. **`CLAUDE.md` aktualisieren** — Status-Tabelle, ggf. neue Einträge unter
   "Nächste Schritte" oder "Bekannte offene Punkte".

## Nicht erlaubt

- Mehrere Akt-Schritte in einer Session bündeln, ohne dass der Nutzer das
  explizit so verlangt hat.
- Stille `try?`-Fehlerbehandlung bei neuen Schreibvorgängen.
- Secrets/Tokens in Code, Tests, Logs oder Commit-Messages.
- Architektur-Schichtgrenzen umgehen (z. B. GRDB-Import in `MykilosKit` oder
  `MykilosWidgets`), auch nicht "nur kurz zum Testen".
- Tests, die echtes Keychain oder echtes Netzwerk im automatisierten Lauf
  brauchen — dafür immer ein injizierbares Protokoll + Test-Double bauen
  (siehe `GoogleTokenStoring`/`InMemoryGoogleTokenStore`).

## Ziel

Eine gute Codex-Session in mykilOS 6 hinterlässt einen grünen Build, grüne
Tests, einen lesbaren Handoff und eine `CLAUDE.md`, die den nächsten
Schritt korrekt beschreibt — nicht eine möglichst große Diff.
