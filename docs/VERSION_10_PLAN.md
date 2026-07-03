# mykilOS — Version 10: Der Plan

**Stand 2026-07-03 · Ausgangspunkt: [VERSION_9_KONSOLIDIERUNG.md](VERSION_9_KONSOLIDIERUNG.md)**
9.0.0 ist ausgeliefert, recovery-safe, 848 Tests grün, signiert. 8.8.0 bleibt der SAFETY-Rückfall.
V9 hat die Fäden sortiert. V10 zieht **einen** davon bis zum Ende.

> **★ Nordstern:** mykilOS = minimal · functional · smart · beautiful.
> Dieser Plan ist unschlagbar durch **Schärfe**, nicht durch Länge. Die kleinste sinnvolle Lösung,
> die funktioniert **und** schön ist. „Final für V10" heißt: ein klar gezogener Schnitt, nicht „alles".

---

## Vision (ein Satz)

**V10 ist der eine Moment, in dem der echte Schneider-Auftrag zum ersten Mal komplett durch mykilOS läuft** —
Fragebogen → Kunde+Projekt → persistierter Warenkorb am Projekt → ein Klick auf „Zum Angebot" → fertiges
MYKILOS-PDF → Cash-Zeile. Aus dem Werkzeugkasten wird „das läuft mein echtes Studio".

---

## Definition of Done (der Schnitt)

V10 ist fertig, wenn der **Schneider-Auftrag EINMAL sauber und live komplett durchläuft**:

1. Intake-Fragebogen ausgefüllt → Kunde + Projekt angelegt.
2. Warenkorb als **WorkBasket am Projekt in GRDB persistiert** (überlebt Neustart — Picks bleiben dekodierbar).
3. Aus dem Korb per **einem Klick** ein Angebots-PDF gerendert (Briefkopf, Positionstabelle, Netto/19 % MwSt/Brutto,
   Angebotsnummer, Datum) und **im Angebote-Tab sichtbar**.
