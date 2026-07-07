# Admin-Ebene — gehärteter Bauplan (adversarial verifiziert)

**Stand:** 2026-07-07 · Branch `feat/multi-user-login` · Multi-Agent erarbeitet (3 Leser + Architekt + 3 Sicherheits-Angreifer + Reconcile), jede Load-bearing-Aussage am Code verifiziert. **Stufe 1 gebaut** (`AdminAuthority` inkl. Token-Kopplung); Rest zur Freigabe.

## Kern-Sicherheitsprinzip
Admin **nur** aus der **verifizierten** `ResidentIdentity.googleEmail`, nie aus `UserProfile.role` (Freitext, wird in keinem Authz-Pfad gelesen). **Ehrliche Grenze:** auf einem local-first macOS-Client, dessen Prozess unter dem Angreifer läuft, ist KEINE rein lokale Grenze fälschungssicher — die googleEmail wird beim Start ohne Netz aus dem lokal beschreibbaren Keychain hydriert (`GoogleAuthService.swift:42`). Der Client-Guard ist **Komfort + Nachweis + Verzögerung**; die absolute Grenze sitzt **serverseitig bei den Airtable-/Google-Key-Scopes**.

## Die drei tragenden Härtungen (aus den Angriffen)
1. **Token-Kopplung** (Angriff 1+2, ✅ in Stufe 1 gebaut): `istAdmin(identity, tokenPresent:)` — Admin nur, wenn zusätzlich ein echtes Google-Refresh-Token im selben per-User-Namespace liegt. Mail fälschen geht, ein gültiges Google-Token für die Admin-Mail nicht. Für **extern-wirksame** Admin-Aktionen zusätzlich frische Live-`fetchUserInfo`-Reverifikation (A.4).
2. **Airtable-Rollen-Override in V1 GESTRICHEN** (Angriff 2+8): der Team-PAT steckt in jeder `.mykinvite` UND ist schreibfähig → ein Eingeladener setzt `Rolle=Admin` bei sich → Selbst-Beförderung. Einziger Anker = compile-time `AdminAllowlist.gebacken`. (Dritter Admin ohne Release ist den Zirkelschluss nicht wert. Falls später: separate nicht-team-PAT-Quelle ODER signierte Liste + ASCII/Homoglyph-Normalisierung.)
3. **Store-Gate VOR/mit UI-Verstecken** (Befund 8): Enforcement (Stufe 4) nie nach UI-Verstecken (Stufe 3) ausrollen. Verstecken ist UX, nie Sicherheit.

## Gate-Punkte (vollständig, am Code verifiziert)
**ADMIN-ONLY (`requireAdmin` als 1. Zeile im Store, `+ identity`, `+ tokenPresent`):**
- `NomenklaturStore.setzeSchema` (:115), `.setzeSchemaAufStandard` (:137) — Struktur/Schema-Template.
- `NomenklaturStore.setzeAuthorityMode` (**neu**, Setter existiert noch nicht) — Umgebung.
- `AppState.einladungErstellen` (:668) — Guard **vor** dem Keychain-Read (:676!) + Live-Reverifikation (A.4).
- `KalkulationsEngine.promote(candidateID:)` (:212) — **OFFEN: Admin oder User?** (verschiebt team-weite Kalkulationsbasis).
- Ghost→echt-Migration (künftig).

**USER-ERLAUBT (KEIN Guard — bewusst, nicht versehentlich gaten):**
- `ProjektProvisioningService.provision` (:71, nur der bestehende `mode==.test`-Gate bleibt) — zentraler User-Flow.
- `LocalSequentialAuthority.nextAndReserve/…Kollisionsfrei` (:76/:98).
- `AppState.erzeugeKundeUndProjekt` (:1244), `erzeugeAusFragebogen` (:1136), `einladungOeffnen` (:702), `writeAirtableContact` (:1033).
- `recordAdjustment`, `schaetze` (KalkulationsEngine).

