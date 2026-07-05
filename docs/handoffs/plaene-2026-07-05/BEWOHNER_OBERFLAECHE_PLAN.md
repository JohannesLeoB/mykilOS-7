# Bauplan — Bewohner-Oberfläche (Identität / Login / persönlich vs. geteilt)

*2026-07-05, Ultracode-Planungs-Workflow (7 Agenten). Read-only. Verschmilzt mit
[SETTINGS_EBENE_PLAN.md](SETTINGS_EBENE_PLAN.md) — die Login-/Multi-User-Oberfläche IST
großteils die Settings-Ebene. Daten-Unterbau (ResidentIdentity, per-User-Keychain, Orphan-Rebind
A–D) ist FERTIG; dies ist die OBERFLÄCHE darauf. Gegencheck durch Johannes vor dem Bau.*

**Basis:** users-and-groups (Struktur + Regeln) + onboarding-flow (Multi-User Fall A/B, Farb-Bänder)
+ minimal-aufbau (Scope-Disziplin). Modell **V1 = „ein Mensch, ein Mac"** (kein Nutzer-Wechsel, keine
Kontenliste, keine wörtliche Login-Seite).

## Zwei Orte, eine Quelle (`ResidentIdentityStore` + `currentGoogleUser` als Live-Fallback)
**A. Ruheort — Settings-Ebene** (exakt der SETTINGS_EBENE_PLAN, kein neues Top-Level-Modul):
- **Personalausweis** (sticky Header, nicht im ForEach): Avatar · Name · `johannes@mykilos.com` · Rolle · „Hausmeister"-Zeile (read-only)
- **Person-Band:** Darstellung · Privat (Orange, = „Meine Zugänge"/persönliche Logons) · Schlüssel-Inventar
- **Geteilt-Band:** Integrationen (ehrliche Fußnote „liegt lokal in deinem Schlüsselbund" — kein Tresor-Etikettenschwindel)
- **System-Band:** Datenschutz · System
- Farbcode: persönlich = Orange (`MykColor.brand`), geteilt = neutral (`MykColor.muted`).

**B. Fluss — Onboarding-Wizard** (+EIN Schritt, nicht neu gebaut): Google-Ausweis → **[NEU] Meldeadresse bestätigen** („Erkannt als Johannes … stimmt das?") → persönliche Zugänge → geteilte Instrumente ansehen.

## Wiederverwenden (nichts neu) vs. neu (klein)
**Reuse:** ResidentIdentity(+Store) · `enrichResidentIdentity()` (AppState:188) · `identitySection`(:250) + `mailSignaturSection`(:327) → Personalausweis-Detail · `privateAreaSection`(:805, Orange) · `integrationStatusSection`(:391) · `KeychainInventoryView` (unangetastet) · `ClockodoNutzerLoader` (read-only Mail→clockodoUserID) · 6 AuthServices + PerUserKeychainService + Orphan-Rebind · `OnboardingWizardView` (+1 Schritt).
**Neu (MykilosDesign):** `MykSettingsRow`/`MykSettingsGroup` · `MykIdentityHeader` (Avatar via `mykNameInitials`) · 1 Onboarding-Bestätigungsschritt (reine Anzeige).

## Etappen (kleinste zuerst)
| # | Etappe | Scope | GO? |
|---|---|---|---|
| **0** | Toten Link fixen `CLAUDE.md:109 → docs/_archiv/IDENTITY_LOGIN_PLAN.md` | klein | nein |
| **1** | Enum-Rename + Bänder-Reihenfolge + `railCases` | klein | nein · **✅ Rename+Order erledigt (a76267f); railCases offen** |
| **2** | Personalausweis-Header + Detail-Case (`.profil` aus Rail; Header speist aus Google-Quelle, **KEIN** Merge) | mittel | nein |
| **3** | Header auf `ResidentIdentityStore` + Bänder mit `MykSettingsRow/Group` + „liegt lokal"-Fußnote (gegen Screenshots) | groß | nein |
| **4** | Meldeadresse-Bestätigung im Wizard (read-only: Ausweis zeigen, `clockodoUserID` bestätigbar, nur lokaler Write) | mittel | nein |
| **5** | Fall A Multi-User (Bewohner trennen → Orphan-Rebind gibt eigenen Namespace, kein Datenverlust) | mittel | **Entscheid** |
| **6** | `NutzerProvisioningService` (Airtable find-or-create Menschen-Record) + ggf. Fall B echtes Umschalten | groß | **JA (Airtable-Write)** |

**Sofort-Start ohne Entscheidung/GO:** E0 → (E1-Rest) → E2 → E3/E4. E5 nach Multi-User-Entscheid, E6 nach Write-GO.

## GO-pflichtig (bis dahin geparkt)
Genau **ein** Teil schreibt nach außen: `NutzerProvisioningService` (E6) — find-or-create Team-Record in Airtable `Clockodo-Nutzer` `tblPbly2br8mR2kaU` (Base `appuVMh3KDfKw4OoQ`), Blaupause `ProjektProvisioningService`. Bis GO **strikt read-only** (`ClockodoNutzerLoader` liest schon, legt nichts an). Nie DELETE, nie Daniels Records. Neue Daten-Weiche erst hier → dann Datenstrom-Handbuch + `DataFlowLogger`-ID.

## Tests
E1 railCases-Unit · E2 Cold-Start gegen alten `.profil`-Rohwert (decode-Fallback) · E3 Screenshot-Abnahme · E4 Cold-Start clockodoUserID im Ausweis · E5 Cold-Start Namespace-Isolation nach Trennen+Wiedereinzug (evtl. schon von Orphan-Rebind-Test gedeckt) · E6 find-or-create idempotent (Fake-Client). Nach jeder Etappe `swift build && swift test` + `swiftlint --strict`.

## Eiserne-Regel-Check
✅ Per-User-Isolation (Header liest nur eigene Identität) · ✅ KI nie Hausmeister (read-only Anzeige, immer Mensch; Offboarding=archivieren nie DELETE) · ✅ Secrets→Keychain (Ausweis trägt nie Secret, Bänder zeigen Status) · ✅ kein Identitäts-Vortäuschen („erkannt als", nicht „angemeldet als") · ✅ append-only · ✅ Token-Disziplin · ✅ Ehrlichkeit („liegt lokal").

## Offene Entscheidungen (Rest — vieles schon im SETTINGS_EBENE-Gegencheck geklärt)
- **Bereits entschieden:** Bänder privat-zuerst ✅ · Farb-Picker später ✅ · Merge später/eigener Strang ✅.
- **Neu offen:** (1) Multi-User Fall A jetzt oder später (blockt nur E5/E6)? (2) Airtable-Write-GO für Meldeadresse (blockt nur E6)? (3) Header-Redundanz Avatar+Header — okay (Empfehlung: Header=Wahrheit, Avatar=Einstieg)?
