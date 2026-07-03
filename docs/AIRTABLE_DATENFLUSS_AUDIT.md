# Airtable-Datenfluss-Audit — „Wo schreibe ich was, wie?"

```
Stand:  2026-06-30 (live gegen beide Bases verifiziert via Airtable-MCP + Code-Grep).
Zweck:  Eine verbindliche, nachvollziehbare Karte aller Lese-/Schreibpfade der App nach Airtable.
Regel:  CREATE/PATCH gated (Whitelist), NIE DELETE/Overwrite. Verifiziert: kein DELETE-Pfad im Code.
```

## 1. Zwei Bases — zwei klar getrennte Rollen

| Base | ID | Rolle | Eigentümer |
|---|---|---|---|
| **mykilOS Mastermind** | `appuVMh3KDfKw4OoQ` | **Routing & Schaltzentrale** der App: Projekt→Drive/ClickUp/Kalender/Mail-Verdrahtung, Kontakte, Clockodo, Datenstrom-Log, Kalkulations-Anker. | mykilOS (Johannes/App) |
| **Artikel & Einkauf** | `appdxTeT6bhSBmwx5` | **Backend & Geschäft**: Artikel-Katalog, operative Projekte mit **Sevdesk/Make-Pipeline**, Kunden-Stammdaten, Warenkörbe, Lagerliste. | Backend (Daniel) |

## 2. Vollständige Lese-/Schreib-Matrix (Code-verifiziert)

