# HANDOFF — „Abnahme"-Widget (ausfüllbares Abnahmeprotokoll) · mykilOS 8

```
Quelle:  MYKILOS_Abnahmeprotokoll BLANKO.pdf (3 Seiten) aus dem _BEISPIELORDNER.
Ziel:    Blanko-Protokoll → in mykilOS voll ausfüllbares Formular, vor-konfiguriert je Projekt,
         Ausgabe als PDF (Briefpapier) + Airtable (Projekt + Kunde), in mykilOS klickbar einsehbar.
Muster:  Baut 1:1 auf dem Intake-Fragebogen-Pattern auf (Model → View → IntakeResultBuilder → gated CREATE
         → MykPDFRenderer → Drive). Nichts neu erfinden, das Pattern wiederverwenden.
```

## 1. Was gebaut wird
- **Widget „Abnahme"** auf der **Projekt-Detailseite** (Farbe: neutral/Sage; alle Renderstates).
  Zeigt Status: „noch keine Abnahme" / „Entwurf" / „abgenommen am … (Ergebnis)". Klick → Formular.
- **Formular** (Sheet, voll editierbar): Kunden-/Projektdaten **vorausgefüllt** (aus Airtable Projekt+Kunde),
  aber **überschreibbar**. Alle 3 Seiten als Eingabemasken.
- **Ausgabe (nach Bestätigung):** (a) **PDF mit Briefpapier** + allen Eingaben, (b) **Airtable-Record**
  verknüpft mit Projekt **und** Kunde. Beides **append-only**, Write-Shadow in die Backup-Base (`HANDOFF_TEST_SANDBOX.md` §7).
- **Einsehbar:** geschriebene Abnahmen sind in mykilOS **klickbar** (Liste am Widget) → öffnet die gespeicherte
  Version (read) + „als PDF öffnen". Mehrere Abnahmen je Projekt möglich (versioniert, nie überschreiben).

## 2. Formular-Schema (aus dem PDF — vollständig)

**Seite 1 — Kopf**
- `Projektadresse` (vorausgefüllt: Projekt.Projektadresse), `Auftraggeber*in` (vorausgefüllt: Kunde),
  `Teilnehmer*innen` (Freitext), `Designer | Innenarchitekt` (Freitext, vorausgefüllt: aktueller User/Team).
- **Raum | Bereich** (Mehrfachauswahl): Eingangsbereich · Wohnzimmer · Flur · Schlafzimmer · Gäste-WC ·
  Ankleide · Badezimmer · Gästezimmer · Küche · Kinderzimmer · Esszimmer · Sonstige (+Freitext).
- `Ort | Datum | Uhrzeit der Abnahme` (vorausgefüllt: heute/Projektadresse-Ort, editierbar).

**Seite 2 — Prüf-Checklisten** (je Punkt ein Status: **OK / Mangel / n.z.** + optionale Notiz):
- **LEISTUNGSUMFANG:** Einbauküche · Waschtischmöbel · Einbaumöbel · Wandverkleidung|Heizkörperverkleidung ·
  Türen|Schiebetüren · Sonderbauten · Sonstiges (Freitext).
- **MASSHALTIGKEIT & AUSFÜHRUNG:** Maße gemäß Plan · Fluchten eingehalten · Höhen korrekt · Passungen zu
  Bestand korrekt · Anschlussfugen sauber.
- **OBERFLÄCHEN:** Material gemäß Bemusterung · Farbton korrekt · keine Kratzer|Druckstellen · keine Leimreste.
- **KANTEN & DETAILS:** Kanten|Stöße sauber · Umleimer|Anleimer fest · Gehrungen korrekt · Sichtkanten einwandfrei.
- **BESCHLÄGE & MECHANIK:** Scharniere · Auszüge laufen sauber · Softclose · Push-to-Open eingestellt · Griffe|Knöpfe montiert.
- **TÜREN, FRONTEN & KLAPPEN:** Spaltmaße gleichmäßig · Fronten ausgerichtet · Öffnungswinkel korrekt ·
  Türanschlag korrekt · kein Schleifen/Verkanten.
