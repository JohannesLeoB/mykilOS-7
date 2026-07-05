# Bauplan — Konsolidierte Settings-Ebene (macOS-System-Settings-Stil, Stufe 2)

*2026-07-05, Ultracode-Planungs-Workflow (7 Agenten: 3 Kartieren → 3 Design-Judge-Panel →
1 Synthese). Read-only erstellt. Gegencheck durch Johannes ausstehend, bevor gebaut wird.*

**Basis:** `reuse-minimal` (bester Etappenzuschnitt + Scope-Disziplin), eingeschmolzen: Sticky-Header-
Lösung (aus `macos-treue`), privat/geteilt-Bänder als Rail-Reihenfolge (aus `hierarchie`). **Kein
Neubau — Konsolidierung:** fast alles wird wiederverwendet, nur Rename + 1 Header + 2 Design-Bausteine.

## Kategorie-Struktur (7, in privat/geteilt-Bändern) + Personalausweis-Header außerhalb der Liste
| Rail | Kategorie | Enum-Case | Band |
|---|---|---|---|
| *(Header, sticky im Content-Pane)* | **Personalausweis** | `.personalausweis` (NICHT im ForEach) | oben |
| 1 | **Darstellung** | `.darstellung` | Person |
| 2 | **Privat** (Orange bleibt) | `.privat` | Person |
| 3 | **Schlüssel-Inventar** | `.schluesselInventar` | Person |
| 4 | **Integrationen** (Rename v. „Verbindungen") | `.verbindungen` | Geteilt |
| 5 | **Datenschutz** | `.datenschutz` | System |
| 6 | **System** | `.system` | System |

**Navigation:** bestehender externalCategory-Mechanismus bleibt komplett. Delta: Personalausweis als
**sticky Header im Content-Pane** (weil im Live-Fall die Rail in der App-Sidebar lebt, nicht in
SettingsView). `.personalausweis` aus BEIDEN ForEachs ausgeschlossen via gemeinsamer `railCases`-Konstante.

## Wiederverwenden vs. neu
Fast alles 1:1: `darstellungSection` · `privateAreaSection` (Orange) · `KeychainInventoryView()` ·
`integrationStatusSection` + 5 Dienst-Sektionen · `miniModeSection` · `diagnoseSection` +
`SchaltzentrumView()` · `identitySection` + `mailSignaturSection` (in Personalausweis-Detail).
**Neu (in MykilosDesign, Token-Zwang):** `MykSettingsRow` (Icon·Titel·Untertitel·trailing·Chevron),
`MykSettingsGroup` (settingsCard-Hülle + Rows + Divider), optional `MykIdentityHeader`.

## Etappen (kleinste zuerst)
1. **Etappe 1 — Enum-Rename + Reihenfolge + `railCases` (KLEIN).** „Verbindungen"→„Integrationen",
   privat/geteilt-Reihenfolge, beide ForEachs auf `railCases`. Kein neuer View. Sofort abnehmbar, null Risiko.
2. **Etappe 2 — Personalausweis-Header + Detail-Case (MITTEL).** Sticky-Header im Content-Pane,
   `identitySection`+`mailSignaturSection` umhängen, `.profil` entfernen. Header speist aus DERSELBEN
   Google-Quelle wie `identitySection` (KEIN `ResidentIdentity`-Merge in dieser Etappe!).
3. **Etappe 3 — `MykSettingsRow`/`MykSettingsGroup` + Integrationen angleichen (GROSS).** Nicht alles
   auf einmal — erst Bausteine, dann schrittweise angleichen, gegen Screenshots prüfen (Layout-Drift-Risiko).

## ⭐ NACHTRAG (Johannes-Feedback 2026-07-05, NICHT im Workflow enthalten): CI-Akzent-Farb-Picker
Der Workflow hat den CI-Akzent-Wähler ins Backlog vertagt — **aber Johannes hat ihn explizit angefragt:**
„Rainbow-Mode (grüne Ansicht) → voller Farb-Picker für die globale Highlight-/Akzentfarbe." Gehört in
**Darstellung**. Vorschlag: eigene kleine Etappe (Etappe 1b oder in Etappe 2), voller `ColorPicker` →
globales `MykColor.brand`/Highlight-Token (persistiert, App-weit). Scope: klein–mittel. Muss in den Plan.

## Tests
- Etappe 1: Unit-Test `railCases` ohne `.personalausweis` + alle 6 sichtbaren Cases; Titel „Integrationen".
- Etappe 2: keine neue Persistenz (reine UI-Umhängung); falls `.personalausweis` als AppStorage-Default
  → Cold-Start gegen alten `.profil`-Rohwert (decode-Fallback `?? .darstellung`).
- Etappe 3: keine Logik-Tests; Screenshot-Abnahme durch Johannes (Build-grün ≠ Layout-korrekt).
- Nach jeder Etappe: `swift build && swift test` + `swiftlint --strict` grün.

## Eiserne-Regel-Check
✅ Token-Disziplin (neue Bausteine in MykilosDesign) · ✅ Private Area getrennt (Orange, NICHT mit
Datenschutz gebündelt) · ✅ Per-User-Isolation (Header liest nur eigene Google-Identität) · ✅ kein
Team-/Zuweisungs-UI · ✅ keine neue Daten-Weiche (kein Datenstrom-Handbuch-Eintrag) · ✅ Benutzerhandbuch
bei Feature-Commit aktualisieren · ✅ Branch, nie main.

## Offene Entscheidungen für Johannes
1. **Reihenfolge:** privat-zuerst (Empfehlung) vs. Apple-nah geteilt-zuerst.
2. **Header-Redundanz:** Sidebar-Avatar-Toggle UND Content-Header im Live-Fall — okay oder stört?
3. **„Gemeinsame Räume":** jetzt gar nicht (Empfehlung) vs. leere read-only Übersicht.
4. **`ResidentIdentity`↔`UserProfile`-Merge:** separater GRDB-Schritt jetzt einplanen oder später?
5. **(Nachtrag) CI-Akzent-Picker:** eigene Etappe 1b, oder mit Etappe 2 bündeln?

## Grundierte Referenzen
`Sources/MykilosApp/Settings/SettingsView.swift` (Enum :8, categoryRail :128, categoryContent :159,
Section-Getter :191–:920) · `Sources/MykilosApp/Shell/SidebarView.swift` (navItems :167, mykNameInitials :7)
· `SettingsView+MiniMode.swift:15` · `KeychainInventoryView.swift` · `ConnectionStatusView.swift` ·
`SchaltzentrumView.swift` · `Sources/MykilosKit/Domain/ResidentIdentity.swift` · `MykilosDesign/Tokens.swift`.
