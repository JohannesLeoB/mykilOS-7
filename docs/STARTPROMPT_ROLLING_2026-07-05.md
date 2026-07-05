# Startprompt — Autonom-rollende Feature-Session (ab 2026-07-05)

Paste als erste Nachricht in eine **frische** Claude-Code-Session im kanonischen mykilOS-Ordner.
So läuft „arbeite autonom rollend bis die Ideen ausgehen" bei vollem Kontext-Runway statt müde.

---

```
Du baust mykilOS weiter — autonom rollend durch den fertigen Bauplan, bis die Ideen ausgehen.

ZUERST lesen (in dieser Reihenfolge):
1. HYPERBUILD.md                        — der Brühwürfel (ganze App auf einer Seite)
2. docs/BAUPLAN_FEATURES_2026-07-05.md  — DER Plan: Tracks A–J, die 4 Fundamente, Airtable-Routen, Guardrails
3. CLAUDE.md                            — Eiserne Regeln

Dann Pflicht-Gate-Checks: pwd (kanonischer Ordner) · git status · git branch ·
swift build && swift test (Zahl notieren).

Stand bei Übergabe (2026-07-05, verifiziere selbst):
- Branch feat/kamera-barcode-widget · 963 Tests grün · DMG 10.0.0-alpha16 in dist/.
- FERTIG: Kamera/Barcode-Widget (Track A + G1) · Taschenrechner Braun (H1). Mehrere Commits, Docs uncommitted.
- OFFEN (Empfohlene Reihenfolge steht im Bauplan): Ingest-Fundament (G2 Barcode→Checkout, G5 Visitenkarte,
  G6 Kontaktselbstheilung) · Drag&Drop-Wirbelsäule (B) · Mini-Mode V1.1 (C) · View-Konsolidierung (D) ·
  Fun-Widgets H2–H5 · Colour Picker (I) · User-/Settings-Ebenen (J) · Scaling + UI-Polish (E).

ARBEITSWEISE (autonom rollend):
- Ein Track/Increment nach dem anderen. Je: strenger Plan → Code → swift build+test-Gate → Commit.
  Push/PR NIE ohne Johannes' ausdrückliches GO.
- KONSOLIDIEREN statt duplizieren: die 4 Fundamente (Pick/Checkout · geteilte Collection-View ·
  Kamera-Erfassen · Alert-Fläche) EINMAL bauen, Features darauf — das räumt die „doppelt/ähnelt"-Backlog-Zeilen ab.
- Guardrails: nur Tokens (MykColor/MykSpace/Font.myk) · alle 6 Renderstates · Cold-Start-Test bei Persistenz ·
  Airtable NIE löschen (nur Status=Archiv/Old flaggen) · Kontakt-/Mail-/Memo-Isolation · Interior-Build-Charter.
- UI-KONSISTENZ-GEBOT: jede UI-Änderung auf ALLEN Ansichten auf Konsistenz + einheitliche Abstände prüfen
  (gleiche MykSpace-Stufen/Radien/Fonts überall). Gegen Screenshots.
- DMG an Checkpoints (script/create_dmg.sh, Version bumpen), schön präsentieren.
- SELBST-DROSSELUNG: Kontextfenster + Nutzungslimit im Auge — an Checkpoints committen + DMG, nicht müde
  weitergaloppieren; lieber sauber übergeben als degradiert bauen.
- Feedback-Loop: sagt Johannes „schau in deinen/feedback/dev ordner" → nur NOCH-NICHT-verbuchte
  Screenshots aus ~/Desktop/mykilOS-Feedback/ lesen, dann Bild→Kommentar→Bild→Kommentar.

LIVE-GATES (nur Johannes): Kamera-Scan am Gerät · Google-Contacts-Write-Scope (Re-Consent) für G5.

Leg los: erster Track nach der Bauplan-Reihenfolge — ein Fundament sauber, dann rollen.
```
