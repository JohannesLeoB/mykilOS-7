# Master-Architektur — Die CHECK-IN-Spine

**Status: Architektur-Vorschlag v1 · 2026-07-05 · Doku-only, KEIN Code-Eingriff in dieser Session.**
Autor: Claude (Architektur-Partner) für Johannes. Formalisiert die von Johannes am 2026-07-05
erkannte **CHECK-IN-Systematik** (`docs/BAUPLAN_FEATURES_2026-07-05.md`, Abschnitt „Die CHECK-IN-
Systematik") zu **einem** Protokoll aus den bereits gebauten Knochen — und zeigt, wie **jedes**
geplante Feature nur noch ein Adapter darauf ist.

> **Der Satz, um den alles kreist (Johannes):**
> **ich hab was → was/wohin/warum → verifizierter Review (okay/nicht okay) → Audit.**
> Append-only, versioniert, idempotent, **nie überschreiben/löschen**, `throws`+SaveState,
> Cold-Start-safe. Wie **Versionskontrolle für die Studio-Realität**.

---

## 0. Kernaussage in fünf Zeilen

1. Es gibt in mykilOS **genau einen disziplinierten Weg**, wie irgendein Datum eintritt oder sich
   ändert: den **Check-in**. Alles andere ist read-only.
2. Die Knochen existieren schon und sind live erprobt: **`CheckoutPort`** (Wirbelsäule) +
   **`*ActionCard`** (Vorschlag+Bestätigung) + **`AuditEntry`/`AuditStore`** (append-only Spur).
3. Diese drei werden zu **einem `CheckIn`-Protokoll** zusammengezogen — die **Spine**.
4. Kamera-Ingest, Lager ein/aus, Kontakt-Selbstheilung, Daniel-Übersetzung, Versand sind dann
   **nur noch `CheckInAdapter`** — keine 12 verstreuten Crash-Safety-Implementierungen, sondern eine.
5. Crash-Safety + Nachvollziehbarkeit + Idempotenz leben an **EINER** Stelle. Das ist der ganze Trick.

---

## 1. Die vier Fundamente, auf die die Spine aufsetzt (Ist-Stand, verifiziert im Code)

Die Bauplan-Fundamente sind bereits als Wertetypen/Protokolle vorhanden. Die Spine erfindet nichts
neu, sie **verklammert** sie.

| Fundament | Ist-Code (verifiziert) | Rolle in der Spine |
|---|---|---|
| **① Pick → WorkBasket → CheckoutPort** | `Sources/MykilosKit/Domain/Wirbelsaeule/WirbelsaeuleFoundation.swift` | Der **Transport**: *was* wird eingecheckt (`Pick`/`WorkBasket`) und *wohin* (`CheckoutPort`). |
| **② Vorschlag→Bestätigung** | `*ActionCard` in `Sources/MykilosWidgets/AssistantChatView.swift` (`ContactActionCard`, `DraftActionCard`, `AirtableContactActionCard`, `CalendarActionCard`) | Der **Review-Gate**: kein Write ohne menschlichen Klick. `CardPhase = idle/saving/done/failed`. |
| **③ Audit-Spur** | `Sources/MykilosKit/Domain/AuditEntry.swift` + `Sources/MykilosServices/Database/AuditStore.swift` (`@MainActor @Observable`, `append(_:) throws`, `SaveState`) | Die **append-only Spur**: jeder erfolgte Check-in hinterlässt einen unveränderlichen Eintrag. |
| **④ Idempotenz + Governance** | `SevdeskPostboxCheckoutPort.objektHash(_:)` (SHA256, append-only, „schon vorhanden?"-Check) · `AirtableClient.writableMap` (Schreib-Whitelist) · `deleteRecord` wirft außer `testDeletableMap` · `WriteShadowRecorder` (Backup-Spiegel) · `DataFlowLogger` (Handbuch-Log) | Der **Sicherheits-Unterbau**: doppelt einchecken = harmlos; nie in fremde Bases; nie DELETE. |

**Bereits real bewiesen:** `SevdeskPostboxCheckoutPort` ist die **erste vollständige Check-in-Kette**
mit echtem externem Write — `preview()` (Vorschlag) → UI-Drop (Bestätigung) → `execute()` (append-only,
idempotent über `objektHash`) → `DataFlowLogger` (Audit/Log). Die Spine ist die **Verallgemeinerung
genau dieses Musters**, damit es nicht pro Feature neu erfunden wird.

---

## 2. Das EINE CheckIn-Protokoll (Skizze — Swift-Signaturen)

Zielort: `Sources/MykilosKit/Domain/Wirbelsaeule/CheckInSpine.swift` (Foundation-only, wie die übrige
Wirbelsäule — importiert **nie** SwiftUI/GRDB). Die Persistenz-/Airtable-Adapter leben in
`MykilosServices`, die Karten in `MykilosWidgets`/`MykilosApp`.

> Diese Signaturen sind ein **Entwurf zur Abstimmung**, kein bereits gebauter Code. Sie sind bewusst
> so gezogen, dass die vorhandenen Typen (`WorkBasket`, `PortZiel`, `CheckoutPreview`, `CheckoutResult`,
> `AuditEntry`) **unverändert** weiterbenutzt werden — die Spine ist eine dünne Klammer darüber.

### 2.1 Die vier Sätze als Typen

```swift
import Foundation

// ── „ich hab was" ─────────────────────────────────────────────────────────────
// Der Gegenstand des Check-ins ist immer ein WorkBasket (heterogen: 1..n Picks).
// Ein Einzel-Ingest (ein gescanntes Teil, eine Visitenkarte) ist ein WorkBasket
// mit genau einem Pick. So gibt es EINEN Transport-Typ, nie zwei.
public typealias CheckInGegenstand = WorkBasket

// ── „was/wohin/warum" ─────────────────────────────────────────────────────────
/// Die Absicht eines Check-ins: WELCHER Adapter (Ziel-Verb), WOHIN (PortZiel),
/// WARUM (Begründung fürs Audit), von WEM (actorUserID — nie KI, immer Mensch).
public struct CheckInAbsicht: Sendable {
    public let adapterID: PortID          // welcher Check-in-Adapter (= CheckoutPort.id)
    public let ziel: PortZiel             // Postbox/Ordner/Tabelle + freie Parameter
    public let begruendung: String        // "warum" — landet im AuditEntry.summary
    public let actorUserID: String        // der bestätigende MENSCH (Autoritätsregel)
    public let projektNummer: String?     // Kontext fürs Audit (AuditEntry.projectID)

    public init(adapterID: PortID, ziel: PortZiel, begruendung: String,
                actorUserID: String, projektNummer: String? = nil) {
        self.adapterID = adapterID; self.ziel = ziel; self.begruendung = begruendung
        self.actorUserID = actorUserID; self.projektNummer = projektNummer
    }
}

// ── „verifizierter Review (okay/nicht okay)" ──────────────────────────────────
/// Das Ergebnis der Vorschau, das die ActionCard dem Menschen zeigt. Erweitert
/// die bestehende CheckoutPreview NICHT — es TRÄGT sie (plus Idempotenz-Signal).
public struct CheckInVorschau: Sendable {
    public let vorschau: CheckoutPreview  // Zusammenfassung + Warnungen (bestehend)
    public let idempotenzSchluessel: String   // SHA256 über den Gegenstand (§4)
    public let istDuplikat: Bool          // true → execute() ist ein No-op-Rückkehr
}

// ── „Audit" ──────────────────────────────────────────────────────────────────
/// Das Ergebnis eines ausgeführten Check-ins. Trägt das bestehende CheckoutResult
/// plus den erzeugten AuditEntry (die Spur), sodass der Aufrufer nichts nachbaut.
public struct CheckInQuittung: Sendable {
    public let ergebnis: CheckoutResult   // erfolg/referenz/meldung/nutzlast (bestehend)
    public let audit: AuditEntry          // die append-only Spur (bestehend)
}
```

### 2.2 Das Adapter-Protokoll (jedes Feature implementiert genau das)

```swift
/// EIN Check-in-Adapter = ein „Ziel-Verb" (in Warenkorb legen, Lager buchen,
/// Kontakt heilen, an Daniels-Base fortschreiben, versenden). Ein Superset des
/// bestehenden CheckoutPort: gleiche preview/execute-Form, plus explizite
/// Idempotenz- und Audit-Pflicht, damit die Spine sie erzwingen kann.
public protocol CheckInAdapter: Sendable {
    var id: PortID { get }                          // stabiler Adapter-Schlüssel (= Rechte-Gate)
    var name: String { get }                        // menschenlesbar (Karten-Titel)
    func erlaubteInhaltsArten() -> Set<InhaltsArt>  // Inhalts-Art-Gate (bestehend)

    /// Deterministischer Idempotenz-Schlüssel über den Gegenstand + die Absicht.
    /// Gleicher Gegenstand + gleiches Ziel ⇒ gleicher Schlüssel ⇒ zweiter Check-in
    /// ist ein No-op. (Muster: SevdeskPostboxCheckoutPort.objektHash.)
    func idempotenzSchluessel(_ g: CheckInGegenstand, _ a: CheckInAbsicht) -> String

    /// „was/wohin/warum" prüfen, NICHTS schreiben. Liefert die Karte-Vorschau
    /// inkl. Duplikat-Erkennung. throws bei nicht-auflösbarem Ziel/Recht.
    func vorschau(_ g: CheckInGegenstand, _ a: CheckInAbsicht) async throws -> CheckInVorschau

    /// Führt den append-only Write aus. VERTRAG: idempotent (Duplikat → erfolg=true,
    /// nichts Neues), nie destruktiv (kein DELETE/Overwrite → nur create/append/
    /// Status-Flag), throws bei echtem Fehler. Gibt Quittung + Audit zurück.
    func fuehreAus(_ g: CheckInGegenstand, _ a: CheckInAbsicht) async throws -> CheckInQuittung
}
```

### 2.3 Der Spine-Orchestrator (die eine Stelle für Crash-Safety)

```swift
/// Die Spine: nimmt Adapter + Registry + Audit-Sink und fährt die Kette
/// Vorschlag→Bestätigung→Audit für JEDEN Adapter identisch. Kein Adapter
/// schreibt selbst ins Audit oder prüft Rechte — die Spine tut es zentral.
public protocol CheckInAuditSink: Sendable {           // implementiert von AuditStore-Wrapper
    func schreibe(_ entry: AuditEntry) async throws     // append-only, throws, SaveState sichtbar
}

public struct CheckInSpine: Sendable {
    private let registry: PortRegistry                 // welche Adapter existieren (bestehend)
    private let rechte: any PortRightsProviding        // Inhalts-Art ∩ User-Recht (bestehend)
    private let audit: any CheckInAuditSink            // die append-only Spur (③)

    public init(registry: PortRegistry, rechte: any PortRightsProviding, audit: any CheckInAuditSink) {
        self.registry = registry; self.rechte = rechte; self.audit = audit
    }

    /// Schritt 1 — Vorschau (schreibt nie). Löst Adapter auf, prüft Recht+Inhalts-Art,
    /// gibt die Karte-Vorschau zurück. Der Aufrufer (UI) zeigt sie in einer ActionCard.
    public func vorschlagen(gegenstand: CheckInGegenstand, absicht: CheckInAbsicht)
        async throws -> CheckInVorschau { /* Adapter finden → adapter.vorschau(...) */ }

    /// Schritt 2 — Ausführung NACH menschlicher Bestätigung. Die UI ruft das erst,
    /// wenn der Nutzer den Bestätigen-Button gedrückt hat (Autoritätsregel: Mensch,
    /// nie KI). Idempotent, nie destruktiv; schreibt danach den AuditEntry.
    public func bestaetigen(gegenstand: CheckInGegenstand, absicht: CheckInAbsicht)
        async throws -> CheckInQuittung {
        // 1) Adapter auflösen + Recht/Inhalts-Art erneut prüfen (nicht auf UI vertrauen).
        // 2) let quittung = try await adapter.fuehreAus(gegenstand, absicht)
        // 3) try await audit.schreibe(quittung.audit)   ← Spur ZWINGEND, throws
        // 4) return quittung
    }
}
```

**Warum genau so:** `preview/execute` = die zwei Methoden, die `CheckoutPort` schon hat. Die Spine
zwingt jeden Adapter zusätzlich zu **explizitem Idempotenz-Schlüssel** und **Audit-Rückgabe**, und
sie schreibt das Audit **selbst** (nicht der Adapter) — so kann kein neuer Adapter das Audit
„vergessen". Der bestehende `SevdeskPostboxCheckoutPort` wird zum ersten `CheckInAdapter` (dünner
Wrapper, `objektHash` → `idempotenzSchluessel`).

---

## 3. Jedes geplante Feature ist ein CheckIn-Adapter (die Übersetzungstabelle)

Jede Zeile = **ein** Adapter, der `CheckInAdapter` implementiert. Kein Feature bringt eine eigene
Vorschlag/Bestätigung/Audit/Idempotenz-Mechanik mit — es füllt nur `vorschau`/`fuehreAus`.

| Feature (Bauplan-Track) | Gegenstand („ich hab was") | Ziel-Verb / `PortID` | Schreibt wohin (nie destruktiv) | Idempotenz-Schlüssel | Decision-Gate |
|---|---|---|---|---|---|
| **Kamera „Verwendung wählen" (G8)** | Scan-Ergebnis → `WorkBasket(1 Pick)` | wählt aus: `warenkorb`/`artikel`/`lager`/`kontakt` | delegiert an den gewählten Adapter unten | Adapter-abhängig | — (Kamera A3/G8 = Live-Gate, kein Datengate) |
| **Barcode → in Warenkorb (G2)** | Artikel-Pick | `PortID("warenkorb")` | `WorkBasketStore` (append-only Version) | Code+Menge+Korb-Version | — |
| **Lager aus-/einbuchen (G9)** | Mengen-Bewegung als Pick | `PortID("lager-bewegung")` | **mykilOS-eigene** Lager-Base, **append-only Bewegung** (Stand = Summe), nie in-place | Barcode+Menge+Richtung+Zeitfenster | **⛔ G9 — Daniel/Johannes** (§5) |
| **Visitenkarte → Kontakt (G5)** | OCR-Kontakt als Pick | `PortID("kontakt-neu")` | Airtable `Kontakte` (create) **+ Google Contacts (NEU)** | Name+Mail+Tel-Hash, Dubletten-Check | **⛔ G5 — Johannes** (Google-Write-Scope + Re-Consent) |
| **Kontakt-Selbstheilung (G6)** | Delta auf bestehenden Kontakt | `PortID("kontakt-heilen")` | Airtable `updateRecord` (Lücken füllen); Merge = Verlierer auf `Status=Archiviert` **flaggen**, **NIE DELETE** | Feld-Delta-Hash pro Zielrecord | teilw. **⛔ G5-Scope** |
| **Daniel-Übersetzung / Fortschreiben (L1b/L2)** | übersetzter externer Record | `PortID("core-fortschreiben")` | **mykilOS-eigene Core-Base**, Änderung = **neue Version** (append-only), Dedup per Artikelnr./SHA256 | Artikelnr.+Inhalts-SHA256 | **⛔ L — Daniel am Tisch** (§5) |
| **Versand / DHL (K)** | Empfänger-Kontakt + Paketinhalt | `PortID("versand")` | Carrier-Adapter (Keychain-Cred, Postbox-Disziplin); Tracking-Nr. Rückweg als Erfassen-Check-in | Empfänger+Inhalt+Datum-Hash | **⛔ K — Carrier-API + Johannes** (§5) |
| **sevDesk-Postbox (bereits live)** | herausgelöste Positionen | `PortID("sevdesk-postbox")` | Airtable Postbox-Beleg+Positionen, append-only | `objektHash` (SHA256, existiert) | — (gebaut) |
| **Fragebogen-Intake / Provisioning (bestehend)** | Kunde/Projekt/Warenkorb | `PortID("provisioning")` | Airtable via `writableMap`, Ledger-Idempotenz | Provisioning-Ledger-Key (existiert) | — (gebaut) |

**Muster-Beweis:** Die letzten zwei Zeilen sind **schon gebaut** und passen ohne Zwang ins Schema —
das ist der Nachweis, dass die Abstraktion die Realität trifft und nicht daneben liegt.

---

## 4. Crash-Safety-Checkliste (gilt für JEDEN Adapter — die Spine erzwingt sie)

Ein Check-in ist erst „fertig", wenn **alle** Punkte grün sind. Ableitung direkt aus den Eisernen
Regeln + dem live erprobten `SevdeskPostboxCheckoutPort`.

**Idempotenz (doppelt einchecken = harmlos)**
- [ ] `idempotenzSchluessel(...)` ist **deterministisch** (nur Inhalt/Ziel, **kein** `Date()`/`UUID()`/Zufall im Schlüssel).
- [ ] `fuehreAus` prüft **vor** dem Write, ob der Schlüssel schon existiert → wenn ja: `erfolg=true`, `referenz`=bestehend, **nichts Neues anlegen** (Muster: `bestehenderBeleg(objektHash:)`).
- [ ] Zweiter identischer Aufruf erzeugt **null** neue Records **und null** neuen Audit-Eintrag für den Write (nur ein „Duplikat, kein neuer"-Log).

**Append-only / nie destruktiv**
- [ ] Kein `deleteRecord` außer über `testDeletableMap` (Live-Code wirft bereits).
- [ ] Kein Overwrite bestehender Werte: Änderung = **neue Version** (append) oder **Status-Flag** (`Archiviert`/`Old`) + Verweis auf den Sieger. Nie in-place mutieren.
- [ ] Ziel-Base steht auf `AirtableClient.writableMap`; fremde/Daniels Base ist read-only Upstream.
- [ ] Kontakte (G6): Merge/Dedup ausschließlich per `updateRecord`-Flag, **NIE DELETE** (Johannes 2026-07-05, eisern).

**Reihenfolge (crash zwischen den Schritten überlebt)**
- [ ] Beleg-Kopf/Parent zuerst, Positionen/Kinder danach mit Verweis — bricht es dazwischen ab, findet der nächste Lauf den Objekt-Hash **nicht** (Kopf trägt ihn) → **nichts halb-doppelt**. (Bewusst: Kopf trägt den Idempotenz-Schlüssel; ein abgebrochener Lauf ohne Kopf ⇒ sauberer Retry; mit Kopf aber ohne alle Positionen ⇒ als Backlog-Punkt §6 „Teil-Write-Reconciliation" markiert, nicht verschwiegen.)
- [ ] `resolve()` der Picks darf werfen — **kein stiller `try?`** (Rückverfolgbarkeit).

**Persistenz + Sichtbarkeit**
- [ ] Jeder Write `throws`; der `AuditStore`-Pfad setzt `SaveState` (`saving`/`saved(Date)`/`failed(String)`) sichtbar in der UI.
- [ ] `@Observable`-Stores sind `@MainActor` (AuditStore, WorkBasketStore).
- [ ] Der Audit-Eintrag wird von der **Spine** geschrieben (`audit.schreibe`), nicht vom Adapter — kann nicht vergessen werden.
- [ ] Zusätzlicher Sicherungsgurt für externe Writes: `WriteShadowRecorder` (Backup-Base-Spiegel, append-only) + `DataFlowLogger` (Datenstrom-Handbuch-Log, `integrationID` == Handbuch-Eintrag).

**Cold-Start (Guardrail-Pflicht)**
- [ ] Neuer persistierter Zustand → **Cold-Start-Test**: einchecken → neue Store-Instanz → lesen → identisch (Muster: `auditEntryUeberlebtNeustart`, `recordAdjustmentUeberlebtNeustart`).
- [ ] Idempotenz-Cold-Start: zweimal einchecken über **zwei** Store-Instanzen hinweg → weiterhin ein Record.

**Migration (falls ein Adapter ein neues Widget/Board-Feld braucht)**
- [ ] Nicht-destruktiv + idempotent nach dem `ensureWidgetOnce`-Muster (`WidgetBoardStore`).

**Renderstates (falls der Adapter ein Widget hat)**
- [ ] Alle **6**: loading / content / empty / permissionRequired / offline / error — keine Sackgasse. Bestätigungskarte hat `idle/saving/done/failed` (Muster: `ContactActionCard.CardPhase`).

**Tokens**
- [ ] Nur `MykColor`/`MykSpace`/`Font.myk…` — kein rohes `Color(hex:)`/`.font(.system(...))`. SwiftLint-sauber.

---

## 5. Decision-gated Stränge (brauchen Johannes/Daniel — NICHT ohne GO bauen)

Klar markiert, damit niemand aus Versehen an einem gesperrten Strang baut. Die **Spine selbst**
(§2) + die **ungated Adapter** (Warenkorb, sevDesk-Postbox schon live) sind frei baubar. Diese hier
nicht:

| Strang | Gate | Warum gesperrt | Was den Bau freischaltet |
|---|---|---|---|
| **G9 — Artikel-/Lager-Ingest** | **Johannes + Daniel** | „Aus-/einbuchen" ändert Mengen — genau das in Daniels heiliger Base `appdxTeT6bhSBmwx5` Verbotene. Schreib-Ziel muss die **mykilOS-eigene** Lager-Base sein (Abnabelung §8b). | Entscheidung: eigene Lager-Base steht + Business-Key-Übergabe mit Daniel geklärt. |
| **G5 — Visitenkarte → Kontakt (Google-Write)** | **Johannes** | Google-Contacts-**Write** existiert nicht (`GoogleContactsClient` ist read-only). Braucht People-API-Write-Scope + **Re-Consent**. Airtable-Kontakt-Write ist da (gated, S19). | Johannes macht Re-Consent mit neuem Scope; dann `createContact`/`updateContact` bauen. |
| **G6 — Kontakt-Selbstheilung (Google-Anteil)** | **Johannes** | Teilt den G5-Google-Scope. Airtable-Anteil (`updateRecord`-Flag, nie DELETE) ist baubar. | wie G5. |
| **L — Daniel-Abnabelung / Fortschreiben** | **Daniel am Tisch** | Kern-Umbau Kunde/Projekt/Artikel + Schreib-Übergabe an seine sevDesk/Make-Pipeline über Business-Keys. Keine mykilOS-Solo-Entscheidung (`AIRTABLE_ARCHITEKTUR.md` §7/§8). | Ziel-Modell + Business-Keys (`Projektnummer`/`Kundennummer`) in Daniels Base nachgezogen; Feeder-Übergabe abgestimmt. |
| **K — Versand/DHL** | **Johannes** | Externe Carrier-API = Outer Limit (Interior-Build-Charter). Braucht Adapter/Port + Keychain-Credentials + Postbox-Disziplin, carrier-neutral. | Johannes gibt Carrier + Zugang frei; eigener Integrations-Strang. |
| **J3 — Rollen/Rechte (echter `PortRightsProviding`)** | **Team** | Aktuell `AllowAllPortRights`. Der echte Admin-verteilte Rechte-Filter (D1/S10 §9) ist eine Team-Entscheidung. | Rollenmodell in Airtable + Freigabe. |

**Ungated & sofort baubar (die empfohlene Bau-Reihenfolge zielt hierauf):** die Spine (§2), der
Wrapper von `SevdeskPostboxCheckoutPort` als erster `CheckInAdapter`, der Warenkorb-Adapter (G2,
schreibt nur in den lokalen `WorkBasketStore`).

---

## 6. Bau-Reihenfolge (step by step — nichts auf einmal, Beppo-Prinzip)

Jeder Schritt endet mit dem **GATE**: `swift build` grün · `swift test` grün (exakte Testzahl notieren)
· gegen Screenshots wo UI. Kein Schritt startet ohne Johannes' GO für den jeweiligen Track.

1. **Spine-Typen (Doku→Code), ungated.** `CheckInSpine.swift` in `MykilosKit/Domain/Wirbelsaeule/`
   anlegen: die Typen aus §2 (`CheckInAbsicht`, `CheckInVorschau`, `CheckInQuittung`, `CheckInAdapter`,
   `CheckInSpine`, `CheckInAuditSink`). Reine Wertetypen/Protokolle, **null** Verdrahtung. Foundation-only.
   → Unit-Tests: Registry-Auflösung, Duplikat-Vorschau, Rechte-Schnittmenge. **Kein persistenter Zustand.**
2. **`AuditStore`-Wrapper als `CheckInAuditSink`.** Dünner Adapter in `MykilosServices`, der
   `append(_:)` auf das Protokoll mappt. Cold-Start-Test bleibt der bestehende (`auditEntryUeberlebtNeustart`).
3. **`SevdeskPostboxCheckoutPort` → erster `CheckInAdapter`.** Wrapper: `objektHash` →
   `idempotenzSchluessel`, `preview`→`vorschau`, `execute`→`fuehreAus` (baut `CheckInQuittung` inkl.
   `AuditEntry`). **Reiner Refactor, kein Verhaltensänderung** — die bestehenden Sevdesk-Tests müssen
   grün bleiben (Regressionsschutz). Beweist: die Spine bricht nichts Live-Erprobtes.
4. **Warenkorb-Adapter (G2, ungated).** `PortID("warenkorb")`: Pick → `WorkBasketStore` (append-only
   Version). Erster **neuer** Adapter auf der Spine. Cold-Start-Test: Pick eincheckt → Neustart →
   Version überlebt; zweiter identischer Check-in → keine Doppel-Version.
5. **UI-Naht: generische `CheckInActionCard`.** Eine Karte, die aus `CheckInVorschau` rendert
   (`idle/saving/done/failed` wie `ContactActionCard`) und bei Bestätigung `spine.bestaetigen(...)`
   ruft. Ersetzt perspektivisch die vier Einzelkarten (schrittweise, nicht auf einmal).
6. **Kamera-Ziel-Menü (G8) auf die Spine setzen** — „Verwendung wählen" wählt nur die `adapterID`,
   der Rest ist die Spine. (Kamera A3 selbst bleibt Live-Gate bei Johannes.)
7. **Danach, je einzeln auf GO + nach Gate-Freigabe (§5):** G9 (eigene Lager-Base), G5/G6 (Google-
   Scope), L (Daniel), K (Carrier). Jeder als isolierter Adapter, jeder mit voller Crash-Safety-
   Checkliste (§4).

**Offener Backlog-Punkt, ehrlich markiert (kein Hack):** „Teil-Write-Reconciliation" — wenn ein Lauf
nach dem Beleg-Kopf, aber vor allen Positionen abbricht, ist der Kopf da (mit Idempotenz-Schlüssel),
die Positionen unvollständig. Heute schützt der Kopf-Hash vor Doppel-Anlage, aber ein **Vervollständigen**
der fehlenden Positionen ist noch nicht modelliert. Für die ersten Adapter (kleine Körbe, Airtable-
Latenz niedrig) tolerierbar; für große Körbe später ein **Wiederaufnahme-Schritt** (fehlende Pos-Hashes
nachziehen) — als eigener Punkt notiert, nicht stillschweigend übergangen.

---

## 7. Verortung im Repo (wo was hingehört — Modulregeln bleiben eisern)

```
MykilosKit/Domain/Wirbelsaeule/CheckInSpine.swift   ← Protokoll + Wertetypen (Foundation-only)
MykilosServices/Wirbelsaeule/…CheckInAdapter.swift  ← konkrete Adapter (Airtable/Drive/Keychain)
MykilosServices/Database/AuditStore.swift           ← CheckInAuditSink (bestehend, GRDB)
MykilosWidgets/…/CheckInActionCard.swift            ← die eine generische Bestätigungskarte
MykilosApp/…                                        ← Verdrahtung: Registry aufbauen, Spine injizieren
```

- `MykilosKit` importiert **nie** SwiftUI/GRDB (die Spine ist reine Domäne).
- Schreibvorgänge kommen **nie** aus Views — nur über Stores/Adapter, angestoßen durch die Spine.
- Jede neue Daten-Weiche eines Adapters → **sofort** ins Datenstrom-Handbuch (`tblaUVftka0GvXzeU`) +
  `docs/BENUTZERHANDBUCH.md`; die `integrationID` im `DataFlowLogger.log()` muss exakt zum Handbuch-
  Eintrag passen.

---

## 8. Ein-Satz-Zusammenfassung

> **Bau die Spine einmal (Vorschlag→Bestätigung→Audit, append-only, idempotent, crash-safe) — dann
> ist jedes Feature nur noch ein `CheckInAdapter`, und die Crash-Safety lebt an EINER Stelle statt
> zwölfmal verstreut.**

---

*Quellen: `docs/BAUPLAN_FEATURES_2026-07-05.md` (CHECK-IN-Systematik + Tracks A–L) ·
`docs/AIRTABLE_ARCHITEKTUR.md` (Abnabelung §8b) · `HYPERBUILD.md` · Ist-Code
`WirbelsaeuleFoundation.swift`, `SevdeskPostboxCheckoutPort.swift`, `AuditEntry.swift`,
`AuditStore.swift`, `AssistantChatView.swift` (ActionCards), `WriteShadowRecorder.swift`,
`DataFlowLogger.swift`, `AirtableClient.writableMap`. Verifiziert 2026-07-05.*
