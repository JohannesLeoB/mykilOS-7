# HANDOFF — Geplante Features (Idea-Log mit Bau-Anweisungen)

```
Stand:   nach mykilOS 7.7.0 — geplant, NOCH NICHT gebaut.
Zweck:   Präzise Vorstellung von Fenstern/Widgets/Masken, damit jede Session/Codex direkt bauen kann.
Regeln:  AGENTS.md gilt. Alle Airtable-Writes gated (Bestätigung→Audit), CREATE/PATCH, NIE DELETE/Overwrite.
```

## FEATURE A — „+"-Anlegen-Button in Kataloge

**Was:** Oben in `KatalogeView` (neben Suche/Warenkorb) ein **„+"-Button**. Klick öffnet ein
kleines **Untermenü** (Menu/Popover) mit „Was neu anlegen?":
- **Kunde**
- **Projekt** → Unterauswahl **Simple** | **Umfangreich** (siehe Feature B)
- **Artikel** (Artikel-DB `appdxTeT6bhSBmwx5` / `Artikel` tbl3dAbQtbF51wb4a)
- **Kontakt** (Mastermind `Kontakte` tblncfQzQa8TzCZQC — nutzt bestehenden `AirtableContactDraft`-Pfad)
- **Lagerartikel** (`Lagerliste` tblh8j1Rykv12T2Dx)
- (erweiterbar: Notiz, Aufgabe …)

**Wie die Masken funktionieren:** Je Eintrag öffnet ein **dezidiertes Sheet** (eigene View je Entität),
voll funktional, mykilOS-Stil (MykColor/MykSpace/Font.myk…), alle Felder der Zieltabelle:
- Pflichtfelder markiert, Validierung vor dem Speichern.
- Speichern → **Bestätigungs-Schritt** → `AirtableClient.createRecord(...)` (gated) → AuditEntry → Erfolg/Fehler sichtbar (SaveState).
- **Nur CREATE** (append), nie Delete/Overwrite. Nach Erfolg: Mask schließen + betroffenen Store refreshen (z. B. `LagerlisteStore.reload()`).
- Wiederverwendbares Muster: ein generischer `CreateEntitySheet`-Rahmen + pro Entität ein Feld-Schema. Pro Zieltabelle die Whitelist in `AirtableClient.writableMap` ggf. erweitern (eng halten!).

**Felder je Maske (Startpunkt, gegen echte Tabellen verifizieren):**
- *Kunde:* Nachname, Vorname, Firma, E-Mail, Telefon, Adresse (Straße/PLZ/Ort).
- *Artikel:* Artikelnummer, Hersteller, Kategorie, Artikelbeschreibung, EK netto, (VK MYKILOS wird per Formel berechnet — nicht schreiben).
- *Kontakt:* nutzt `KontaktDetailSheet`-Logik (existiert) im Anlege-Modus.
- *Lagerartikel:* Bezeichnung, Kategorie, Hersteller, Artikelnummer, Bestand, EK/VK, Quelle, Notiz.

## FEATURE B — Projekt anlegen (Simple / Umfangreich) + Artikel-Verknüpfung

- **Simple:** wenige Felder (Projektname, Kunde, Status) → schneller Projekt-Anlage-Record.
- **Umfangreich:** **großer Projektfragebogen** — Johannes liefert die genaue Feldstruktur als **PDF**
  (TODO: PDF einlesen, Felder ableiten). Der Fragebogen wird **direkt mit der Artikelliste verknüpft**:
  beim/aus dem Projekt heraus können Artikel (aus Shop/Lager) als Projektartikel gesammelt werden.
- Ziel-Tabelle: `Projekte` (`appdxTeT6bhSBmwx5` tblOXF9Cv8Jze6595, hat die Sevdesk-/Make-Felder) ODER
  Mastermind-Projekte — **vor Bau klären, welche Projekt-Tabelle führend ist** (es gibt zwei: Drive-geroutete
  Mastermind-Projekte vs. Artikel-DB-Projekte mit Sevdesk-Pipeline). Für den Warenkorb→Sevdesk-Fluss ist die
  Artikel-DB-`Projekte` die richtige.
- **Offen für Johannes:** PDF des Fragebogens schicken + entscheiden, welche Projekt-Tabelle führt.

## FEATURE C — Warenkorb → Projekt + Warenkorb-Widget auf der Projekt-Detailseite

**Fluss:**
1. In Kataloge einen Warenkorb zusammenstellen (existiert ab 7.7.0) → **„In Projekt schreiben"**:
   schreibt den Warenkorb als `Warenkörbe`-Record (append-only, versioniert) **und** als verknüpfte
   `Projektartikel` ins gewählte Projekt.
2. **Warenkorb-Widget** auf der **Projekt-Detail-/Übersichtsseite** (`ProjectDetailView`): zeigt die
   aus Airtable geführten Warenkörbe/Projektartikel des Projekts — **klickbar, mit Vorschau** (Positionen,
   Mengen, Summen EK/VK).
3. **Editieren am Widget** → führt **zurück nach Kataloge**, wo der Warenkorb bearbeitet/geändert/gelöscht
   und **wieder gespeichert** werden kann.
   - **WICHTIG:** „löschen/ändern" im UI heißt **NIE** echtes Editieren/Löschen der Airtable-Warenkorb-
     **Archivliste**. Append-only bleibt: eine neue Version wird angelegt (Status `Aktuell`), die alte auf
     `Archiviert` gesetzt (PATCH Status, kein DELETE). „Löschen" = letzten Stand archivieren / leere
     Folgeversion, nie Record-Löschung.

**Datenanforderung (hart):** **Jeder Warenkorb muss ALLE Artikeldaten aus der Preisliste enthalten** —
also einen vollständigen Snapshot je Position (Artikelnummer, Bezeichnung, Hersteller, Kategorie,
EK, VK, Menge, ggf. Record-ID/Bild-Link), nicht nur eine Referenz. So bleibt der Warenkorb auch dann
korrekt lesbar/anzeigbar, wenn sich der Katalog später ändert. Das `Positionen (JSON)`-Feld der
`Warenkörbe`-Tabelle ist dafür da — vollständig befüllen.

**Bausteine (vorhanden):** `Warenkorb`/`WarenkorbItem`, `CartStore.sendWarenkorbToAirtable` (append-only),
`AufLagerMatcher`, `ArtikelKatalogStore`, `LagerlisteStore`. Neu: Projekt-Detail-Warenkorb-Widget +
„In Projekt schreiben"-Pfad + „aus Widget editieren → Kataloge"-Rückweg.

## Reihenfolge (Vorschlag, bruchsicher)
1. Feature A („+"-Masken) — abgegrenzt, sofort nützlich.
2. Feature C (Warenkorb→Projekt + Widget) — baut auf 7.7.0-Warenkorb auf.
3. Feature B (Projektfragebogen) — wartet auf Johannes' PDF + Projekt-Tabellen-Entscheidung.