| Base | Tabelle | App **liest** | App **schreibt** | Code-Pfad |
|---|---|:--:|:--:|---|
| Mastermind | `Projekte` (tblGJR13OliFt6Ewi) | ✅ | — | `AirtableRegistry.sync` ← `registry.syncFromAirtable(baseID: writableBaseID)` |
| Mastermind | `Kunden` (tblsz4i1CqpBZUE0N) | ✅ | — | `AirtableRegistry.sync` (customersTable) |
| Mastermind | `Kontakte` (tblncfQzQa8TzCZQC) | ✅ | ✅ CREATE/PATCH | `AppState.syncKontakte` (lesen) · `AppState.writeAirtableContact` (S19, gated) · `MailClientView` (lesen) |
| Mastermind | `Datenstrom-Log` (tbl71AZC9FGWZuDNU) | — | ✅ CREATE | `DataFlowLogger` (append-only Handshake) |
| Mastermind | `Datenstrom-Handbuch` (tblaUVftka0GvXzeU) | (Doku) | (manuell) | Eiserne Regel: jede Weiche hier eintragen |
| **Artikel** | `Artikel` (tbl3dAbQtbF51wb4a, 13.419) | ✅ | — | `ArtikelKatalogStore.load` |
| **Artikel** | `Lagerliste` (tblh8j1Rykv12T2Dx) | ✅ | ✅ CREATE (geplant „+") | `LagerlisteStore.load` |
| **Artikel** | `Warenkörbe` (tblhZujm3Ig6hlafX) | ✅ | ✅ CREATE + PATCH-Status | `CartStore.sendWarenkorbToAirtable` (append-only, versioniert) |
| **Artikel** | `Projektartikel` (tblirHIicPP3qdcDp) | — | ✅ CREATE | `CartStore` (verknüpfte Positionen) |
| **Artikel** | `Projekte` (tblOXF9Cv8Jze6595) | — | — | **noch NICHT verdrahtet** (s. §4) |
| **Artikel** | `Kunden` (tblImZ3fKYBXBT7Wb) | — | — | **noch NICHT verdrahtet** (s. §4) |

**Schreib-Whitelist (`AirtableClient.writableMap`) — eng & korrekt:**
- `appuVMh3KDfKw4OoQ` → `Datenstrom-Handbuch`, `Datenstrom-Log`, `Kontakte`
- `appdxTeT6bhSBmwx5` → `Lagerliste`, `Projektartikel`, `Warenkörbe`

`createRecord`/`updateRecord` werfen `invalidBaseID`, wenn Base+Tabelle nicht auf der Whitelist stehen.
**Kein `deleteRecord` existiert.** Inaktivierung nur per Status-/Versions-Feld. ✅ sauber.

## 3. ⚠️ Wichtigster Befund: Doppelte Identität bei Kunden + Projekte

> **Status (2026-06-30, mykilOS 8 Block A): Resolver gebaut, Daten-Lücke offen.**
> `ExternalMappingRegistry` (`Sources/MykilosServices/ExternalMappingRegistry.swift`) ist jetzt
> der einzige Join-Punkt — er joint Mastermind-Routing und Artikel-Geschäft ausschließlich über
> die Projektnummer, nie per Namens-Fuzzy-Match. **Live verifiziert (code-grep, nicht nur Doku):**
> der Schreibpfad `AppState.erzeugeKundeUndProjekt` schrieb bisher zwar nach Artikel-`Projekte`,
> der anschließende `registry.syncFromAirtable(...)`-Aufruf synct aber NUR Mastermind — ein neu
> angelegtes Intake-Projekt war dadurch in der App komplett unsichtbar, bis irgendwann ein
> Mastermind-Routing-Eintrag dafür entsteht (was heute nirgends automatisch passiert). Block A
> behebt das für die Registry-Schicht (`syncBusinessRegistry()` läuft jetzt zusätzlich), aber die
> eigentliche Lücke bleibt: **Artikel-`Projekte` hat kein `Projektnummer`-Feld** — neue
> Geschäftsprojekte laufen als `businessOnlyUnbound`, sichtbar über
> `ExternalMappingRegistry.unboundBusinessProjects()`. Schließt entweder Daniel (Feld ergänzen)
> oder Block C (Nomenklatur schreibt die Nummer beim Anlegen mit).

Es gibt **zwei `Kunden`-Tabellen** und **zwei `Projekte`-Tabellen** — je eine pro Base. Sie sind **keine
Duplikate, sondern zwei Schichten**:

| | Mastermind `Projekte` | Artikel `Projekte` |
|---|---|---|
| Zweck | **Routing**: Drive-Ordner-ID, ClickUp-Liste, Mail-/Kalender-/Kontakte-Suche, sevdesk-Ref, Phase | **Geschäft**: Status, Budget, Projektadresse, Projektartikel, Summe EK/VK, Marge, Anzahlung/Abschlag/Schlussrechnung, **„Angebot an sevDesk senden"** (Make.com), Ist-Kosten |
| App nutzt | **liest** (Galerie/Projektliste/Verdrahtung) | (noch nicht) |
| Schlüssel | `Projektnummer` (JJJJ-NR) | `Projektname` + Kunde-Link |

**Das ist die eine fragile Naht.** Solange die App Projekte aus *Mastermind* liest, aber Warenkörbe/
Sevdesk in *Artikel* laufen, müssen beide über die **Projektnummer** verbunden bleiben. Solange niemand
das explizit als Join-Regel führt, ist „welches Projekt ist das echte?" mehrdeutig.

**Empfehlung (Entscheidung Johannes + Daniel):**
- **Routing bleibt Mastermind** (Drive/Mail/Kalender) — das funktioniert.
- **Geschäfts-Wahrheit = Artikel-Base `Projekte`/`Kunden`** (Sevdesk-Pipeline lebt dort).
- **Join-Schlüssel verbindlich = `Projektnummer`.** Wird im **Datenstrom-Handbuch** als eigene Weiche
  (`AIRTABLE_PROJEKT_JOIN`) eingetragen, damit es nachvollziehbar und für Daniel sichtbar ist.
- **Für den Intake (Feature B):** neuer Kunde/neues Projekt → **in die Artikel-Base** schreiben (dort hängen
  Warenkorb + Projektartikel + Sevdesk). Die Mastermind-Routing-Zeile entsteht, wenn der Drive-Ordner angelegt wird.

## 4. „Noch nicht verdrahtet" — bewusst offen
- Artikel-Base `Projekte`/`Kunden` werden noch nicht gelesen/geschrieben → wird mit Feature A/B nachgezogen
  (dann `writableMap[appdxTeT6bhSBmwx5]` um `Projekte`, `Kunden` erweitern — eng halten).

## 5. Aufräum-Kandidat
- Mastermind enthält eine leere Default-Airtable-Tabelle **„Table 1"** (tblvAz5BVtbJxOrWo) — Vorlagen-Müll,
  von keinem Code berührt. Sollte gelöscht werden (Johannes/Daniel im Airtable-UI), damit die Base sauber liest.

## 6. „Die App soll schnell bleiben" — verbindliche Regeln
1. **Nie die UI auf einen Live-Airtable-Fetch warten lassen.** Projekte laufen schon über
   `CachedProjectRegistry` (lokaler Cache, Sync im Hintergrund). Gleiches Muster für Artikel:
2. **Lokaler Artikel-Spiegel** (Entscheidung 2026-06-30, siehe [HANDOFF_PROJEKT_INTAKE.md](handoffs/HANDOFF_PROJEKT_INTAKE.md) §D):
   13.419 Artikel einmal in GRDB cachen, Suche/Picker lesen lokal, **inkrementeller Abgleich** nur über
   `Zuletzt geändert` (`fldd4eeutPgkyRoZ8`). Heilt zugleich den langsam/leeren Artikel/Shop-Tab.
3. **Jeder Sync schreibt einen Handshake** in `Datenstrom-Log` (Dauer-Ms, Mengen, HTTP-Status) — so ist
   Performance messbar und nachvollziehbar.
4. **Paginierung statt Voll-Render** in großen Listen (Artikel/Shop) — kommt mit Webshop-Phase 4.
