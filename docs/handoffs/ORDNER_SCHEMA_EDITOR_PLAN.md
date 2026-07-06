# 📁 Ordner-Schema-Editor — Startplan (Johannes 2026-07-06)

**Ziel (Johannes, wörtlich sinngemäß):** Der **Admin** gibt die **Muster-Projektordner-Struktur
in der App** an. Aus der **Projekt-Anlegen-Maske** heraus werden dann alle neuen Drive-Projektordner
**vollständig, systematisch und mit korrektem Namensschema** nach genau diesem Muster angelegt.

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Regel:  „langsam daran machen" — Fundament steht, eigener fokussierter Strang.
        Echter Drive-Write auf PROJEKTE-Root ist GO-pflichtig (extern).
```

## Was schon existiert (Fundament ~70%)

| Baustein | Datei | Stand |
|---|---|---|
| **`FolderSchema`** (Domain, Codable, `allePfade()`) | `Sources/MykilosKit/Domain/FolderSchema.swift` | ✅ da, aber **hartkodiert** als `static let v1` (aus `_BEISPIELORDNER` verifiziert) + `v1Defaults`-Konnektoren |
| **`OrdnerKonnektor`** (slot → ordnername → relativerPfad → schemaVersion) | `FolderSchema.swift` | ✅ da |
| **`DriveOrdnerbaumBuilder`** — baut Baum idempotent unter Parent | `Sources/MykilosServices/DriveOrdnerbaumBuilder.swift` | ✅ da (gemeinsame Präfixe nur einmal, Wiederaufnahme über bestehende IDs) |
| **`ProjektProvisioningService`** — Drive + Airtable + ClickUp orchestriert | `Sources/MykilosServices/ProjektProvisioningService.swift` | ✅ da, aber **TEST-Sandbox-gated** (`_TEST_PROVISIONING`) |
| **`NomenklaturStore`** — persistiert Konnektoren (GRDB) + `aktiveSchemaVersion: Int` | `Sources/MykilosServices/NomenklaturStore.swift` | ✅ da |
| **`ProvisioningPlan`** (`plan.schema`, `plan.ordnerName`, `plan.projektnummer`) | `Sources/MykilosKit/Domain/Provisioning.swift` | ✅ da |

## Was fehlt (der Neubau)

1. **Schema editierbar + persistent machen.** Heute ist `FolderSchema.v1` ein `static let` im Code.
   → Ein vom Admin definiertes Schema (`FolderSchema v2`) in GRDB speichern (der `NomenklaturStore`
   verwaltet schon eine Schema-Version — dort andocken). Migration für die Schema-Ablage.
2. **Admin-Editor-UI.** Neue Sektion (Settings → System/Admin, oder eigener „Team/Admin"-Bereich):
   Baum bearbeiten — Ordner hinzufügen/entfernen/umbenennen/verschachteln, Live-Vorschau. Der
   Backlog nennt „Finder-artiger Baum-Editor". Nur für Admin/Hausmeister sichtbar.
3. **Namensschema-Token.** Projektordner-Name als Template: `{Jahr}_{Nr:3}_{Kunde}` o. ä., mit
   Token-Editor + Live-Vorschau. Teile davon existieren (`projektnummer.appFormat`, `plan.ordnerName`).
4. **Verdrahtung in die Projekt-Anlegen-Maske.** Beim Anlegen eines Projekts: aktives Admin-Schema
   + Namensschema → `ProvisioningPlan` → `ProjektProvisioningService`.
5. **Echter Drive-Write (GO-pflichtig).** Raus aus `_TEST_PROVISIONING`, auf den echten
   PROJEKTE-Root (`1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST`, verifiziert). Nur mit Johannes' GO,
   idempotent, nie überschreibend (bestehende Ordner bleiben).

## Leitplanken (aus CLAUDE.md)

- **Namen sind Referenzen, keine Primärschlüssel** — Schema-Slots über stabile IDs, nicht Klartext.
- **Externe Daten heilig:** Alt-Ordner physisch unangetastet; Schema ist Vertrag/Vorlage für NEUE
  Projekte, kein Umzug bestehender. Nie DELETE, nie überschreiben.
- **Datenstrom-Handbuch + Benutzerhandbuch** bei der neuen Drive-Write-Weiche sofort eintragen.
- **Provisioning bleibt idempotent** (find-or-create) — Doppel-Anlegen tut nichts.

## Empfohlene Bau-Reihenfolge (kleine, abnehmbare Stufen)

1. `FolderSchema` editierbar + GRDB-Persistenz (Domain + Store + Migration + Cold-Start-Test) — **kein
   Drive-Write, voll autonom testbar.**
2. Admin-Editor-UI (Baum + Namensschema-Token + Live-Vorschau) — sichtbar, Johannes-Abnahme.
3. Verdrahtung Projekt-Anlegen-Maske → Plan (weiter Sandbox).
4. **GO-Gate:** echter PROJEKTE-Root statt Sandbox — Johannes' ausdrückliches GO, ein Testprojekt live.

## Anwendungsfall: Mail-Anhang → Marker → Unterordner (Johannes 2026-07-06)

**Wunsch:** Im Mail-Anhang-Drive-Dialog auswählen können, in welchen **Unterordner** eines Über-
ordners das Dokument verschoben wird — mit einem **Marker** (AB / Rechnung / Zeichnung / …).

**Ist-Stand (Fundament da):** `Sources/MykilosApp/Mail/MailAttachmentDriveSheet.swift` +
`MailAttachmentRow.swift` existieren; `appState.listDriveSubfolders(parentFolderID:)` **listet
Unterordner bereits**. Es ist ein **Ausbau**, kein Neubau.

**Zu bauen:**
1. **Unterordner-Navigation** im Sheet — nicht nur Überordner, sondern in die Unterordner
   reinklicken + als Ziel wählen (nutzt `listDriveSubfolders`).
2. **Marker → Ziel-Slot (Schaltschrank-Route):** Marker AB/Rechnung/Zeichnung/… mappen auf die
   **Ordner-Slots dieses Schemas** (z. B. AB→„01 ANGEBOTE", Zeichnung→„02 CAD"). Der Marker
   *schlägt* den Ziel-Unterordner vor (steckbare Route, kein Hardcode) und **taggt** das Dokument.
   → Genau dieselbe `OrdnerKonnektor`/Slot-Logik wie oben; die Marker sind die Slot-Namen.
3. Ablage bleibt **bestätigt** (nie Auto-Move), Drive read-only außer zum bestätigten Ziel.

Deshalb gehört dieser Wunsch hierher: die Marker-Zuordnung IST das Ordner-Schema, nur von der
Mail-Seite aus benutzt. Ein gepflegtes Schema (oben) speist direkt die Marker-Liste dieses Dialogs.

## Warum eigener Strang / frische Session

Erfasst in der langen Session vom 2026-07-06 (Multi-User + Profil + View-Einstellungen + UI-Feedback).
Kontext dort am Limit — dieser Strang verdient frischen Kopf. Fundament ist hier präzise kartiert,
die nächste Session startet direkt bei Stufe 1.
