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

## 4. Offene Entscheidungen (Johannes — vor dem Bau)

1. **Live-Sync oder harte Abnabelung?** Soll die **Preisliste** weiter periodisch von Daniel
   gespiegelt werden (read-only Sync, Preisänderungen kommen an) — ODER **harter Schnappschuss**
   (einmal kopieren, danach pflegt mykilOS die Preise selbst, keine Daniel-Abhängigkeit mehr)?
   „Komplett abnabeln" klingt nach hart — aber Preis-Aktualität klären.
2. **Ziel-Base-Zuordnung:** Vorschlag — Artikel/Preisliste → `mykilOS_Handelswaren`; Kunden+Projekte
   → `mykilOS_Projekte`; Warenkörbe+Projektartikel → `mykilOS_Onlineshop & Verkauf`; Intake-Neuanlagen
   → `mykilOS_Fragebogen & Projekt IN`. Passt die Aufteilung?
3. **Bestehende Test-Warenkörbe in Daniels Base** (Screenshot): migrieren, oder einfach dort lassen?
   (Löschen wäre ein Write in Daniels Base — machen wir nur mit seiner ausdrücklichen Erlaubnis,
   und Löschen ist ohnehin generell tabu.)
4. **Business-Wahrheit vs. Mastermind-Routing:** bleibt die `ExternalMappingRegistry`-Reconciliation
   bestehen, oder wird nach der Abnabelung EINE gemeinsame mykilOS-Projekt-Wahrheit daraus (dann
   entfällt das Titel-Matching)? Größere Architektur-Frage, evtl. eigener Schritt.

**Bau erst nach Bestätigung dieser 4 Punkte** — dann als delegierter Worker (Schema-Anlage +
Migration + Umverdrahtung + Verifikation), nicht blind über Nacht. Migration ist datenkritisch.
