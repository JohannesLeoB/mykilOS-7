# Handoff: Live-Wiring-Session 2 (2026-06-27, Fortsetzung)

Direkte Fortsetzung von [HANDOFF_LIVE_WIRING_1.md](HANDOFF_LIVE_WIRING_1.md) —
Schritte A/B/C aus dessen Plan sind erledigt (siehe Status-Tabelle dort).
Diese Session kam danach: erster echter Google-Login-Versuch, drei vom User
gemeldete Live-Bugs, und ein großer Ausbauwunsch für den Assistenten (als
Plan dokumentiert, nicht umgesetzt).

---

## 1. Google-Login: client_secret nachgerüstet

**Symptom live beim ersten echten Verbindungsversuch:** `httpError(400)`,
nach Fix `httpError(401)` mit dem alten OAuth-Client, dann gelöst durch einen
**neuen OAuth-Client vom Typ "Desktop"** in der Google Cloud Console (User
hat das selbst gelöst — der genaue Dreh, ob am Ende mit oder ohne
Client-Secret, wurde nicht zurückgemeldet; bei Bedarf nachfragen und hier
ergänzen).

**Code-Fix (unabhängig vom genauen Client-Typ nötig):**
`GoogleOAuthPKCEService`/`GoogleTokenRefreshService` sendeten nie ein
`client_secret` beim Token-Tausch — jetzt optional unterstützt:
- `KeychainGoogleTokenStore`: neuer `clientSecret`-Account im bestehenden
  `com.mykilos6.google`-Service.
- `GoogleAuthService.startAuthorization(clientID:clientSecret:)`.
- Settings-UI: neues SecureField "Client-Secret" neben der Client-ID.
- Nur gesendet, wenn nicht leer — reine "Installed App"-Clients ohne Secret
  bleiben unverändert funktionsfähig.

Details/Diagnose-Vorgehen: Commit `219cc41`.

---

## 2. Drei Live-Bugs nach dem ersten echten Rundgang

Der User hat nach Schritt A (echte Daten) die App tatsächlich benutzt und
drei Dinge gemeldet:

### 2a. Fenster-Drift bei Projekt-Detailseiten

**Symptom (Screenshots):** Auf jeder Projekt-Detailseite saß das
Fenster nicht mehr mittig — Sidebar-Text am linken Rand abgeschnitten
("ilOS 6" statt "mykilOS 6", "& Daten" statt "Marken & Daten" etc.), auf
der Galerie-Seite selbst aber alles normal.

**Root Cause nicht abschließend isoliert** — aber der Code-Kommentar in
`MykilOS6App.swift`/`ProjectGalleryView.swift` zeigt: **genau dieses
Problem** ("Fenster driftet aus dem Bild bei Inhaltswechsel") wurde
bereits einmal diagnostiziert und mit `.opacity`-Transition statt `.move`
+ festem Mindestrahmen "gefixt". Diese Maßnahmen sind im Code noch korrekt
vorhanden (geprüft) — es ist also entweder eine Regression durch eine
andere, seither geänderte Stelle, oder ein bisher nicht erfasster
Auslöser-Pfad.

**Umgesetzter Fix — Verteidigungslinie statt Ursachenjagd:**
Neue Datei `Sources/MykilosApp/WindowGuard.swift`:
- `WindowGuard.clampMainWindowToVisibleScreen()` — liest das Hauptfenster
  über `NSApp.windows`, vergleicht mit `NSScreen.visibleFrame`, zieht
  Position (nicht Größe über das Maximum hinaus) zurück, falls das Fenster
  ganz oder teilweise vom sichtbaren Bereich abgewandert ist.
- `View.guardWindowPosition(on:)` — ruft den Clamp ca. 260 ms nach jeder
  Änderung des übergebenen Werts auf (Animationsdauer abwarten, bis AppKit
  die neue Größe final angewendet hat).
- Eingehängt in `ContentView` (`on: module`) und `ProjectGalleryView`
  (`on: selectedProject?.id`).

**Das ist bewusst eine Untergrenze, kein Ersatz für echte Layout-Stabilität.**
Falls das Drift-Problem nach diesem Fix weiterhin sichtbar auftritt (kurz
sichtbares Springen, bevor der Guard greift), ist eine tiefere AppKit-Debug-
Session nötig: `NSWindow`-Frame-Logging bei jedem Layout-Pass, um den exakten
Trigger zu finden. Für jetzt: **bitte live verifizieren**, ob das Drift
verschwunden oder nur abgeschwächt ist.

### 2b. ProjectFavoritesWidget (Heute-Seite) — Karten nicht klickbar

**Symptom:** Die "Projekte"-Pinned-Karten im Heute-Board waren rein
dekorativ, kein Tap-Handler.

**Fix:**
- Neue Navigations-Brücke `AppState.pendingProjectSelection: Project?`
  (siehe Kommentar dort) — andere Module können "öffne Projekt X" anfordern,
  ohne `ContentView`s `module`-State oder `ProjectGalleryView`s
  `selectedProject`-State zu kennen.
- `ContentView`: `.onChange(of: appState.pendingProjectSelection)` wechselt
  `module` auf `.projects`.
- `ProjectGalleryView`: `.onChange(of: appState.pendingProjectSelection)`
  öffnet das Projekt und räumt die Brücke sofort wieder auf (`nil`).
- `MiniProjectCard` ist jetzt ein echter `Button`, `ProjectFavoritesWidget`
  setzt beim Tap `appState.pendingProjectSelection = project`.

Dieses Muster (Brücke über `AppState` statt direkter State-Kopplung) ist
wiederverwendbar für jede künftige "von Modul A nach Modul B mit Kontext
springen"-Anforderung — z. B. falls der Assistent (Aufgabe aus dem
Ausbauplan) später "öffne Projekt X" als eigene Aktion anbieten soll.

