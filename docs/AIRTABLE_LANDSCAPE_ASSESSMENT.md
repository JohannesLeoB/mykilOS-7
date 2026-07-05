# Airtable-Landscape-Assessment — Live-Stand vs. 07-01-Snapshot

**Datum: 2026-07-05 · Status: Assessment / Report (kein Live-Eingriff, kein Airtable-Write)**
Autor: Claude (Architektur-Partner) für Johannes.
Vergleich: **Live-Inventar (read-only, 2026-07-05)** gegen die Ist-Landkarte in
[docs/AIRTABLE_ARCHITEKTUR.md](AIRTABLE_ARCHITEKTUR.md) (Snapshot vom 2026-07-01, „24 Bases").

Dieses Dokument bewertet, macht keine Änderungen. Kern-Umbau von Kunde/Projekt bleibt
Johannes- (und bei Daniels Base: Daniel-)Entscheidung.

---

## 0. Die eine große Überraschung zuerst

Der **07-01-Snapshot listet 24 Bases** — der **Live-Zugriff (PAT/MCP) sieht heute nur 3**:

| # | Base | ID | Live sichtbar? |
|---|---|---|---|
| 1 | mykilOS Mastermind | `appuVMh3KDfKw4OoQ` | ✅ |
| 2 | Artikel- & Einkaufsdatenbank (Daniel) | `appdxTeT6bhSBmwx5` | ✅ |
| 3 | mykilos Datenbank Zuliefererpreise Schätzung | `appkPzoEiI5eSMkNK` | ✅ |

Die **anderen ~21 Bases** aus dem Snapshot (mykilOS_Projekte, _Handelswaren, _Onlineshop,
alle 6 Adapter-Bases, Angebote/Rechnungen IN/OUT, Fragebogen IN, 3 Alerts-Bases, Backup,
TRESOR, Datenweichen, App-Entwicklung) **tauchen im Live-Zugriff nicht auf**.

**Das bedeutet nicht zwangsläufig „gelöscht".** Wahrscheinlichste Erklärung: der aktuelle
PAT/MCP-Scope umfasst nur diese 3 Bases (bzw. nur den Workspace, in dem sie liegen). Die
Snapshot-Liste kann aus einem breiteren Zugriff oder aus manueller Bestandsaufnahme stammen.
**Live nicht verifizierbar** — siehe Delta-Abschnitt §5. Bis das geklärt ist, gilt: das
07-01-„24-Bases"-Bild ist **nicht durch den heutigen Zugriff gedeckt**.

Bemerkenswert: die im Snapshot als **TABU/„niemals lesen"** markierte Zuliefererpreise-Base
(`appkPzoEiI5eSMkNK`) ist heute **im Zugriff und wird aktiv genutzt** (V4-Kalkulations-Pipeline,
3.384 Beobachtungen). Das deckt sich mit der CLAUDE.md-Korrektur vom 2026-07-03
(„`appkPzoEiI5eSMkNK` ist NICHT mehr tabu — freigegeben, eigene Base"). Das alte
Architektur-Doc ist an dieser Stelle **veraltet**.

---

## 1. Inventar-Tabelle (live, tabellengranular)

### Base 1 — `mykilOS Mastermind` (`appuVMh3KDfKw4OoQ`)
Rolle: zentrale Schaltzentrale / System-of-Record der App (Routing, Kunden/Projekte,
Clockodo, Kalkulation, Ghost-ClickUp, Datenstrom, sevDesk-Postbox).

| Tabelle | Records | Inhalt/Leer | Anmerkung |
|---|---|---|---|
| Kontakte (`tblncfQzQa8TzCZQC`) | 917 | gefüllt | größte Tabelle; seit 07-01 stark gewachsen |
| Datenstrom-Log (`tbl71AZC9FGWZuDNU`) | 1432 | gefüllt | append-only Sync-Protokoll |
| ClickUp-Ghost-Adapter (`tblJvo4MNd1i1Xl2y`) | 101 | gefüllt | Ghost-Persona-Routing (Testspace-Regel) |
| Kunden (`tblsz4i1CqpBZUE0N`) | 60 | gefüllt | **⚠ Dopplung** mit Daniels `Kunden` (16) |
| Datenstrom-Handbuch (`tblaUVftka0GvXzeU`) | 54 | gefüllt | Weichen-Register (Eiserne Regel) |
| Projekte (`tblGJR13OliFt6Ewi`) | 37 | gefüllt | **⚠ Dopplung** mit Daniels `Projekte` (24) |
| Kundenkontakte (`tblN7RKglX15dmLYe`) | 24 | gefüllt | |
| Polish-Log (`tblberJMgRArGSypE`) | 21 | gefüllt | seit 07-01 neu (nicht im Snapshot) |
| Externe Systeme (`tbl8aoORULVVtphE0`) | 17 | gefüllt | Integrations-Register |
| Clockodo-Leistungen (`tblRtsegocdpM8CJd`) | 10 | gefüllt | Stundensätze teils noch leer |
| Datenqualität (`tblDPVFEzF93JM6SF`) | 8 | gefüllt | seit 07-01 neu |
| Ghost-Personas (`tbl56f2arYm0ynrYx`) | 5 | gefüllt | Jo/Da/Fra/Sen/Jil |
| Clockodo-Nutzer (`tblPbly2br8mR2kaU`) | 4 | gefüllt | |
| TEST-Projekte (`tblj1OXFt0nOqgq0P`) | 2 | Sandbox | nur TEST_-Records; seit 07-01 neu |
| Clockodo-Buchungen (`tblYQxlauwej7FD1w`) | 0 | **leer** | Schema wartet auf erste Buchung |
| Clockodo-EW-Johannes (`tbl4vZ2UFyeTRD8hd`) | 0 | **leer** | persönl. Entwurfstabelle |
| Clockodo-EW-Jilliana (`tblXQIDrvPVN9ijI9`) | 0 | **leer** | persönl. Entwurfstabelle |
| Clockodo-EW-Daniel (`tblNDVve3jjJ9s8HB`) | 0 | **leer** | persönl. Entwurfstabelle |
| Clockodo-EW-Frauke (`tblRrqIQZmm2DosJT`) | 0 | **leer** | persönl. Entwurfstabelle |
| Kalkulationen (`tblO3y2jdmxDnuiZj`) | 0 | **leer** | Schema da, Daten leben lokal/in Zuliefererpreise-Base |
| Kalkulations-Positionen (`tblNamx3cHTus6gtk`) | 0 | **leer** | dito |
| Eingehende-Angebote (`tbliKfs5FnufjdB36`) | 0 | **leer** | wartet auf Import-Pipeline |
| Archiv-Übersetzung (`tblzWwfK2QOEO3mTI`) | 0 | **leer** | Alt-Name ↔ neues Schema, noch ungebaut |
| Postbox-Beleg (`tbluQiYMVllkTS4jQ`) | 0 | **leer** | sevDesk-Postbox-Schema, wartet |
| Postbox-Position (`tblfVRnwgaxvXPfOK`) | 0 | **leer** | dito |
| **Table 1** (`tblvAz5BVtbJxOrWo`) | 3 | Dummy | Airtable-Default, 3 leere Zeilen — **Löschkandidat** |

### Base 2 — `Artikel- & Einkaufsdatenbank` (`appdxTeT6bhSBmwx5`) — Daniels Base
Rolle: Daniels Geschäfts-DB (Artikel/Preise, Projekte, Warenkörbe, Eingangsrechnungen,
sevDesk-Anbindung). **⚠ Bestehende Records = Daniels Hoheit, nie ändern/löschen.**

| Tabelle | Records | Inhalt/Leer | Anmerkung |
|---|---|---|---|
| Artikel (`tbl3dAbQtbF51wb4a`) | 13420 | gefüllt | Kern-Preis-DB; App liest read-only |
| Lagerliste (`tblh8j1Rykv12T2Dx`) | 151 | gefüllt | |
| Projekte (`tblOXF9Cv8Jze6595`) | 24 | gefüllt | **⚠ Dopplung** mit Mastermind `Projekte` (37) |
| Projektartikel (`tblirHIicPP3qdcDp`) | 23 | gefüllt | |
| Kunden (`tblImZ3fKYBXBT7Wb`) | 16 | gefüllt | **⚠ Dopplung** mit Mastermind `Kunden` (60) |
| Warenkörbe (`tblhZujm3Ig6hlafX`) | 14 | gefüllt | |
| Eingangsrechnungen (`tbl5jo8Q4NPXsWbmh`) | 0 | **leer** | Schema da, wartet |

Keine Dummy-„Table 1" in dieser Base.

### Base 3 — `mykilos Datenbank Zuliefererpreise Schätzung` (`appkPzoEiI5eSMkNK`)
Rolle: Kalkulations-/Schätz-Korpus (MYKILOS Kalkulationslabor). **Zwei Generationen:**
alte V1-Tabellen (fast alle leer) + aktive V4-Pipeline (gefüllt).
Hinweis: im 07-01-Doc noch als „TABU, niemals lesen/schreiben" geführt — **inzwischen
freigegeben** (CLAUDE.md 2026-07-03).

| Tabelle | Records | Inhalt/Leer | Anmerkung |
|---|---|---|---|
| V4_MoneyObservations (`tbl1FdVLeBRu0xO2p`) | 3384 | gefüllt | aktiver Korpus |
| V4_PositionCandidates (`tbll0NhjdXbwVG9uk`) | 815 | gefüllt | Positionen extrahiert |
| V4_PageEvidence (`tbl8kchEDamscf1qi`) | 481 | gefüllt | |
| V4_ReviewQueue (`tbla95p3Pgy6dWCAL`) | 339 | gefüllt | |
| V4_SupersededRecords (`tblXpxxsgmuQgBKhU`) | 275 | gefüllt | |
| V4_ActivePriceAnchors (`tblUWNwBKEw3FHFAZ`) | 201 | gefüllt | |
| V4_ComponentAtoms (`tbl0o4OZv7YbrBu80`) | 199 | gefüllt | |
| V4_SourceDocuments (`tblhB4DTXUI6GWCSo`) | 146 | gefüllt | |
| SourceDocuments (`tblBe98BaMk7RH1e2`) | 11 | Rest | V1-Legacy, abgelöst durch V4 |
| ActivePriceAnchors (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| PositionCandidates (V1, `tblrkm9EbP2NddHEG`) | 0 | **leer** | V1-Legacy — ungenutzt |
| ReviewQueue (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| EstimateSessions (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| EstimateAdjustments (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| CalibrationFactors (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| SupersededRecords (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| AuditLog (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| PageEvidence (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| MoneyObservations (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| ComponentAtoms (V1) | 0 | **leer** | V1-Legacy — ungenutzt |
| V4_EstimateSessions | 0 | **leer** | V4-Schema angelegt, noch ohne Daten |
| V4_CalibrationFactors | 0 | **leer** | V4-Schema angelegt, noch ohne Daten |
| **Table 1** (`tblhTmwVg9KQs7Pq1`) | 3 | Dummy | Airtable-Default — **Löschkandidat** |

---

## 2. Die Kommoden-Metapher (Johannes' Bild)

Drei Kommoden im Raum (3 Bases). Nicht 24 — das war eine Inventarliste vergangener Möbel,
die im heutigen Zimmer nicht steht. Was in den drei Kommoden liegt:

### Sauber gefaltet (liegt richtig, greifbar)
- **Mastermind — Betriebswäsche:** Datenstrom-Log/-Handbuch, Ghost-Adapter, Externe Systeme,
  Clockodo-Nutzer/-Leistungen, Kontakte (917). Das ist die Alltagsschublade der App —
  ordentlich, benutzt, wächst.
- **Daniels Artikel-Kommode — die schwere Eichenschublade:** 13.420 Artikel, sauber, seine
  Hoheit. Liegt genau da, wo sie hingehört; wir fassen sie nur mit Handschuhen an (read-only).
- **Zuliefererpreise, V4-Fach:** der destillierte Schätz-Korpus (3.384 + 815 Positionen).
  Frisch einsortiert, in Gebrauch.

### Doppelt in zwei Schubladen (dieselbe Wäsche zweimal) — der Kernschmerz
- **Kunde:** 60 in Mastermind **und** 16 in Daniels Base — zwei Schubladen, zwei Schemata,
  kein Master. Genau die „Entität-Fragmentierung ohne Master" aus dem 07-01-Doc §2.1.
- **Projekt:** 37 in Mastermind **und** 24 in Daniels Base — dieselbe Doppelung. Die Adresse
  liegt reich bei Daniel, dünn bei uns → das „Adresse hängt nicht am Projekt"-Gefühl (§2.4).
- Die Wäsche ist nicht identisch gefaltet (unterschiedliche Felder), und es gibt **keinen
  durchgehenden Etikettenfaden** (Business-Key `Kundennummer`/`Projektnummer` fehlt/uneinheitlich,
  §2.2). Man weiß nicht sicher, welches Hemd in welcher Schublade dasselbe ist.

### Leere Schubladen, die warten (Schema da, Inhalt fehlt)
- **Mastermind:** 11 leere Tabellen — alle 4 Clockodo-EW + Buchungen (warten auf die
  Postbox-Zeitbuchung), Kalkulationen/-Positionen (Daten leben lokal), Eingehende-Angebote,
  Archiv-Übersetzung, beide Postbox-Tabellen. Fertig gezimmerte Fächer, noch nichts drin.
- **Daniel:** `Eingangsrechnungen` (leer).
- **Zuliefererpreise:** die komplette **V1-Generation** (13 leere Fächer) — abgelöst von V4,
  aber noch im Möbel. Totholz.

### Verrutschte Beilage, die keiner braucht
- **2× „Table 1"** (Airtable-Default-Dummy, je 3 leere Zeilen) — in Mastermind und in
  Zuliefererpreise. Das Packpapier, das beim Möbelkauf drin lag. Weg damit.

---

## 3. Ranked Aufräum-Empfehlungen

Verankert an Abnabelung/§8b + Track L: **eine Core-Base als Master, Business-Keys als
Etiketten überall, Daniels Base bleibt read-only Spiegel.** Reihenfolge = billig+risikolos
zuerst, teuer+koordinationspflichtig zuletzt.

**1. (sofort, null Risiko) Die beiden `Table 1`-Dummies löschen.**
`tblvAz5BVtbJxOrWo` (Mastermind) + `tblhTmwVg9KQs7Pq1` (Zuliefererpreise). Reines
Airtable-Default-Rauschen, 3 leere Zeilen, kein Code hängt dran. Der einzige Punkt, den man
guten Gewissens *heute* anfassen könnte — aber Eiserne Regel „kein Airtable-Write in diesem
Auftrag" gilt, also: **als Löschkandidat vormerken, in eigener Mini-Session mit GO ausführen.**

**2. (billig) V1-Generation in Zuliefererpreise stilllegen.**
13 leere V1-Tabellen sind von V4 abgelöst. Erst **verifizieren**, dass kein Code/keine
Pipeline mehr V1 liest (grep auf die V1-Tabellen-IDs), dann per Status-/Archiv-Konvention
kennzeichnen bzw. — da leer und Airtable — nach Bestätigung entfernen. Räumt die dritte
Kommode auf ein einziges klares V4-Fach zusammen. **Nie ohne den grep-Nachweis.**

**3. (Klärung, kostenlos aber wichtig) Den 24-vs-3-Bases-Widerspruch auflösen.**
Bevor irgendein Abnabelungsschritt startet, muss klar sein, ob die ~21 fehlenden Bases
*existieren aber außer Scope* oder *nicht mehr da* sind. Sonst plant man Migration gegen
ein Fantasie-Inventar. Johannes fragen / PAT-Scope prüfen. (Siehe §5.)

**4. (der eigentliche Track L, koordinationspflichtig) Business-Keys als Etiketten überall.**
`Projektnummer`/`Kundennummer` als Textfeld in **beide** Kunden- und Projekt-Tabellen
(Mastermind + Daniel), damit die doppelte Wäsche endlich denselben Etikettenfaden trägt.
Das ist die Voraussetzung für jede saubere basisübergreifende Übergabe (07-01-Doc §3.2, §5).
**Braucht Daniel am Tisch** (seine Base). Kein Solo-Eingriff.

**5. (Zielbild, nach 8.0) Kunde/Projekt entdoppeln → eine Master-Tabelle.**
Entscheiden, welche Schublade die Wahrheit hält. Empfehlung entlang §8b: eigene Core-Tabellen
(App liest+schreibt) für Kunde/Projekt/Warenkorb, Daniels Artikel/Lager als **read-only
Sync-Spiegel**. Strangler-Migration entität-für-entität, nie Big-Bang, nie löschen (nur
Status/Archiv). Das ist der große Umbau — bewusst **nach** dem 8.0-Merge, als ruhiger Strang.

**6. (Pflege, laufend) Leere Warte-Schubladen als „wartend" markieren, nicht als „kaputt".**
Die 11 leeren Mastermind-Tabellen sind gewollt (Schema-vor-Daten). Kein Aufräumbedarf —
aber im Datenstrom-Handbuch als „Schema angelegt, Pipeline offen" führen, damit niemand sie
später für Totholz hält und wegräumt.

---

## 4. Kernprobleme aus 07-01 — heute noch gültig?

| 07-01-Problem (§2) | Live-Stand 07-05 | Gültig? |
|---|---|---|
| 1. Entität-Fragmentierung ohne Master (Kunde/Projekt doppelt) | 60/16 Kunden, 37/24 Projekte — real doppelt | ✅ voll gültig |
| 2. Kein durchgängiger Join-Key (Business-Key fehlt) | live nicht gegengeprüft, aber Doppelung besteht | ✅ wahrscheinlich gültig |
| 3. Zwei-Eigentümer-Problem (Daniel/mykilOS) | Daniels Base separat, read-only-Regel steht | ✅ voll gültig |
| 4. Adresse hängt nicht am Projekt | Mastermind-Projekte dünn, reiche Adresse bei Daniel | ✅ voll gültig |

Die vier Kernprobleme sind **unverändert real.** Der Abnabelungsplan (§8b) und Track L
adressieren sie richtig — das Assessment ändert die Diagnose nicht, es bestätigt sie am
Live-Bestand.

---

## 5. Ehrlicher Delta-Abschnitt

**Was sich seit 07-01 geändert hat (belegt):**
- **Kontakte** in Mastermind massiv gewachsen (jetzt 917 — größte Tabelle).
- **Neue Mastermind-Tabellen** seit Snapshot: Polish-Log (21), Datenqualität (8),
  TEST-Projekte (2), ClickUp-Ghost-Adapter (101), Ghost-Personas (5). Das Ghost-Persona-
  und Datenqualitäts-Instrumentarium ist neu materialisiert.
- **Zuliefererpreise-Base freigegeben:** von „TABU/niemals" (07-01) zu aktiv genutztem
  V4-Korpus (CLAUDE.md 2026-07-03). Das alte Architektur-Doc §1/§7 ist hier **stale** und
  sollte korrigiert werden (Free-Climber-Anker-Prinzip).

**Was unklar bleibt / nicht live geprüft werden konnte:**
- **Der 24-vs-3-Bases-Widerspruch.** Der Live-Zugriff sieht nur 3 Bases. Ob die ~21 anderen
  (Adapter, Angebote/Rechnungen IN/OUT, Alerts, Backup, TRESOR, Projekte/Handelswaren/
  Onlineshop) **existieren aber außerhalb des PAT-Scopes** liegen, oder ob sie **nie in
  diesem Workspace waren / entfernt wurden**, ist **nicht entscheidbar** ohne breiteren
  Zugriff oder Johannes' Bestätigung. **Das ist die wichtigste offene Frage dieses Reports.**
- **Business-Keys:** ob `Projektnummer`/`Kundennummer` heute schon irgendwo als Textfeld
  liegen, wurde **feld-granular nicht geprüft** (nur Record-Zahlen im Inventar, keine
  Schema-Dumps). Für Track L muss das nachgeholt werden.
- **Ob die Kunden/Projekt-Doppelung inhaltlich überlappt** (dieselben 16 Kunden in beiden,
  oder disjunkte Mengen) — nicht abgeglichen. Record-Zahlen sagen „doppelt vorhanden", nicht
  „identischer Inhalt".

**Was dieser Report bewusst NICHT tat:**
- Kein Airtable-Write, kein Löschen, kein Feld-Anlegen (Auftragsgrenze).
- Keine Schema-Tiefenanalyse einzelner Tabellen — nur Rollen-/Inhalts-/Dopplungs-Ebene.
- Keine Entscheidung über den Master — das bleibt Johannes (+ Daniel bei der Artikel-Base).

---

*Quelle Live-Inventar: read-only MCP-Zugriff 2026-07-05 (permissionLevel `create`,
Record-Zahlen aus metadata.totalRecordCount). Quelle Snapshot: docs/AIRTABLE_ARCHITEKTUR.md
(2026-07-01). Kein Live-Eingriff durch dieses Dokument.*
