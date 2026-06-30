# HANDOFF — Webshop · Lager · Angebote (in Kataloge integrieren)

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Basis:  main (v7.6.9) — sauber, 514 Tests grün, Repo aufgeräumt
Modell: Sonnet 4.6 (Bau), Opus für Phase 1 (Whitelist/Datenmodell, sensibel)
Datum:  2026-06-30
```

> ⚠️ Der veralteten `CLAUDE.md` NICHT trauen. Lebender Stand: Memory + dieser Handoff.
> **Leitsatz: NICHT kaputt machen.** Jede Phase einzeln: build + swift test grün → eigene DMG →
> Live-Check durch Johannes → erst dann nächste Phase. Das bestehende, schöne mykilOS-Layout bleibt.

## Auftrag (Johannes, 2026-06-30)
Webshop (HTML-Prototyp), Lagerliste (DEGELA) und der Sidebar-Tab „Angebote" wandern als **Unter-Tabs
in „Kataloge"** — nahtlos im mykilOS-Stil (Tokens, keine Gold/Dark-HTML-Optik). Ein **listenübergreifender
Warenkorb** (Artikel + Lager + Geräte) wird über eine kleine Eingabemaske nach Airtable geschrieben.

## Entscheidungen (bestätigt)
- **Artikel-DB `appdxTeT6bhSBmwx5`:** read-only → **gated write** (Projektartikel, Lagerliste, Warenkörbe).
  IMMER Bestätigung+Audit, NIE Delete/Overwrite. Sevdesk läuft NICHT über mykilOS, sondern über die
  Airtable-Checkbox „Angebot an sevDesk senden" → Make.com.
- **Geräteliste:** lokale CSV → **Live-Airtable** (`Artikel` tbl3dAbQtbF51wb4a). Eine Quelle.
- **Lagerliste-Ziel:** Base `appdxTeT6bhSBmwx5`, neue Tabelle.
- **Webshop-UI:** KEINE API-Key/Base-ID-Felder (kommt aus den Einstellungen, Airtable ist schon verbunden).
- **Angebote:** „Alle Angebote" behält die Sortierung **eingehend | ausgehend in zwei Spalten**.

## Tabellen-IDs (appdxTeT6bhSBmwx5)
Artikel `tbl3dAbQtbF51wb4a` · Projekte `tblOXF9Cv8Jze6595` · Projektartikel `tblirHIicPP3qdcDp` · Kunden `tblImZ3fKYBXBT7Wb`

---

## PHASE 1 — Datenfundament (KEIN UI-Risiko, kann das Layout nicht brechen)
**Modell Opus (sensibel: Schreib-Whitelist + Datenmodell).**
1. **AirtableClient gated-write erweitern:** zweite schreibbare Base `appdxTeT6bhSBmwx5` mit enger
   Tabellen-Whitelist (`Projektartikel`, `Lagerliste`, `Warenkörbe`). Bestehende Mastermind-Whitelist
   unangetastet. NUR create/PATCH, NIE delete. Tests für die Whitelist-Grenzen (fremde Base/Tabelle wirft).
2. **Lagerliste importieren** (einmalig, ~175 Positionen aus DEGELA LAGER.xlsx → neue Tabelle `Lagerliste`):
   Spalten: Bezeichnung (primär), Kategorie, Hersteller, Artikelnummer, Bestand, EK netto (€), VK netto (€),
   Quelle (Geräte/Produkte/Studio Hamburg), Notiz. Nur CREATE. **Vorher die exakte Tabelle Johannes zeigen.**
3. **`Warenkörbe`-Tabelle** anlegen (append-only Datenmodell, s. u.).
**Gate:** build + test grün. DMG. Kein UI verändert.

## PHASE 2 — Geräteliste → Live-Artikel
1. `DeviceCatalog`/`search_katalog`: Quelle umstellen auf Live-`Artikel` (mit lokaler CSV als Fallback,
   damit nichts bricht wenn Airtable mal weg ist). KalkulationsEngine-`geraetepreis` weiter versorgt.
2. Kataloge „Geräte"-Tab zeigt die Live-Artikel (Bild, Hersteller, Kategorie, Art.-Nr., EK/VK MYKILOS).
**Gate:** build + test grün. DMG. Geräte-Tab + Schätzungen weiter funktionsfähig.

## PHASE 3 — Kataloge-Tabs + Warenkorb + Angebote-Umzug
1. **Kataloge-Unter-Tabs** (verschiebbar, wie bestehend): **Geräte/Artikel · Lager · Angebote** (+ bestehende).
   - **Artikel/Shop:** Live-Artikel mit Suche/Filter (Kategorie/Hersteller/Preis), „+ in Warenkorb".
   - **Lager:** `Lagerliste`-CRUD (gated, Bestätigung), „+ in Warenkorb".
   - **Angebote:** der bisherige Sidebar-Inhalt 1:1 — „Alle Angebote" mit **zwei Spalten eingehend | ausgehend**.
   - `AppModule.offers` aus der Sidebar entfernen (analog zur Mail-Toggle-Lösung sauber rückbauen).
2. **Listenübergreifender Warenkorb** (`CartStore`, lokal): Positionen aus Artikel + Lager + Geräte,
   Menge editierbar, Summen EK/VK.
3. **„An Airtable senden"** — kleine Eingabemaske: Projekt wählen (oder leer) + Bezeichnung. Schreibt:
   - **Append-only Versionierung (harte Regel):** jeder Versand = NEUER Record in `Warenkörbe`. Wird ein
     Warenkorb zum selben Projekt/derselben Prüfsumme erneut geschickt, werden ältere Versionen auf
     **Status = Archiviert** gesetzt (PATCH, kein Delete/Overwrite), der neue auf **Aktuell**. Versionsnummer hochzählen.
   - **Prüfsumme/ID:** wenn KEIN Kundenprojekt/Name angegeben → stabile ID/Prüfsumme generieren und als
     Warenkorb-Kennung speichern (damit Versionen zusammenfinden).
   - Positionen als `Projektartikel` (Artikel-Link + Menge) verknüpft → greift in den bestehenden
     Sevdesk-via-Make-Fluss (Projekte.„Angebot an sevDesk senden").
**Gate:** build + test grün. DMG. Live-Check.

## `Warenkörbe`-Datenmodell (Phase 1, append-only)
- Bezeichnung (primär), Projekt (Link Projekte | leer), Prüfsumme/Kennung (Text), Version (Zahl),
  **Status** (Auswahl: Aktuell / Archiviert), Erstellt-am (dateTime), Gesamt EK/VK, Positionen (Link Projektartikel
  oder eigene Warenkorb-Positionen-Tabelle). NIE Delete, NIE Overwrite — nur CREATE + Status-PATCH.

## Eiserne Regeln
- Token-Disziplin, Schreibvorgänge `throws`, Cold-Start/Backward-Compat-Tests (Lehre: persistierte Typen
  nie ohne tolerantes Decoding ändern). MykilosKit nie SwiftUI/GRDB.
- Airtable: nur CREATE/PATCH, NIE Delete/Overwrite (NO-GO-Regel 6). Mutationen gated → Audit.
- Signierte Commits. **Phasenweise**: nicht alles auf einmal. Jede Phase grün + DMG + Abnahme.
- Webshop-UI nahtlos in mykilOS (keine HTML-Optik, keine Connection-Felder).
