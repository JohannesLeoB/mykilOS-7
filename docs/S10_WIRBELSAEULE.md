# S10 — Wirbelsäule Blueprint · `Pick → WorkBasket → Port → CheckoutRun`

**Status: Grundsatz-Blueprint v1 · 2026-07-02 · reines Papier (kein Code).**
Vision Johannes, Architektur Claude. Baut auf `WARENKORB_CHECKOUT.md §1–§5j` auf und ist die
Blaupause, gegen die Welle C (C1–C4) gebaut wird. Nichts hier ist implementiert — dieses Dokument
wird bestätigt, *dann* beginnt Code.

---

## 0. Die S10-Grundsatzentscheidung

**Entscheidung: EINE generische Pipeline, keine Sammlung von Einzel-Features.**

Begründung: In den Konzept-Sessions (2026-07-02) hat Johannes durchgängig *ein System* beschrieben —
Postbox pro Port, Rechte-Gate, stabile Katalog-IDs, Lebenszyklus. Das sind keine vier Features,
das ist **ein Primitiv mit Konfiguration**. Also:

- **Pick / WorkBasket / Port / CheckoutRun** sind vier generische Bausteine.
- **Neue Kataloge, neue Ports, neue Postboxen = Konfiguration/Erweiterung** — kein neuer UI- oder
  Code-Strang je Anwendungsfall. Das UI (ein Checkout-Sheet) skaliert von selbst mit dem
  wachsenden Port-Katalog.
- **Anti-Ziel:** kein Artikel-only-Hardwiring, kein Port-als-eigener-Button, keine zweite
  Erkennungslogik neben der generischen.

---

## 1. Die vier Primitive (Typmodell, MykilosKit-Ebene)

Foundation-only, `MykilosKit/Domain/` — importiert **nie** SwiftUI/GRDB. Persistenz liegt in
`MykilosServices`, UI in `MykilosApp`.

```
Pick          — typisierter Verweis auf EIN Katalog-Objekt: { matrix, objektID(stabil), snapshot, resolve() }
WorkBasket    — geordnete, versionierte, append-only Menge von Picks; trägt inhaltsArt + Projektbezug + Lebenszyklus-Status
Port          — benannter Ausgang (CheckoutTarget): nimmt einen WorkBasket, erzeugt Output in eine Ziel-Postbox
PortRegistry  — liefert verfügbare Ports = ports(fuer: inhaltsArt, user:)  →  Inhalts-Art ∩ User-Recht
CheckoutRun   — ein Checkout: WorkBasket + Port + Ziel → Preview → Bestätigung → Ausführung → Audit
```

Protokoll-Skizze (Konzept, nicht final):

```swift
// MykilosKit/Domain — Foundation only
protocol Pick {
    var matrix: CatalogMatrix { get }      // Artikel, Kontakt, Bild, Dienstleistung, Eingangsangebot, …
    var objektID: CatalogObjectID { get }  // STABIL, einmalig, unveränderlich (Rückverfolgbarkeit)
    var snapshot: PickSnapshot { get }      // leichte Metadaten (Bezeichnung, Menge, EK, VK, …)
    func resolve() async throws -> PickContent   // lazy: Bytes/Datei/Kontaktkarte erst beim Checkout
}

struct WorkBasket {
    let id: WorkBasketID                    // einmalig, nie wiederverwendet
    let projektNummer: String
    var inhaltsArt: InhaltsArt              // Artikel | Bilder | Material | Zeichnungen | Dokumente | gemischt | …
    var picks: [Pick]                       // geordnet
    var version: Int                        // append-only Versionierung (Keim: WarenkorbEintrag.version existiert)
    var status: WorkBasketStatus            // siehe §7 Lebenszyklus
    let erstellt: Date
}

protocol Port {                            // = CheckoutTarget
    var id: PortID { get }                  // z. B. "sevdesk", "moodboard", "geraeteliste", "firefly-prompt"
    var name: String { get }
    func erlaubteInhaltsArten() -> Set<InhaltsArt>   // Inhalts-Art-Gate (§5b/§5d)
    func preview(_ basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutPreview
    func execute(_ basket: WorkBasket, ziel: PortZiel) async throws -> CheckoutResult  // schreibt/rendert/prompted
}
```