### 2c. Drive-Anbindung nur für das offene Projekt live, nicht für alle

**Symptom:** `DriveOfferWatcher` pollte bisher ausschließlich, solange eine
einzelne `ProjectDetailView` offen war — alle anderen 30 Projekte hatten
keine Live-Quelle für `offerDetected`, solange niemand draufschaute.

**Fix:**
- `AppState.pollAllActiveProjectsForOffers(into:) async -> Int` — zentrale
  Methode, pollt alle `registry.activeProjects()` mit gesetztem
  `driveFolderID` auf einmal, emittiert Signale in den übergebenen
  `StudioContext`, gibt die Trefferzahl zurück.
- `HomeForcePollButton` (Heute-Seite) nutzt jetzt diese zentrale Methode
  statt einer eigenen Kopie der Schleife (Code-Dedupe nebenbei).
- **Neu:** `TodayView` hat einen Hintergrund-`.task`-Loop, der alle 5 Minuten
  automatisch `pollAllActiveProjectsForOffers` aufruft, solange die
  Heute-Seite offen ist — bewusst seltener als der Pro-Projekt-Loop (60 s),
  weil hier 31 Ordner pro Tick statt 1 abgefragt werden.

**Nicht geändert:** Der bestehende Pro-Projekt-Loop in `ProjectDetailView`
(60 s, nur für das offene Projekt) bleibt zusätzlich bestehen — beide Pfade
nutzen denselben `appState.offerWatcher(for:)`-Cache, also dieselbe
Baseline/„seen"-Menge pro Projekt, kein doppeltes Melden.

---

## 3. Großer Ausbauwunsch: Assistent (nur Plan, nicht umgesetzt)

User-Wunsch: Assistent soll Mail/Kalender/Drive komplett durchsuchen,
Projektordner+Unterordner crawlen, Mail-Entwürfe schreiben/verwerfen,
echte Kalender-Termine anlegen, Notizen verwalten, Clockodo-Stunden
vorbereiten, Kundenmails zusammenfassen, Kontakte/Bilder/Angebote suchen.

Vollständig zerlegt in
[ASSISTANT_CAPABILITIES_PLAN.md](../ASSISTANT_CAPABILITIES_PLAN.md):
7 Lese-Punkte (klein bis mittel, kein neues Schreibrisiko, bauen auf
bestehenden Clients auf) + 5 Schreib-Punkte (alle zwingend über
Action-Card → Bestätigung → Audit, zwei davon blockiert auf eine bewusste
Google-Scope-Erweiterung, die der User aktiv freigeben muss).

**Nichts davon ist umgesetzt.** Empfohlene Reihenfolge steht im Plan-Dokument
(Drive-Crawling zuerst als Grundlage, dann die übrigen Lese-Punkte, dann
Notizen als kleinster Schreib-Baustein, dann die Scope-abhängigen Punkte).

---

## 4. Identity/Login-Plan (nur Plan, teilweise umgesetzt)

[IDENTITY_LOGIN_PLAN.md](../IDENTITY_LOGIN_PLAN.md) — Teil 1 (Zertifikat
gegen die 8 Keychain-Prompts) war als Sofort-Maßnahme empfohlen, **Status
beim User nicht zurückgemeldet** — bei Bedarf in der nächsten Session
nachfragen, ob das Zertifikat angelegt wurde und ob es geholfen hat. Teil 2
(ein einziger Login für alles) ist bewusst eine offene Entscheidung,
abhängig vom Ergebnis aus Teil 1.

---

## Build/Test-Status dieser Session

`swift build` clean nach jeder Änderung. `swift test` zuletzt bei
169/169 grün (vor den allerletzten drei Fixes — **bitte vor dem nächsten
Commit nochmal laufen lassen**, da der Bash-Classifier während dieser
Session kurz unterbrochen war und der letzte Testlauf nach den
Window-Guard-/Navigations-/Drive-Routing-Änderungen noch ausstand).

---

## Empfohlener Startprompt für die nächste Session

> "Live-Wiring-Session 3: Lies HANDOFF_LIVE_WIRING_2.md. Zuerst swift test
> verifizieren (letzter Stand war vor den allerletzten drei Fixes). Dann
> live im laufenden Bundle prüfen: (1) ist der Fenster-Drift bei
> Projekt-Detailseiten durch den WindowGuard behoben oder nur abgeschwächt?
> (2) sind die Projekt-Favoriten-Karten im Heute-Board jetzt klickbar und
> öffnen das richtige Projekt? (3) zeigt 'Jetzt prüfen' im Heute-Board
> weiterhin korrekt Trefferzahlen über alle 31 Projekte? Danach: Schritt D
> aus HANDOFF_LIVE_WIRING_1.md (neue Tabs) oder Assistent-Ausbau Punkt A3
> (Drive-Crawling) je nach Priorität."

## Status-Tabelle (für spätere Sessions auf einen Blick)

| Punkt | Status |
|---|---|
| Google-Login client_secret-Fix | ✅ Code erledigt, `219cc41` — Live-Ergebnis vom User nicht final rückgemeldet |
| Fenster-Drift-Guard | 🚧 Verteidigungslinie eingebaut, **Live-Verifikation ausstehend** |
| Projekt-Favoriten klickbar | ✅ Code erledigt — Live-Verifikation ausstehend |
| Drive-Routing über alle Projekte | ✅ Code erledigt — Live-Verifikation ausstehend |
| Assistent-Ausbau | ⬜ nur geplant, siehe ASSISTANT_CAPABILITIES_PLAN.md |
| Identity/Login Teil 1 (Zertifikat) | ⬜ Status vom User nicht rückgemeldet |
