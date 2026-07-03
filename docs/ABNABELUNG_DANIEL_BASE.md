# Abnabelung von Daniels Artikel- & Einkaufsdatenbank (`appdxTeT6bhSBmwx5`)

**Status: Plan v1 · 2026-07-03 · Audit code-basiert + live verifiziert.** Ziel (Johannes):
mykilOS komplett von Daniels Base abnabeln — die benötigten Daten in mykilOS-eigene Bases routen,
Daniels heutigen Stand nie antasten (Lesen frei, kein Schreiben/Ändern seiner Records).

---

## 1. Ist-Zustand — wie mykilOS heute an `appdxTeT6bhSBmwx5` hängt (verifiziert)

### LIEST von Daniel
| Zweck | Store (Code) | Quell-Tabelle |
|---|---|---|
| **Preisliste / Artikel-Katalog** | `ArtikelKatalogStore` (baseID:46) | Artikel `tbl3dAbQtbF51wb4a` |
| Lagerliste | `LagerlisteStore` | `tblh8j1Rykv12T2Dx` |
| Warenkorb-Liste (Anzeige) | `WarenkorbListeStore` | Warenkörbe `tblhZujm3Ig6hlafX` |
| **Business-Wahrheit** (Kunden + Projekte) | `CachedBusinessRegistry` (`BusinessCustomer`/`BusinessProject`) | Kunden + Projekte |

### SCHREIBT in Daniel (writableMap `AirtableClient.swift:184`)
`Warenkörbe` (`tblhZujm3Ig6hlafX`) · `Projektartikel` (`tblirHIicPP3qdcDp`) · `Lagerliste`
(`tblh8j1Rykv12T2Dx`) · **`Kunden`** (`tblImZ3fKYBXBT7Wb`) · **`Projekte`** (`tblOXF9Cv8Jze6595`)
→ Das **Intake-Fragebogen legt neue Kunden + Projekte direkt in Daniels Geschäfts-DB an** — der
tiefste Haken. Alle Writes append-only/gated, aber sie klittern Daniels Workspace.

### Bestehende Trennung (Kontext)
`CachedBusinessRegistry` (Daniels Geschäfts-Wahrheit) und `CachedProjectRegistry`
(Mastermind-Routing, 31 Projekte aus Drive) sind bewusst getrennt. Verbunden werden sie über
`ExternalMappingRegistry.candidateBindings` (Titel-Match Daniel↔Mastermind, manuell bestätigt,
Integrations-ID `PROJECT_NUMBER_LOCAL_BINDING`). Das ist die „Doppel-Identität"-Reconciliation.

---

## 2. Ziel-Bases — live geprüft (2026-07-03, read-only)