---

## 2. Pick — trägt echten Inhalt + stabile Katalog-ID

- **Jedes Katalog-Objekt** (Artikel, Kontakt, Bild, Textblock, Dienstleistung, Eingangsangebot-
  Position, …) trägt eine **einmalig vergebene, unveränderliche `CatalogObjectID`/Hash** — sie wird
  **nie weitergegeben, kopiert, gelöscht oder verändert** (Rückverfolgbarkeits-Leitlinie, Johannes
  2026-07-02). Ein Pick referenziert diese ID → jeder Wert ist lückenlos ins Original zurückverfolgbar.
- **`resolve()` ist lazy:** der Pick-Snapshot bleibt leicht (Referenz + Metadaten); echte Bytes
  (Bild, PDF, vCard) werden erst beim Checkout materialisiert (§5g). Warenkörbe bleiben leicht,
  keine doppelte Binär-Persistenz.
- **Inhalts-Arten (Matrizen):** Kunde · Projekt · Artikel · Material · Lager · Bilder · Zeichnungen ·
  Textblöcke · Dienstleistungen · Eingangsangebote (+ einzelne Positionen daraus) · … (erweiterbar).

---

## 3. WorkBasket — der verallgemeinerte Warenkorb

- **Keim heute:** `CartStore` + Warenkörbe-Tabelle (nur Artikel-Positionen, append-only,
  `WarenkorbEintrag.version` existiert). → **verallgemeinern** auf alle Matrizen; kein Artikel-only mehr.
- **`inhaltsArt`** = *was* im Korb steckt (§5b), nicht der Zweck. Steuert, welche Ports im Checkout
  erscheinen.
- **Projektbezug + Versionierung:** jeder Korb gehört einem Projekt; Änderungen erzeugen neue
  Versionen (append-only), nie Überschreiben.
- **Gemischt erlaubt:** ein Korb kann Kontakt + Artikel + Eingangsangebot + Notiz zugleich tragen.
- **Lebenszyklus-Status:** siehe §7.

---

## 4. PortRegistry + Ports

**Verfügbare Ports = `ports(fuer: inhaltsArt, user:)` = Inhalts-Art-Gate ∩ User-Recht** (§5f):
- **Inhalts-Art-Gate:** eine Inhalts-Art bietet nur passende Ports (Kreativ-Korb → Moodboard/Firefly;
  Artikel-Korb → Geräteliste/Angebot/sevDesk; §5b/§5d).
- **User-Recht:** ein **Admin** verteilt Port-Rechte; heikle Ports (sevDesk-Übergabe) sind typischerweise
  Finance/Admin. Rechte-Quelle perspektivisch Airtable (pro User → erlaubte Ports), lokal gecacht.
- **Jeder Port hat seine eigene Ziel-Postbox** (§6). Neue Ports erscheinen automatisch in der Liste —
  kein neues UI je Port.

**Port-Katalog v1** (aus §5c, erweiterbar): Moodboard · Geräteliste (an Tischler) · Angebot ·
Materialauswahl · Bestellung · Präsentation · Nachtrag zu … · Firefly-Bild-Prompt · Kalkulation ·
Ausstattungs-/Spec-Liste · Auftragsbestätigung · Abnahmeprotokoll · Aufmaß-/Montageliste ·
Mail-Entwurf · Drive-Ablage · ClickUp-Aufgaben · CAD-Handoff · Datenblatt-Sammlung · **sevDesk-Übergabe**.

---

## 5. Checkout = EIN Flow (E-Commerce-Metapher, §5e)

```
WorkBasket → [ Checkout-Sheet ]
   1. Port wählen        („Zahlungsart")   — Liste gefiltert nach Inhalts-Art ∩ User-Recht
   2. Ziel konfigurieren („Versandadresse") — port-spezifische Ziel-Postbox / Renderer / Template
   3. Preview             — was rauskommt, bevor es passiert
   4. Bestätigen          — Karte → Bestätigung → Audit  (sevDesk: DOPPELTE Bestätigung)
   5. Ausführung          — execute() schreibt/rendert/prompted in die Ziel-Postbox
```