- **MONTAGE & BEFESTIGUNG:** Möbel standsicher · Wandbefestigung korrekt · Kippsicherung · verdeckte
  Befestigungen sauber · Sockel korrekt montiert.
- **ANSCHLÜSSE & INTEGRATION:** Elektroausschnitte korrekt · Kabeldurchführungen berücksichtigt ·
  Revisionsklappen vorhanden/zugänglich · Ausschnitte passend.
- **SCHUTZ & SAUBERKEIT:** Schutzfolien entfernt · Baustaub gereinigt · Möbel innen sauber · Verpackung entsorgt.
- **DOKUMENTATION:** Pflege-|Reinigungshinweise besprochen · Ersatzteile|Werkzeuge übergeben.

**Seite 3 — Abschluss**
- `MÄNGELLISTE` (Liste/Freitext, je Eintrag Raum+Beschreibung+Frist optional).
- `RESTLEISTUNGEN | NOCH AUSSTEHEND` (Liste/Freitext).
- **ERGEBNIS DER ABNAHME** (Einfachauswahl, Pflicht): „mangelfrei abgenommen" · „Abnahme unter Vorbehalt" · „Abnahme verweigert".
- `HINWEISE | VORBEHALTE DES AUFTRAGGEBERS` (Freitext).
- **UNTERSCHRIFTEN:** Auftraggeber*in (Datum + Unterschrift) · Auftragnehmer*in (Datum + Unterschrift).
  Unterschrift: Touch/Trackpad-Signaturfeld oder „später unterschreiben" (Status offen) — mit Johannes klären.

> Gegen die echte PDF verifizieren (Reihenfolge/vollständige Punktliste) — obige Liste ist aus dem
> PDF-Text rekonstruiert.

## 3. Architektur (Pattern wiederverwenden)
- **`AbnahmeModel`** (`@Observable`, MykilosApp/Abnahme/) — alle Felder oben. Pro Prüfpunkt ein Enum-Status.
- **`AbnahmeView`** (Sheet) — 3 Abschnitte, Chips/Status-Toggles + Freitext, Vorausfüllung + editierbar.
- **`AbnahmeWidget`** (MykilosApp, Projekt-Detailseite) — Status + Liste vorhandener Abnahmen, klickbar.
- **PDF-Ausgabe „mit Briefpapier":** zwei Optionen — (a) **Overlay**: Werte/Häkchen per PDFKit auf die
  **bestehende Blanko-PDF als Hintergrund-Template** zeichnen (höchste Briefpapier-Treue) — empfohlen; oder
  (b) `MykPDFRenderer` um ein Abnahme-Template erweitern. Mit Johannes wählen. PDF → Drive
  (Ordner-Konnektor, z. B. neuer Slot `ABNAHME` oder `01 INFOS`-Unterordner — live klären) + lokal speicherbar.
- **Airtable-Ausgabe:** neue Tabelle **`Abnahmen`** (live mit Johannes anlegen, Artikel-Base), verknüpft auf
  **Projekt** (Record-Link) **und Kunde** (Record-Link): Datum, Ergebnis, Mängel-Anzahl, Teilnehmer, PDF-Link,
  Status, Version. **Nur CREATE/Status-PATCH, nie DELETE.** writableMap eng erweitern.
- **Gating:** Schreiben (PDF-Upload + Airtable) hinter **Bestätigungskarte** → Audit + Write-Shadow-Backup.
  Default in die **TEST-Sandbox**, bis Johannes PROD freigibt.

## 4. Tests (Pflicht)
Model↔Airtable-Feld-Mapping (Feld-NAMEN!) · Ergebnis-Pflichtfeld erzwingt Auswahl · Cold-Start: gespeicherte
Abnahme überlebt Neustart + ist wieder ladbar/anzeigbar · PDF wird erzeugt (nicht-leer) · append-only (neue
Version statt Überschreiben).

## 5. Offene Punkte (LIVE mit Johannes)
- Unterschrift digital (Signaturfeld) vs. „auf Papier, später"? · PDF-Overlay vs. neues Template? ·
  Drive-Zielordner für die Abnahme-PDF (neuer Konnektor-Slot)? · Airtable `Abnahmen`-Tabelle: Felder final?
