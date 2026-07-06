# 🏁 Session-Abschluss 2026-07-06 — Multi-User fertig, Vision kartiert

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/multi-user-login — GEPUSHT nach origin (mit origin synchron)
Build:  ✅ swift build grün + warnungsfrei (lokal)
Tests:  ✅ 1085 grün (139 Suites) (lokal)
CI:     ✅ GRÜN (build-and-test 2m10s) — Lint-Baseline geglättet, Build + 1085 Tests durch
DMG:    dist/mykilOS-11.1.0-alpha7.dmg (Profil + Start-Ansicht + UI-Fixes; QR→Link kam danach)
main:   NICHT gemergt (heilig) — CI-technisch jetzt möglich, bleibt aber Johannes' bewusste Entscheidung

## ✅ CI ist GRÜN (2026-07-06 nachmittags behoben)
Der frühere Lint-Baseline-Drift (deutsche Erklär-Kommentare → neue `line_length`) ist geglättet:
Baseline neu erzeugt + auf CI-Runner-Pfad re-pinnt (Commit `606fde7`). Ein echter Rest-Verstoß
(QR-Button-Syntax) wurde **sauber gefixt, nicht gebaselined**. GitHub-CI `build-and-test` grün in
2m10s. Merge nach `main` ist damit CI-technisch offen — bleibt aber deine bewusste Entscheidung.
```

## Was diese Session gebaut hat (alles committet + getestet)

**Multi-User-Identität — komplett + adversarial reviewt:**
- Abmelde-Button, `signOutEverywhere`, Gast-Namespace, Relaunch
- Store-Isolation: Chat, Notizen, Aufgaben, Clockodo-Zeiten, **ChatMemoryStore** (privat, nie kreuzlesbar)
- **WorkBasketStore bewusst GETEILT** (projekt-, nicht personenbezogen) — dokumentiert
- **Login-Auflösung** geschlossen (`clearSignedOut` verdrahtet) — war toter Code
- Cold-Start-Isolationstest mit **echter Datei-DB + echten Neustarts** (Bauplan §7.3)
- **8-Winkel-Review** → **echter Cross-User-Leak in `completeLoginAndRefresh` gefunden + gefixt**
  (band Mail eines neuen Bewohners an alte userID) + 1 eigener Fehl-Fix zurückgerollt (clientID/Secret
  sind team-geteilt, nicht persönlich). Details: `REVIEW_MULTI_USER_2026-07-06.md`.

**Einstellungen vertieft:**
- Nutzerprofil: Geburtsdatum, Telefon, Abteilung, Über-mich (Migration v28, Cold-Start-Tests)
- Start-Ansicht wählbar (Darstellung & Fenster)
- 3 UI-Feedback-Fixes (visuell verifiziert): Favoriten-Klick (echter Hit-Test-Bug), Toggle-Ausrichtung,
  Sidebar-Flucht
- Swift-6-Blocker `BackupService.fm` behoben (Build warnungsfrei)

## Kartierte Architektur — 4 Startpläne für frische Sessions

| Plan | Inhalt |
|---|---|
| `docs/PRINZIP_SCHALTSCHRANK.md` | **Leitprinzip:** Verknüpfungen als umsteckbare Klemmen (FieldRoute-Registry), nie hart verdrahtet |
| `docs/VISION_LOGIN_UND_DATENFLUSS.md` | Google-SSO-Eingang, 6 Dienste (OAuth vs. Key), Sevdesk-Budget-Routen |
| `docs/handoffs/CLICKUP_DATENINTEGRATION_PLAN.md` | Aufgaben/Fälligkeiten/Meilensteine/Status + **13 Custom Fields ausgelesen + Mapping** |
| `docs/handoffs/ORDNER_SCHEMA_EDITOR_PLAN.md` | Admin-Ordnerschema (Fundament ~70% da) |

## ⏳ Wartet auf Johannes (autonom nicht machbar)

1. **Live-Abnahme** alpha7 (Favoriten klicken, Profil, Sidebar) + zwei echte Google-Accounts (Multi-User).
2. **Design-Entscheidung:** Was ist „Projekt-Status" genau? (ClickUp-Phase / Lebenszyklus-Stepper /
   Ableitung aus Tasks) — blockt die ClickUp-Status-Verdrahtung.
3. **ClickUp-OAuth-App registrieren** (client_id/secret) für den Login-Fenster-Umbau.
4. **Datenschutz-Tab-Wording** (Freigabe-Texte, „KI-aus"-Schalter, Daten-Export) — keine eigenmächtigen Rechtstexte.
5. **GO-Gates:** echter Drive-Write (Ordner-Schema, raus aus Sandbox); ClickUp-Schreiben bleibt Testspace/Ghost.
6. **Lint-Baseline** neu schreiben (war Permission-blockiert; ~27 neue line_length durch deutsche Kommentare).

## Empfohlener Start der nächsten Session
`main` NICHT gemergt (bewusst — CI-grün + GO nötig). Der gepushte Branch ist die Backup-/Weiterbau-Basis.
Kleinster nächster Bau-Schritt mit größtem Wert: **ClickUp `FieldRoute`-Registry** (Schaltschrank,
read-only, voll testbar) ODER **Ordner-Schema editierbar machen** (Stufe 1, kein Drive-Write).

---

## Nachtrag 2026-07-06 (autonome Folge-Session): ClickUp-Custom-Fields als Schaltschrank-Route (Stufe 1, read-only)

**Gebaut** (Schritt 1+2 aus `CLICKUP_DATENINTEGRATION_PLAN.md`, rein Lese-/Modell-Arbeit — kein Schreiben,
kein Netzwerk, kein echtes Secret):

1. **`ClickUpProjektMeta`-Struct** (`Sources/MykilosKit/Domain/ClickUpProjektMeta.swift`, Foundation-only,
   Codable/Sendable): typisiertes Modell der 13 Projekt-Custom-Fields (Budget `Double?`, 3× Datum `Date?`,
   Drive-Ordner/Kunde/Kunde-Token/Projekttyp/Ort/Lead/Risiko/Slack `String?`, Lieferanten `[String]?`).
   Alle Slots optional (fehlt ein Feld → nil, nie brechend). Dazu `.empty`/`isEmpty`.
2. **Schaltschrank-Registry** (gleiche Datei): `ClickUpMetaSlot` (13 stabile Klemmen-IDs mit `kind` +
   typisierten Key-Paths als DATEN am Slot), `ClickUpFieldRoute { routeID, quelle, ziel, aktiv }` und
   `ClickUpFieldRouteRegistry` mit `.default` (13 Routen, ClickUp-Feldname → Slot). Umlegen = Route-Zeile
   ändern, nicht Parser. Registry ist Codable (persistierbar/perspektivisch editierbar).
3. **Adapter-Auswertung** (`Sources/MykilosServices/ClickUp/ClickUpProjektMetaMapper.swift`, neue Datei):
   `ClickUpMetaFieldValue` (tolerant dekodierter Rohwert: Zahl/Text/Liste/none via do/catch-Type-Probing,
   inkl. Label-Objekt-Arrays), `ClickUpProjektMetaMapper.parse(from:routes:)` (eigener minimaler
   Decodable-Pfad über `custom_fields` der ersten befüllten Task) und `.map(fields:routes:)` (läuft die
   Felder durch die Route-Tabelle statt 13 harter if-Zweige). `ClickUpClient.swift` blieb dabei bewusst
   schlank (der `project_phase`-Int-Pfad ist unverändert — Regressionstest deckt das ab).

**Tests:** `Tests/MykilosServicesTests/ClickUpProjektMetaTests.swift` — 18 neue Tests (voller 13-Feld-Parse
aus Fake-`custom_fields`, fehlende/null-Felder → nil, leere Task/Liste → `.empty`, kaputtes JSON → throw,
Mapper direkt mit Fake-Feldern, Registry-Lookup, stillgelegte Route übersprungen, **Route umlegen leitet
Quelle auf anderes Ziel**, Registry-Codable-Roundtrip, project_phase-Regression). Kein echtes ClickUp/
Netzwerk/Keychain.

```
Build:  ✅ swift build grün
Tests:  ✅ 1103 grün (140 Suites) — 1085 Baseline + 18 neu
Lint:   ✅ neue Dateien 0 Verstöße (swiftlint --strict); Projekt-Lauf mit (pfad-korrigierter) Baseline
        sauber → Baseline musste NICHT neu geschrieben werden (Zeilen-Shift in ClickUpClient.swift von
        der Baseline toleriert).
CI:     <wird nach Push mit gh run watch geprüft>
```

**⚠️ Offen / Johannes-Entscheidung:** Die Route-`quelle`-Namen im `.default` nutzen die deutschen LABELS
aus dem Plan („Budget (€)", „Nächstes Nachfassen" …). Der reale `custom_fields[].name` der ClickUp-API
kann davon abweichen (Slug vs. Label) — genau dafür ist der Schaltschrank da: stimmt ein Name live nicht,
wird EINE Route-Zeile angepasst, kein Parser-Umbau. Die exakten Live-Slugs bestätigt Johannes (bzw. eine
Session mit echtem ClickUp-Read). **Nicht Teil dieses Auftrags** (spätere Schritte): Spiegeln in
UI/Widgets/`Project`-Felder, Meilenstein-Timeline, Status-Ableitung, Alert-Pfad, Caching/Polling.
