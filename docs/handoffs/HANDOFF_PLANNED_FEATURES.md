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

> **✅ PDF GELIEFERT (2026-06-30).** Vollständig entschlüsselt + geordnet in
> **[HANDOFF_PROJEKT_INTAKE.md](HANDOFF_PROJEKT_INTAKE.md)** — der maßgebliche Bau-Vertrag für den
> umfangreichen Modus (24 Sektionen, Mapping Kunde/Projekt+Ordner/Erst-Warenkorb, Geräte→Artikel-Picker,
> lokaler Artikel-Spiegel). Diese Sektion hier ist nur noch die Kurzfassung.

- **Simple:** wenige Felder (Projektname, Kunde, Status) → schneller Projekt-Anlage-Record.
- **Umfangreich:** der **Küchen-Projekt-Fragebogen** aus dem Erstgespräch. Erzeugt in EINEM Durchlauf
  **Kunde + Projekt (mit Drive-Ordner-Schema) + Erst-Warenkorb + erste Preisschätzung**. Geräte-Sektionen
  bieten je eine **konkrete Artikel-Auswahl** (gefiltert nach Geräteklasse €/€€/€€€) **plus Freitext**.
- **Assets vorhanden:** `Archiv.zip → Linienzeichnungen_Fragen/` enthält die **Strichzeichnungen** zu den
  Optionen (Armatur-Formen, Schubladen-Bedienung, Möbelkörper, Spülbecken-Bauart …) — ideal als
  Option-Illustrationen in der geführten Maske.
- Ziel-Tabelle: `Projekte` (`appdxTeT6bhSBmwx5` tblOXF9Cv8Jze6595, hat die Sevdesk-/Make-Felder) ODER
  Mastermind-Projekte — **vor Bau klären, welche Projekt-Tabelle führend ist**. Für den Warenkorb→Sevdesk-Fluss
  ist die Artikel-DB-`Projekte` die richtige.
- **Offen für Johannes:** (1) welche Projekt-Tabelle führt, (2) Drive-Ordner-Unterordner-Schema bestätigen.

## FEATURE C — Warenkorb → Projekt + Warenkorb-Widget auf der Projekt-Detailseite

**Fluss:**
1. In Kataloge einen Warenkorb zusammenstellen (existiert ab 7.7.0) → **„In Projekt schreiben"**:
   schreibt den Warenkorb als `Warenkörbe`-Record (append-only, versioniert) **und** als verknüpfte
   `Projektartikel` ins gewählte Projekt.
2. **Warenkorb-Widget (Einkaufswagen-Icon)** auf der **Projekt-Detailseite im Tab „Übersicht"**
   (`ProjectDetailView` / Übersicht-Board): kompakte Kachel mit **Einkaufswagen-Icon** + Kurzinfo des
   **aktuellsten** Warenkorbs (Bezeichnung, Positionsanzahl, Summen EK/VK, Datum/Version). Alle Renderstates.
   - **Klick → öffnet den aktuellsten Warenkorb als Tabelle**, klickbar: je Zeile Artikelnummer · Bezeichnung ·
     Hersteller · Menge · EK · VK · Zeilensumme; Fuß = Summen. Zeilen klickbar → Artikeldetail/Vorschau.
   - **Versions-Auswahl:** mehrere **vergangene Warenkörbe** des Projekts wählbar (Liste/Dropdown nach
     Version/Datum — aus den `Warenkörbe`-Records desselben Projekts/derselben Prüfsumme).
   - **Differenz-Markierung (rot):** in der Vorschau einer Version werden **Unterschiede zur vorherigen
     Version ROT markiert** — **neue** Positionen, **entfernte** Positionen, **geänderte** Menge/Preis.
     Vergleich über den vollständigen `Positionen (JSON)`-Snapshot je Version (Diff-Schlüssel: Artikelnummer;
     verglichen werden Vorhandensein + Menge + VK). Read-only — der Diff ändert nie Records.
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

## FEATURE D — Export: Fragebogen & Warenkörbe als PDF / CSV

**Wunsch (Johannes, 2026-06-30):** Nach dem Ausfüllen soll der **Projektfragebogen** als **PDF oder
Excel/CSV** exportierbar sein; ebenso **Warenkörbe** nach Bedarf.