| Base | ID | Zustand |
|---|---|---|
| `mykilOS_Handelswaren` | `appDj4wH4WDQfziDZ` | **leer** (Default „Table 1", kein Schema) |
| `mykilOS_Projekte` | `appWI2qj9cc6Muu3b` | leeres „Table 1" + 1 DEPRECATED Daniel-Mapping-Tabelle |
| `mykilOS_Onlineshop & Verkauf` | `app2XOhOxXfkLtGVC` | (noch nicht geprüft) |
| `mykilOS_Fragebogen & Projekt IN` | `appYE7GnC4bcfTBTX` | (noch nicht geprüft) |
| `mykilOS Mastermind` | `appuVMh3KDfKw4OoQ` | vorhanden (Projekte/Kontakte/Datenstrom-Handbuch etc.) |

**Kernbefund (Stand zum Zeitpunkt dieser Prüfung):** Die Ziel-Bases existieren als **Hüllen**, aber
die Empfangs-Tabellen (Artikel/Preisliste, Kunden, Projekte, Warenkörbe, Projektartikel, Lagerliste)
sind **noch nicht gebaut.** Die Abnabelung ist deshalb eine echte **Migration**, kein Konstanten-
Tausch. → Für den inzwischen gebauten Zustand siehe §7 (Phase 1 GEBAUT, mit Field-IDs).

---

## 3. Abnabelungs-Plan (Phasen)

- **Phase 1 — Ziel-Schema bauen:** in den mykilOS-Bases die Empfangs-Tabellen anlegen (Schema 1:1
  aus Daniels Quell-Tabellen abgeleitet). Zuordnung siehe offene Entscheidung §4.
- **Phase 2 — Read-Daten spiegeln:** Einmal-Migration von Daniels Artikel (Preisliste) +
  Kunden/Projekte + Lagerliste in die neuen mykilOS-Tabellen (read von Daniel = erlaubt).
- **Phase 3 — App umverdrahten:** Store-Konstanten (`ArtikelKatalogStore`/`LagerlisteStore`/
  `WarenkorbListeStore`/`CartStore`/`CachedBusinessRegistry`) auf die neuen Bases/Tabellen zeigen;
  `writableMap`: `appdxTeT6bhSBmwx5` **raus**, mykilOS-Ziel-Bases rein. Intake schreibt Kunden/
  Projekte künftig in mykilOS, nicht Daniel.
- **Phase 4 — Verifizieren:** build+test grün, **keine Schreib-Referenz mehr auf `appdxTeT6bhSBmwx5`**;
  Daniels Base höchstens noch read-only für den (optionalen) laufenden Preis-Spiegel.

---

## 4. Entscheidungen GETROFFEN (Johannes, 2026-07-03)

1. **Preisliste = periodischer Read-only-Mirror** (Johannes delegiert an Claudes Empfehlung).
   Nicht harter Schnappschuss (Preise würden veralten), nicht Live-pro-Request (API-Kosten). Ein
   **geplanter/on-demand Batch-Sync** liest Daniels Artikel `tbl3dAbQtbF51wb4a` **read-only** und
   spiegelt sie in `mykilOS_Handelswaren`. **Die App liest künftig NUR aus `mykilOS_Handelswaren`**
   — voll entkoppelt; der einzige Daniel-Kontakt ist der kontrollierte Sync-Job (read-only, batch,
   schont das 100k-Call-Monatslimit). Preise bleiben aktuell, App ist abgenabelt.

2. **Ziel-Zuordnung:**
   - **Artikel/Preisliste → `mykilOS_Handelswaren`** ✅ (bestätigt).
   - **Warenkörbe routen nach Checkout-Typ in VERSCHIEDENE Listen** (nicht eine Base):
     - **Kreativ-Checkouts** (Moodboard/Firefly/Bilder): in `mykilOS_checkouts` nur **ID +
       Dateinamen + Metadaten + Ordner-Link** des Exports — **keine Binärdaten**. Dem Nutzer
       zusätzlich einen **lokalen Export in einen selbst gewählten Ordner** (ZIP/Bündel) anbieten.
     - **Business / sevDesk / Nachträge / Projektartikel:** in die **Projekt-Ebene des jeweiligen
       Projekts** in **`mykilOS_Projekte` (`appWI2qj9cc6Muu3b`)** = die **Buchhaltungs-Share**.
       Diese muss **sauber dokumentiert** und die bestehende (Make.com/Checkbox-)Lösung **abgelöst**
       werden. Verknüpft mit dem sevDesk-Postbox-Port (WARENKORB_CHECKOUT §5i).

3. **Daniels Projektnummern + Projektstummel-Daten** → nach **`mykilOS_Projekte` transponieren**
   (in unser sauberes System übernehmen). Damit wird `mykilOS_Projekte` die **eine
   Projekt-Wahrheit** — das Titel-Matching der `ExternalMappingRegistry` (Daniel↔Mastermind)
   konvergiert dorthin, statt zwei getrennte Wahrheiten zu pflegen. Kunden-Business-Daten analog.

4. **Test-Warenkörbe in Daniels Base:** bleiben dort (wir schreiben/löschen nicht in Daniels Base);
   Daniel räumt selbst auf, wenn er mag. Kein mykilOS-Eingriff.

**Nächster Schritt:** Bau als delegierter Worker in Phasen (Schema-Anlage in Handelswaren/Projekte/
checkouts → Read-Mirror Daniel→Handelswaren → Projekt-/Nummern-Transposition → App-Umverdrahtung →
Verifikation). Datenkritisch, mit Zwischen-Checkpoints, nicht blind über Nacht.

---

## 5. Quell-Schema Daniels Base (gelesen 2026-07-03, read-only — nur Struktur, KEINE Kundendaten)

- **Artikel** (`tbl3dAbQtbF51wb4a`, Preisliste): Artikelnummer · Hersteller · Kategorie ·
  Artikelbeschreibung · **Netto-VK LISTE** · **Netto-EK** · **Netto-VK MYKILOS** (Formel: Gaggenau
  = EK×1,51, sonst Liste) · Rabattstufe · Preisstand · Produktlink · Produktbild (Attachment) ·
  **Marge** (Formel) · Lieferant · sevDesk-Artikel-ID.
- **Projekte** (`tblOXF9Cv8Jze6595`): ⚠️ **NICHT nur Projektdaten — der ganze sevDesk/Make.com-
  Accounting-Hub.** Checkbox „Angebot an sevDesk senden" → Make.com → sevDesk-Angebot-Entwurf;
  sevDesk-Angebot-/Kostenstellen-IDs; Anzahlung/Abschlag/Schlussrechnung-Tracking (gestellt/erhalten
  + Datumsfelder); Ist-Kosten Material/Montage (Make-Rollups aus Eingangsrechnungen);
  Kostenabweichung-Formeln. + Projektname · Kunde-Link · Status · Budget · Adresse · ClickUp-Lead-ID.
- **Kunden** (`tblImZ3fKYBXBT7Wb`): Nachname/Vorname/Firma · 2× Email/Telefon · Angebotsadresse ·
  Quelle · sevDesk-Kontakt-ID. → **Personendaten (Datenschutz).**
- **Projektartikel** (`tblirHIicPP3qdcDp`): Projekt↔Artikel-Link · Menge · Rabatt% · EK/VK-Lookups.
- **Eingangsrechnungen** (`tbl5jo8Q4NPXsWbmh`), **Lagerliste** (`tblh8j1Rykv12T2Dx`, DEGELA),
  **Warenkörbe** (`tblhZujm3Ig6hlafX`, Positionen-JSON, append-only).

## 6. Ziel-Schema-Design (Vorschlag, NOCH NICHT angelegt)

**🔑 KERN-ERKENNTNIS:** Die gesamte Buchhaltungs-/sevDesk-Logik steckt heute **eingebettet in
Daniels Projekte-Tabelle** (Make.com-Formeln, sevDesk-Checkbox + IDs, Zahlungs-Tracking).
**„Ablösen" heißt: NICHT 1:1 kopieren, sondern sauber neu bauen** — der sevDesk-Übergang läuft
über die **sevDesk-Postbox (§5i)**, nicht über eingebettete Make-Formeln. `mykilOS_Projekte` trägt
die **saubere Projekt-Wahrheit**, die Postbox trägt den Accounting-/sevDesk-Handoff. Das ist der
eigentliche Wert der Abnabelung — die verwachsene Make/sevDesk-Kopplung entwirren.

- **`mykilOS_Handelswaren` → Tabelle `Artikel`** (read-only Spiegel, Batch-Sync): Artikelnummer,
  Hersteller, Kategorie, Beschreibung, VK-Liste, EK, VK-MYKILOS, Marge, Produktlink, Bild,
  Lieferant, Preisstand. VK-MYKILOS/Marge als Airtable-Formel ODER im App-Layer berechnen.
- **`mykilOS_Projekte` → `Projekte`** (clean): mykilOS-Projektnummer, Projektname, Kunde-Link,
  Status, Budget, Adresse, **Daniel-Nummer-Referenz** (transponiert) — **KEINE Make/sevDesk-Formeln**.
- **`mykilOS_Projekte` → `Kunden`** (Personendaten, Datenschutz), `Projektartikel`, `Warenkörbe`,
  `Nachträge` = die **Buchhaltungs-Share** auf Projekt-Ebene.
- **`mykilOS_checkouts`** = Kreativ-Checkout-Index (§5k): ID + Dateiname + Metadaten + Drive-Link.
- **Lagerliste** → mykilOS-eigene (Handelswaren-Base).

**Offen fürs Bauen:** welche Formeln als Airtable-Formel vs. App-berechnet; wie die sevDesk-Postbox
konkret die alte Make-„Angebot senden"-Checkbox ablöst (= der C4/§5i-Bau, eigener Schritt);
aiText-Auto-Felder in den Ziel-Bases löschen (Kosten, siehe Backlog).

---

## 7. Phase 1 GEBAUT (2026-07-03) — angelegte Tabellen + Field-IDs

Schema in allen 3 Ziel-Bases live angelegt (delegierter Worker, verifiziert, keine Records, keine
Schreibvorgänge auf Daniels/verbotene Bases, `Intake — Daniel-DB Zuordnung` unberührt). **Diese IDs
werden in Phase 3 in die Store-Konstanten verdrahtet.**

### `mykilOS_Handelswaren` (`appDj4wH4WDQfziDZ`)
- **`Artikel`** = `tblaIgE0qt4uGUuyT`: Artikelnummer `fld2vmc8y2H4Uel0D` · Hersteller `fldvM5yja0MgJzr0N` · Kategorie `fld23qLpLrZm6JbLd` · Beschreibung `fldT5RAS8QAq7gKrV` · VK-Liste `fldWOFXgSuIUfyPQp` · EK `fldWiTQrbPoETlWyy` · VK-MYKILOS `fldT7VB5XfouuIpXQ` (App-berechnet) · Marge `fldUyOR7mG0qowhuQ` (App-berechnet) · Produktlink `fldhRAbxrgCzfsztu` · Lieferant `fldB8QvlGGVWW4gkm` · Preisstand `fldDuYfQJaWhLHUvm`
- **`Lagerliste`** = `tbliQ4ArjUhpcAyqd`: Bezeichnung `fldaotKN76dkL65Fb` · Menge `fldfLmZIQsuotgtnQ` · Notiz `fldfLQGfhf5OaoSph`

### `mykilOS_Projekte` (`appWI2qj9cc6Muu3b`)
- **`Projekte`** = `tbljXw0CLNhUAH27b`: mykilOS-Projektnummer `fldwHGpWgSER6Rw89` · Projektname `fldBnaNAgqyk9XMZm` · Status `fldDigEHX6WyARR9C` · Budget `fldIiAtngyJoY2Z0t` · Adresse `fldZTM1UzekN4UGz1` · Daniel-Nummer-Referenz `fldrHVVolus8Jw5So`
- **`Kunden`** = `tblj1eOVEsH5nGooD`: Name `fldqaBljXVnZ4fYVT` · Firma `fldBwgbytMMGB4dD8` · E-Mail `fldZRDjyA3Zw9XCn2` · Telefon `fldnxEoGIILHUTCfd` · Adresse `fld7pqLeq9iliC8qd` · Quelle `fldwF9t7erLkacbm8`
- Unberührt: `Intake — Daniel-DB Zuordnung` (`tblTieGBBgrubylRt`, DEPRECATED).

### `mykilOS_checkouts` (`appytOWS4wrxqtpkp`)
- **`Checkouts`** = `tblQvY6PCw113mjCT`: Checkout-ID `fldd7Y76x83RS0Nvf` · Typ `fldQANpMK4UMXbzsA` · Projekt `flddsST3E82ZtQVbo` · Kunde `fldzJKlbzKTnRnhU6` · Zeitstempel `fldRFBBjY1TcieZer` · Drive-Link `fldzNrZ2cuRac7bcp` · Dateiname `fldDAsD8BTIKyIRva` · Summe-EK `fld0wETTogb9nFjtQ` · Summe-VK `fldlURhWNk6u5RuP3` · Status `fldQwZ7Uss9lDZhzH` · Metadaten `fldGSl64DiZ9olE4d`

### ⚠️ Manuell in der Airtable-UI löschen (Template-Reste, per MCP nicht löschbar)
Je Base kam die Default-Tabelle mit Template-Rumpf. **Kostenfalle** = die `Attachment Summary` (aiText). Auch die toten `Notes`/`Assignee`/`Attachments`/`Status (ALT, unbenutzt)`-Felder entfernen:
- Artikel (`tblaIgE0qt4uGUuyT`): `Attachment Summary` `fldoPYiLs8twJn6gj` (aiText) + Notes `fldxvmJ3lr343VWOZ` · Assignee `fldNbPVCa7yS8Ov33` · Status `fldwmU1vaGOPkcwhF` · Attachments `fld2PXosunwu2g1kX`
- Projekte (`tbljXw0CLNhUAH27b`): `Attachment Summary` `fldBD8pzN3xDnSKri` (aiText) + Notes `fldkUldUbopNBk9qw` · Assignee `fldqeqOOBVjZWFiKq` · Status (ALT) `fldrVEcTRywT0VDv1` · Attachments `fldFChtCx6uea7V3A`
- Checkouts (`tblQvY6PCw113mjCT`): `Attachment Summary` `fld0QcmsVjP9RywBS` (aiText) + Notes `fldMRNYrHd39Gjbe7` · Assignee `fldpRAqRQyfcqG6Xv` · Status (ALT) `fldhqt89hHlOeHpRz` · Attachments `fld3INll1io0kjqjy`

**Nebenprodukt:** In `Projekte`/`Checkouts` je ein totes `Status (ALT, unbenutzt)`-Zwillingsfeld (das Default-Template belegte `Status` mit falschen Choices Todo/In progress/Done, und `update_field` kann singleSelect-Choices nicht ändern → neues echtes Status-Feld angelegt, altes umbenannt). Beim manuellen aiText-Löschen gleich mit weg.

**Phase 2 (nächster Schritt):** Read-Mirror Daniels Artikel `tbl3dAbQtbF51wb4a` → `mykilOS_Handelswaren.Artikel` (read-only Batch). Dann Phase 3 (App-Umverdrahtung auf obige IDs) + Phase 4 (Verifikation, keine Schreib-Referenz mehr auf `appdxTeT6bhSBmwx5`).