**Wichtig — `.prod` ist KEIN Runtime-Admin-Recht** (Angriff 3): `ProvisioningModeStore.setMode` wirft für jedes `!= .test` `prodLocked` (Code-Lock). Kein folgenloser `requireAdmin` davor. Go-Live = Code-Änderung + Johannes-Live-Abnahme, kein Admin-Klick.

**Assistent bleibt strukturell unter der Admin-Linie** (Befund 2): `AssistantToolRegistry.standard()` ist default-deny-Whitelist; kein Tool erreicht `provision/setzeSchema/setMode/einladungErstellen/promote`. Mit Cross-Check-Test absichern.

## Nummern-Autorität (D)
Weil **normale User (viele, parallel) nummerieren**, ist `.local` (nur pro Gerät atomar) unzureichend. Zwei Offline-User → **garantierte Kollision ist der Normalfall**. Es gibt keine offline-global-atomare Lösung → **`.airtable` (System-of-Record, `appuVMh3KDfKw4OoQ`) + Kollisions-Toleranz + Sync-Rekonziliation**: Offline-Nummern als `reserviert-offline` + Geräte-Marker; beim Sync kollidierende → neue globale Nummer, provisorische **archiviert (nie gelöscht)**. `.airtable` ist nur sicher MIT Rekonziliation (Pflicht). Modus-Umschaltung ist Admin-only (Gate `setzeAuthorityMode`).

## Einladung/Keys (E)
`.mykinvite` verleiht **nie** Admin (kein Rollenfeld, darf nie eines bekommen). Erstellen = Admin; Öffnen/Import = jeder. Audit `inviteCreated` mit **verifizierter** `currentIdentity.googleEmail` als Actor (nicht spoofbares `actorUserID`), ohne Keys zu loggen. **Ehrliche PAT-Grenze:** App-Admin begrenzt NICHT die Airtable-Schreibrechte — die reale Grenze ist der PAT-Scope → **minimale Scopes + Rotation bei Verlust** (Datei-Ablauf schützt die Keys darin nicht).

## Stufenplan
- **S1 ✅ gebaut:** `AdminAllowlist` + `AllowlistAdminAuthority.istAdmin(_, tokenPresent:)`/`assertAdmin` + `BerechtigungError.nurAdmin` (Kit, 8 Tests inkl. Token- + Eskalations-Negativtest).
- **S2:** `AppState.currentIdentity` (mit A.5-Fallback auf `googleAuth.currentUser?.email` gegen Lockout bei Airtable-Timeout) + `currentAdminTokenPresent` + `istAktuellAdmin` (read-only, Debug-Label). Kein Airtable-Roster.
- **S3+S4 GEKOPPELT:** Store-Gate (`requireAdmin` in setzeSchema/…Standard/einladungErstellen — vor Keychain-Read) + UI (`AdminZoneSection`, Invite-Split „erstellen"=Admin/„öffnen"=alle, Lockout-Leerzustand). **Eskalations-Negativtests** inkl. Positiv-Gegenprobe (Nicht-Admin legt Projekt DURCH an, Ledger geschrieben) + Assistent-Whitelist-Cross-Check.
- **S5:** Airtable-Roster — in V1 **übersprungen** (s. o.); Invite-Audit trotzdem in S4.
- **S6:** `AirtableAuthority` + Offline-Rekonziliation + Modus-Umschalter (Admin-gated). Harte Abschlussbedingung: 2 Geräte quasi-gleichzeitig → 2 verschiedene Nummern, live von Johannes geprüft.

## Offene Entscheidungen (Dringlichkeit)
1. **Daniels exakte Admin-Mail** — blockt `AdminAllowlist.gebacken` (sonst nur Johannes Admin).
2. **Airtable-Roster ja/nein?** Empfehlung: in V1 streichen.
3. **`promote` Admin oder User?**
4. **Airtable-PAT-Scopes minimieren + Rotationsplan** (die reale externe Grenze).
5. **`.airtable` als Default-Nummernmodus** — sobald Mehr-User live, nach Live-Abnahme des Kollisionstests.
6. **A.4 Live-Reverifikation vor Invite-Erstellung** — ok, dass Invite-Erstellen einen Online-Login voraussetzt?