- **Ein Sheet für alle Ports.** Neue Ports = neue Zeile in der Port-Liste, kein neues UI.
- **CheckoutRun** kapselt Preview → Bestätigung → Ausführung und schreibt bei Ausführung **immer**
  `AuditEntry` **+** `DataFlowLogger.log` **+** WriteShadow (§8).

---

## 6. Postboxen — die Zieladressen der Ports

Jeder ausgehende Port schreibt in eine **eigene, append-only Ziel-„Postbox"** (= die „Versandadresse").
Postboxen sind **Einweg** je Richtung.

**`mykilOS_Sevdesk Postbox`** (Ausgang, §5i) — die erste konkrete Postbox:
- **Keine Bilder.** Nur Text/Zahlen/Links/Referenzen.
- **Einmalige Warenkorb-ID** je Übergabe (Abhol-Schlüssel für sevDesk), nie identisch/wiederverwendet.
- **Append-only:** nie überschreiben, nie löschen; Inaktivierung nur per Status.
- **Schematisch immer gleich:** feste Feldstruktur (Kopf + Positionen).
- **Pflichtinhalt:** Datum · Projekt · Kunde · Zeitstempel · Artikel · Gesamtwert vor Rabatt in
  **EK und VK** · Fließtexte · alle Details; je Position der stabile Objekt-Hash.
- **mykilOS berührt sevDesk NIE direkt** — weder schreibend noch lesend. sevDesk *holt ab*.
- **Nur opt-in + rechte-gated:** nur berechtigte User via Port „an sevDesk".

**Eingangs-Postbox (Gegenrichtung, sevDesk → mykilOS):** für Daten, die mykilOS von sevDesk braucht
(Bestätigungs-Status, Ist-Umsatz). sevDesk schreibt, **mykilOS liest** — nie direkter sevDesk-Read.
Speist §7 (Cash-Widget).

---

## 7. Warenkorb-Lebenszyklus + Cash-Widget (§5j)

**State Machine des Projekt-Warenkorbs:**

```
   [ KALKULATION · live, nicht final ]
        └─ aktuellster Kalkulationswarenkorb; ändert sich frei
        └─ das zeigt die Projekt-Übersicht als KALKULATIONSGRÖSSE
                    │  sevDesk markiert „bestätigt" (via Eingangs-Postbox)
                    ▼
   [ BESTÄTIGT · eingefroren · fest am Projekt ]   ← unveränderlich
                    │  Fortführung NUR durch
                    ▼
   [ + Nachtragswarenkorb ]   oder   [ + Gutschrift (späteres Kapitel) ]
        └─ append-only Kette · gültiger Projektwert = Summe der Kette
```

- **Cash-Widget = Fenster darauf, liest NUR aus der sevDesk-Postbox** (nie direkt sevDesk). Zeigt je
  Projekt den **aktuellsten** (live) *oder* den **bestätigten** (eingefroren) Warenkorb.
- **Zweck:** in jeder Projekt-Übersicht sofort sehen, *was angeboten wird* und *was die aktuellen
  Kalkulations-Warenkörbe / Gerätelisten sind*.