4. Cash-Widget zeigt die **kalkulierte Summe genau dieses Auftrags** (eine Zeile, „kalkuliert").

**Abgenommen wird live durch Johannes gegen Screenshots** — nicht durch grüne Tests allein
(Lehre: Build-grün ≠ Layout-korrekt). Dann: Version 10.0.0 gestempelt, DMG gebaut, 9.0.0 bleibt SAFETY,
Datenstrom-Handbuch + `BENUTZERHANDBUCH.md` + Gedächtnis nachgezogen.

**Kein neues Subsystem.** V10 verdrahtet fast nur schon Gebautes zu **einem** Faden.

---

## Killer-Feature

> **Ein einziger „Zum Angebot"-Knopf im Projekt.**
> Aus dem am Projekt persistierten Warenkorb entsteht mit einem Klick das MYKILOS-Angebots-PDF.
> Der eine sichtbare Moment, in dem sich die ganze gebaute Kette als **durchgängig UND wertig** beweist.

Das PDF ist das erste echte Kundendokument. Hier zählt „beautiful" real: Briefkopf minimal, aber sauber.

---

## Warum genau dieser Schnitt (kurz, ehrlich)

Die Code-Diagnose ist eindeutig — und ich habe sie gegen die Platte geprüft:

- `WorkBasketStore` existiert (C3, GRDB), ist grün — hat aber **null Instanziierungen in `Sources/`**.
  Toter Code, nie an einem echten Fall durchgezogen.
- **Wichtige Korrektur gegenüber dem ersten Entwurf:** Die Migration `v21_workbasket` liegt bereits im
  gemeinsamen Migrator (`GRDBDatabase.swift:410`) und läuft bei **jedem** App-Start. Tot ist der **Swift-Store**,
  **nicht** die Migration. Das reale Risiko ist deshalb der **Codable-Decode alter Rows**, nicht das DDL.
- `Warenkorb` (MykilosKit, Intake/Airtable-Domäne) und `WorkBasket` (Wirbelsäule, GRDB) sind
  **zwei verschiedene Structs**. Das WarenkorbWidget liest heute aus dem Airtable-`WarenkorbListeStore`,
  nicht aus dem GRDB-Store. „Einfach verdrahten" unterschätzt das — es braucht einen echten kleinen
  **Warenkorb→WorkBasket-Bridge** und einen **WorkBasket→Render-Args-Mapper**.
- `MykPDFRenderer.render(title:subtitle:sections:table:totals:)` ist schema-agnostisch und kennt
  Warenkorb nicht → der Mapper ist Pflicht, aber reine, testbare Foundation-Logik.

Der unschlagbare Schnitt ist deshalb nicht Fähigkeit, sondern **Verbindung**: der kürzeste Pfad von
„Werkzeugkasten" zu „trägt einen echten Auftrag", mit dem Schneider-Fall als **binär prüfbarem Gate**.

---

## Die Phasen (mit DMG-Rhythmus)

Reihenfolge bewusst **umgestellt** gegenüber dem ersten Entwurf: **Schneider zuerst beweisen.**
Die per-User-Keychain-Härtung ist richtig und fällig — aber sie invalidiert alle Tokens (team-weiter
Re-Consent), braucht einen stabilen `userID`, den es im Code noch **nicht** gibt, und ermöglicht den
Schneider-Beweis nicht. Sie kommt deshalb als **abgestimmter Folge-Block**, nicht als Pflicht-Eröffnung
vor dem Rückgrat. Ein Gerät, ein Nutzer, lokale Identität — der Beweis läuft ohne sie durch.

### Phase 1 — Rückgrat verdrahten: der Korb lebt am Projekt
**Ziel:** `WorkBasketStore` hört auf, toter Code zu sein — er hängt in `AppState`, das Intake-Ergebnis
landet als persistierter WorkBasket am Projekt, und man sieht ihn.

- **Block C — WorkBasketStore an AppState verdrahten.** In `AppState.bootstrap()` mit der geteilten
  `GRDBDatabase` instanziieren; `speichere` / `lade` / `alle(projektNummer:)` an die UI exponieren.
  Kein neuer Store, nur Anschluss.
  **Gate:** Roundtrip-Test — Korb schreiben → App neu → **identisch**, Picks (`snapshotJSON`/`inhaltJSON`)
  bleiben dekodierbar. Plus ein Cold-Start gegen eine **per Hand geschriebene alte Row**
  (Codable-Gedächtnisverlust-Lehre: additiv, `decodeIfPresent ?? default`).
- **Block D — Warenkorb→WorkBasket-Bridge.** Der verifizierte Knackpunkt. Kleiner expliziter Mapper:
  Intake-`Warenkorb`-Positionen → WorkBasket-Picks, `status = .kalkulation`, gebunden an `projektNummer`
  (Pflichtfeld, indexed, notNull). **Kein Fuzzy-Match — Projektnummer nie raten.** Schneider-Fall als Testdaten.
- **Block E — Warenkorb im Projekt sichtbar + editierbar.** Das WarenkorbWidget/-Panel vom
  Airtable-`WarenkorbListeStore` auf den **persistierten WorkBasket** umhängen (eine Quelle der Wahrheit
  im Projekt), Menge/Preis korrigierbar, Save-State sichtbar, alle Renderstates. **Kein Positions-Picker.**
  **UI gegen Screenshots prüfen** (P0-Sidebar-Drift-Lehre), nicht nur Build-grün.

**DMG:** `10.0.0-beta1` (korb-persistiert-am-projekt) · **SAFETY = 9.0.0**

### Phase 2 — Der Killer-Moment: aus dem Korb wird ein Angebot
**Ziel:** Ein Klick verwandelt den persistierten Korb in ein wertiges Kundendokument und macht den
Auftrag finanziell sichtbar.

- **Block F — WorkBasket→Render-Args-Mapper.** Positionen → Tabellenzeilen, **Netto → 19 % MwSt → Brutto**
  → `totals`, MYKILOS-Briefkopf/Adresse + **projektNummer-abgeleitete Angebotsnummer + heutiges Datum**
  → `sections`. Reine Foundation-Logik, unit-testbar. MwSt-Satz **fix sichtbar** ausgewiesen.
- **Block G — „Zum Angebot"-Knopf.** Ein Knopf im Projekt: WorkBasket → Mapper → `MykPDFRenderer.render`
  → PDF **lokal ablegen** + im Angebote-Tab zeigen. **Wichtig / RAIL:** Drive ist read-only — das PDF
  wird **nicht** nach Drive geschrieben; es liegt lokal und der Angebote-Tab liest den lokalen Pfad.
  (Der Tab liest heute aus dem Drive-Ordner — hier wird der lokale Pfad zusätzlich eingespeist,
  keine zweite Render-Pipeline.) **Kein sevDesk-Write, keine Postbox-Live-Anbindung, kein zweiter Renderer.**
- **Block H — Cash-Sicht zeigt DIESEN Auftrag.** Cash-Widget um **eine schlanke Zeile**: Warenkorb-Summe
  (Netto/Brutto) aus dem WorkBasket als „kalkuliert". sevDesk bleibt read-only (Ist-Umsatz) wie bisher.
  **Nur sichtbar machen** — kein Budget-Balken, keine sevDesk-Verknüpfung, keine Schreibkette.

**DMG:** `10.0.0-rc1` (zum-angebot-pdf-cash) · **SAFETY = 9.0.0**

### Phase 3 — Schneider live durchziehen + stempeln
**Ziel:** Nicht bei grünen Tests stehenbleiben. Der echte End-to-End-Lauf ist das Gate.

- **Block I — Echter End-to-End-Lauf.** Intake real ausfüllen, Projekt anlegen, Korb prüfen/korrigieren,
  PDF real erzeugen und ansehen, Cash-Zeile real prüfen. **Live durch Johannes, gegen Screenshots.**
  Bei jedem Bruch: Block C–H nachziehen, **nicht überstempeln**.
- **Block J — 10.0.0 stempeln.** Version → 10.0.0, DMG (`MYKILOS_NO_LAUNCH`) bauen, 9.0.0 bleibt SAFETY.
  Neue Daten-Weichen ins Datenstrom-Handbuch (Airtable `tblaUVftka0GvXzeU`) + `docs/BENUTZERHANDBUCH.md`,
  Gedächtnis nachziehen. **Erst dann „V10 fertig".**

**DMG:** `10.0.0` (final, signiert) · **SAFETY = 9.0.0**

### Folge-Block (abgestimmt, getrennter Branch) — Eine echte Identität
Nicht auf dem kritischen Pfad des Schneider-Beweises, aber das nächste Fundament. Erst mit Johannes ansagen
(Re-Consent), **nie im Nacht-Automode** ausrollen.

- **Vorab — stabiler lokaler `userID`.** First-Run-UUID, in `UserProfile`/`ProfileRecord` persistiert
  (GRDB additiv, `decodeIfPresent ?? neu`). **Ohne ihn** ist per-User-Keychain nicht implementierbar —
  `googleDomain`/`clockodoUserID` sind optional/teils leer und als Schlüssel untauglich.
- **Block A — Per-User-Keychain-Härtung.** Die **6 echten** Keychain-Services
  (google/clockodo/airtable/clickup/sevdesk/claude) von teamweit auf `com.mykilos6.<service>.<userID>`.
  (Der siebte „oauth" ist nur ein DispatchQueue-Label, **kein Secret** — kein Migrationspfad nötig.)
  Cold-Start-Test: User A schreibt Token, User B liest nichts. Re-Consent ist ohnehin fällig.
- **Block B — Anti-Impersonation-Minimalguard** nur **als Test verankert** (geteilte Wissensschichten
  per `userID` gefiltert; Assistent spricht Kollegen nie als wäre er der Nutzer). **Kein UI-/Filter-Ausbau** —
  der volle Datenschutz-Strang ist eine eigene Session.

**DMG:** `10.1.0-alpha1` (per-user-keychain) · **SAFETY = 10.0.0**

---

## Was V10 bewusst NICHT ist

- **Angebots-Positions-Extraktion / Klick-Picker auf PDF** (Flaggschiff, Strang 5) — spektakulärster
  Strang, für **einen** durchlaufenden Auftrag nicht nötig. Größter Scope-Kriech-Reiz → hart nach V11.
- **Abnabelung Phase 2/3** (Mirror + Umverdrahtung von Daniels Base `appdx`) + Multi-Base v2 — der
  Schneider-Auftrag läuft über die **bestehende** Quelle. Eigener großer Strang, nicht in V10.
- **sevDesk-Postbox Live-Schreibpfad** — bleibt read-only/Vorschau. Cash zeigt nur die kalkulierte
  Korb-Summe. Echte Rechnungsbuchung ist V11+.
- **Zentraler Alerts-Strang, Morgen-Brief, native macOS-Push, Spaß-/Delight-Momente** — reife Politur,
  aber eigene Tiefe. Kein Alert liegt auf dem kritischen Pfad **eines** manuell durchgezogenen Auftrags.
- **Volles DSGVO-Paket** (KI-Master-Switch, Datenexport Art. 15/20, Admin-2FA) — V10 nimmt aus der
  Vertrauens-Linse **nur** die per-User-Keychain-Härtung als Folge-Block vorweg. Rest = Strang 3, eigene Session.
- **Generisches Pipeline-Modell** (IO-001…018, PortRegistry-Ausbau, Moodboard/Firefly/CAD-Ports) —
  V10 braucht genau **einen** Port (PDF-Angebot), nicht die generische Maschine.
- **Mail SENDEN, Clockodo-Zeitbuchung, ClickUp Ghost→Live** — Integrationen-Reife. Der Auftrag läuft ohne sie durch.
- **Nachtrag-/Gutschrift-Zweige der Warenkorb-State-Machine** — nur der Happy Path `.kalkulation → sichtbar`.
- **Zweiter PDF-Renderer / mehrseitiges Layout** — der einseitige `MykPDFRenderer` reicht fürs Schneider-Angebot.

---

## Die ersten 3 Schritte für morgen früh

1. **Roundtrip zuerst prüfen (nicht die Migration „erstmals zünden").** Die Migration `v21_workbasket`
   läuft bei jedem Nutzer längst. Der reale erste Test: `WorkBasketStore.speichere` → App-Neustart →
   `lade` **identisch** (Codable-Roundtrip `statusJSON`/`inhaltJSON`/`snapshotJSON`) **plus** ein
   Cold-Start gegen eine **per Hand geschriebene alte Row**. Risiko ist Decode alter Daten, nicht DDL.
   Erst grün, dann weiter.
2. **Block C beginnen.** `WorkBasketStore` in `AppState.bootstrap()` instanziieren (geteilte `GRDBDatabase`),
   `speichere` / `lade` / `alle(projektNummer:)` exponieren. Der eine mechanische Anschluss-Schritt,
   von dem alles Weitere abhängt. `swift build && swift test` grün.
3. **Block D anlegen.** Warenkorb→WorkBasket-Mapper mit dem Schneider-Fall als Testdaten, `status = .kalkulation`,
   `projektNummer` sauber geführt (kein Fuzzy-Match). Damit steht der erste echte Datensatz in der Kette.

---

## Risiken

- **Codable-Decode alter Rows** (nicht DDL): Die Migration läuft schon, aber Bestands-Rows müssen mit dem
  neuen Store dekodierbar bleiben. Pflicht: Roundtrip-Test **und** Test gegen eine alte Row, additiv,
  `decodeIfPresent ?? default`. Ist Schritt 1 überhaupt.
- **Warenkorb vs. WorkBasket sind zwei Structs**, und das Widget liest heute Airtable. Die
  „einfach-verdrahten"-Erzählung unterschätzt Block D+E. Bridge sauber halten, `projektNummer` nicht raten.
- **UI-Layout-Drift:** WarenkorbWidget-Umbau + „Zum Angebot"-Knopf im Projekt-Tab könnten Sidebar/Übersicht
  erneut verschieben (dokumentierter P0). Jede UI-Änderung **gegen Screenshots** prüfen.
- **PDF-Sichtbarkeits-Pfad (RAIL):** Drive ist read-only. Block G legt lokal ab und der Tab liest lokal —
  **nicht** nach Drive schreiben, um Sichtbarkeit zu erzeugen. Sonst RAIL-Bruch oder „im Tab sichtbar" nicht erfüllt.
- **MwSt / Angebotsnummer / Datum** sind für ein echtes Kundendokument **nicht weglassbar**. Fixer sichtbarer
  19 %-Ausweis, abgeleitete Angebotsnummer, heutiges Datum — in Block F/G benannt, damit sie nicht erst
  beim Live-Lauf auffallen und den „ein Klick, fertig"-Moment kippen.
- **Live-Abnahme-Schuld:** Nicht bei grünen Tests stehenbleiben. **Block I ist das Gate, nicht Block J.**
- **Folge-Block A invalidiert alle Tokens** (team-weiter Re-Consent). Deckt sich mit fälligem Re-Consent,
  aber Johannes vorher ansagen; nicht im Nacht-Automode. Deshalb bewusst **nach** dem Schneider-Beweis.

---

## RAILS (im Plan respektiert, nicht verhandelbar)

`main` heilig (kein Push/Force) · externe Writes nur über gated Karte→Bestätigung→Audit · Sevdesk nur via
Postbox (nie direkt) · Airtable nie DELETE, Daniels Base `appdxTeT6bhSBmwx5` nur lesen · Drive read-only ·
ClickUp nur Testspace `90128024109` + Ghost-Personas · Mail/Memos/Assistent nie zwischen Team-Mitgliedern
kreuzlesbar · jede Integration per-User isoliert · jeder Alert braucht Datenschutz-Toggle · Kosten als
Design-Kriterium (lean) · jede Bau-Einheit = kleiner Block + eigenes DMG + SAFETY.
