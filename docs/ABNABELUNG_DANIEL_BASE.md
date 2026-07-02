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

**Kernbefund:** Die Ziel-Bases existieren als **Hüllen**, aber die Empfangs-Tabellen (Artikel/
Preisliste, Kunden, Projekte, Warenkörbe, Projektartikel, Lagerliste) sind **noch nicht gebaut.**
Die Abnabelung ist deshalb eine echte **Migration**, kein Konstanten-Tausch.

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