- **Warenkorb-Export (klein, zuerst):**
  - ✅ **CSV (gebaut 2026-07-07):** `WarenkorbCSVExporter` (Sources/MykilosApp/, reine testbare
    String-Erzeugung, 13 Tests) + „CSV"-Knopf im Warenkorb-Panel (NSSavePanel, rein lesend).
    Spalten: Pos./Artikelnummer/Bezeichnung/Lieferant/Kategorie/Quelle/Menge/EK-Einzel/VK-Einzel/
    VK-Summe + Kopf (Datum, Positionsanzahl) + VK-Summenzeile. Semikolon-getrennt (dt. Excel),
    RFC-4180-Escaping, UTF-8-BOM, dt. Komma-Preise, unbekannte Preise leer (nie erfundene 0,00).
    Lieferant/Kategorie aus den verifizierten `attribute`-Keys (`lieferant`/`kategorie`).
    **Ehrliche Abweichung vom Plan:** Kopf ohne „Version" (der Session-Warenkorb im Panel trägt
    keine Versionsnummer — nur der projektgebundene WorkBasket); Projekt-Kopfzeile optional (wird
    nur geschrieben, wenn gesetzt, nichts erfunden).
  - ✅ **PDF (gebaut 2026-07-07):** `WarenkorbPDFExporter` (reuse `MykPDFRenderer` wie DokumentPort,
    7 Tests inkl. %PDF-Magic-Byte-Check) + „PDF"-Knopf im Warenkorb-Panel (NSSavePanel, rein lesend).
    A4, Terrakotta-Kopf, Positionstabelle (Pos./Artikelnummer/Bezeichnung/Menge/EK-Einzel/VK-Einzel/
    VK-Summe — schlanker als CSV für Druckbreite), Summen EK/VK netto. **Belegführung (eiserne Regel):**
    Fußnote „Kalkulations-Vorschau — kein offizielles Angebot" — mykilOS stellt nie einen Beleg aus.
  - **CSV (Ursprungsplan):** eine Zeile je Position aus dem `Positionen (JSON)`-Snapshot (Artikelnummer, Bezeichnung,
    Hersteller, Kategorie, Menge, EK, VK, Summe) + Kopf (Bezeichnung, Projekt, Datum, Version) +
    Summenzeile. Reiner String → `.fileExporter` / Speicherort-Dialog. Excel öffnet CSV direkt.
  - **PDF:** druckbare Tabelle (mykilOS-Stil, Logo, Kopf, Positionsliste, Summen EK/VK) via
    SwiftUI→`ImageRenderer`/`NSPrintOperation` oder `PDFKit`. Read-only Snapshot, kein Airtable-Write.
  - **Wo:** Button „Exportieren ▾" (CSV / PDF) im Warenkorb-Panel und im neuen **Warenkörbe-Tab** (je Zeile).
  - Passt natürlich an den Warenkörbe-Tab aus Webshop-Phase 4 — dort als kleiner Folgeschliff einbauen.
- **Fragebogen-Export (mit Feature B):**
  - **PDF:** der ausgefüllte Bogen als sauberes Dokument (alle 24 Sektionen + Auswahl/Freitext + Erst-Warenkorb
    + Schätzung) — das Beratungs-Protokoll zum Mitgeben/Ablegen. Optional in den Projekt-Drive-Ordner.
  - **CSV/Excel:** flache Schlüssel-Wert-Liste (Sektion · Feld · Wert) für Weiterverarbeitung.
  - Baustein gemeinsam mit Warenkorb-PDF: ein wiederverwendbarer `MykPDFRenderer` (Kopf/Logo/Tabelle/Summen).
- **Regeln:** rein lesend, keine Airtable-Mutation. Datei-Schreiben über System-Speicherdialog
  (`.fileExporter`), kein stiller Download. Token-Disziplin im UI.

## Reihenfolge (Vorschlag, bruchsicher)
1. Feature A („+"-Masken) — abgegrenzt, sofort nützlich.
2. Feature C (Warenkorb→Projekt + Widget) — baut auf 7.7.0-Warenkorb auf.
3. Feature D **Warenkorb-Export** (CSV zuerst, dann PDF) — klein, an Phase-4-Warenkörbe-Tab andocken.
4. Feature B (Projektfragebogen, siehe HANDOFF_PROJEKT_INTAKE.md) + **Fragebogen-Export** — wartet auf
   Projekt-Tabellen-Entscheidung (siehe [AIRTABLE_DATENFLUSS_AUDIT.md](../AIRTABLE_DATENFLUSS_AUDIT.md) §3).