- **Eiserne Sicherheit:** nie gelöscht, nie editiert. Bestätigt + Nachträge (− Gutschriften) = Kette.
- **Reframe:** das heutige `CashWidget` wird vom sevDesk-Rechnungsleser zum **Postbox-Lebenszyklus-
  Fenster**. (Der Lebenszyklus-„Lock" ≠ der behobene Freeze-UI-Bug.)

---

## 8. Instrumentierung (aus dem I/O-Audit 2026-07-02)

Der Audit fand: kein externer Write hatte bisher *beide* Nachweise. Für die Wirbelsäule ist der
Standard **verbindlich**:

> **Jeder externe Write (jeder `Port.execute`) → `AuditEntry` + `DataFlowLogger.log(integrationID:)` + WriteShadow.**

- Schließt beide Buchhaltungslücken auf einen Schlag.
- Jede Postbox/jeder Port bekommt eine **Datenstrom-Handbuch-ID** (Airtable `tblaUVftka0GvXzeU`), die
  exakt mit der `integrationID` im Code übereinstimmt (Datenstrom-Eisenregel).
- sevDesk-Port: zusätzlich **doppelte Bestätigung** + Inhalts-Hash (SHA256) + Erzeuger je Record.

---

## 9. Bau-Reihenfolge (Welle C)

| Schritt | Inhalt | Abhängigkeit |
|---|---|---|
| **C1** | **Pick-Abstraktion + stabile `CatalogObjectID` + PortRegistry** (generisch, Inhalts-Art ∩ Recht). Pick trägt echten Inhalt (lazy resolve). | Fundament — zuerst |
| **C2** | **Erste native Ports:** Dokument (Briefpapier→PDF, nutzt MykPDFRenderer) · Moodboard (ImageRenderer) · Firefly-Prompt (Claude-Vision). Nativ zuerst, Adobe-Pro später (§5h). | C1 |
| **C3** | **WorkBasket-Ausbau:** `inhaltsArt`, Projekt-Zuordnung/Versionierung, Sortieren/Filtern — ohne Artikel-only-Hardwiring. Verallgemeinert `CartStore`. | C1 |
| **C4** | **sevDesk-Postbox-Port + Lebenszyklus + Cash-Widget-Neufassung** (§5i/§5j): Postbox-Schema, Ein-/Ausgangs-Postbox, State Machine, Nachträge/Gutschrift-Kette, doppelte Bestätigung. | C1–C3 |

**Rechte-Schicht (D1)** — Admin-Port-Rechte + per-User Clockodo/ClickUp — läuft parallel/danach und
schaltet den User-Recht-Teil des PortRegistry-Filters scharf.

---

## 10. Rails (eiserne Regeln der ganzen Wirbelsäule)

- **Append-only überall.** Nie löschen, nie editieren, nie überschreiben — Inaktivierung per Status.
- **Stabile Katalog-IDs sind unveränderlich** — nie weitergeben/kopieren/ändern.
- **sevDesk nie direkt** (weder Read noch Write) — nur über Einweg-Postboxen.
- **Karte → Bestätigung → Audit** für jeden externen Write; sevDesk doppelt.
- **Rechte-Gate:** Ports erscheinen nur bei Inhalts-Art ∩ User-Recht.
- **Persistenz:** GRDB-Migration nur anhängen; Cold-Start-Test für jedes neue persistierbare Feature.
- **Secrets nur Keychain**; externe IDs = Referenzen, nie Primärschlüssel.
- **Kein Artikel-only-Hardwiring** — die Generalisierung nie verbauen.

---

## 11. Offene Entscheidungen (an Johannes — vor/während C4)

1. **EK in die sevDesk-Postbox?** (Marge sichtbar für den Abholer — bewusst?)
2. **ID-Schema:** UUID (maschinell) vs. sprechend (`WK-‹Projekt›-‹Zeitstempel›-‹Kurzhash›`).
3. **Positionen-Ablage:** Kopf-Record + verlinkte Positions-Records (empfohlen) vs. ein Record.
4. **„Bestätigt"-Rückweg:** Status-Feld auf dem Postbox-Record vs. eigener Bestätigungs-Record.
5. **Ketten-Rechnung:** wie Nachträge/Gutschriften den gültigen Projektwert bilden.
6. **Weitere Postboxen** je Port (Moodboard/Geräteliste/…) — je Port beim Bauen definieren.
7. **Gutschrift** — eigenes späteres Kapitel.

---

## 12. Was heute schon steht (Andockpunkte)

- `CartStore` + Warenkörbe (Artikel, append-only, `version`) — der WorkBasket-Keim.
- `AIRTABLE_WARENKORB_SENDEN` — ein erster Port-artiger Write (Warenkorb → Airtable), gated + audited.
- `writableMap`-Whitelist im `AirtableClient` — die Postboxen kommen hier drauf.
- `MykPDFRenderer` / Briefpapier-Assets — Dokument-Port-Renderer.
- `KalkulationsEngine` — Kalkulations-Port.
- `DataFlowLogger` + `WriteShadowRecorder` + `AuditStore` — die Instrumentierungs-Dreifalt aus §8.

---

*Nächster Schritt nach Bestätigung dieses Blueprints: C1 (Pick + PortRegistry + stabile IDs) —
das Fundament, auf dem alles andere steht.*
