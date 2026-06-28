# mykilOS 6 — Polish-Loop Ledger

Branch: `polish/dampflok` · Erstellt: 2026-06-28

Reihenfolge = Priorität. Status: `pending` | `done` | `blocked`.

---

## Block 1 — Zahlen-Hirn

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L1 | Kalkulation echt — BrainSeedProvider verdrahten | done | 51b8ed0 | 207 | Parsing.swift küche-Pattern + 6 neue Tests |
| L2 | Kalkulator im Assistenten + Schätzchat-Toggle | done | d5b1c1a | 209 | schaetzDefinitions, ConversationEngine schaetzModusEnabled, AssistantChatView Toggle, 2 GATE-Tests |
| L3 | Geräte & Stundensätze (DeviceCatalog CSV + Airtable-Fallback) | done | 573c16e | 215 | StundensatzLoader + 6 Tests; DeviceCatalog.loadDefault() bereits live; Weiche DEVICE_CATALOG_LOAD in Handbuch |
| L4 | Lern-Loop-Politur (Promote-Flow + Audit) | done | 60c9abd | 216 | anpassen Auto-Reset 2,5s; promoteBestaetigung Auto-Clear 3s; promoteSchreibtAuditEntry GATE-Test |

## Block 2 — Daten-Hirn (Schaltzentrale)

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L5 | Alle Ströme instrumentieren (DataFlowLogger) | done | 5d50c26 | 217 | ConversationEngine.runLoop loggt jeden Tool-Call (success/error); AppState injiziert dataFlow; GATE-Test dataFlowLoggerLogtJedesToolRun |
| L6 | Knoten-Link (mykilos://datastream/<ID>) im Handbuch | done | e17d07e | 223 | DatastromManifest.json (22 Weichen) + 6 GATE-Tests (Existenz/JSON/Count/IDs/Felder/Link-Format) |
| L7 | SchaltzentrumView — Live-Anzeige Weichen + letzter Handshake | pending | — | — | |
| L8 | Vollständigkeits-Audit (SCHALTZENTRUM_DATENSTROM.md) | pending | — | — | |

## Block 3 — Artikel-Hirn (Kataloge)

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L9 | Sidebar-Umbau: brands → kataloge; Dashboard → Settings | pending | — | — | |
| L10 | KatalogeView: Artikel-Airtable read-only + Suche/Filter | pending | — | — | |
| L11 | search_katalog-Tool im Assistenten | pending | — | — | |

## Block 4 — Assistent-Vollendung

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L12 | Tool-Transparenz: Quellzeile je Tool-Lauf im Chat | pending | — | — | |
| L13 | Gmail-Labels (Ablageort) im Detail-Fetch | pending | — | — | |
| L14 | Streaming/Activity-Politur | pending | — | — | |
| L15 | Capability-Ehrlichkeit + Connect-Check | pending | — | — | |

## Block 5 — Datei-Vorschau

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L16 | Drive-Scope + downloadFileContent | pending | — | — | |
| L17 | Preview-Bausteine (FilePreviewView / Renderer) | pending | — | — | |
| L18 | Preview verdrahten in Files/Angebote/Material | pending | — | — | |
| L19 | Mail-Anhänge (format=full + downloadAttachment) | pending | — | — | |

## Block 6 — Angebote

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L20 | Angebote-Tab 04/05 getrennt + Suche/Sortierung + Preview | pending | — | — | |
| L21 | Angebote-Sammler GlobalOffersView über alle Projekte | pending | — | — | |

## Block 7 — Menschen/Projekt-Hirn (Signal-Nervensystem)

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L22 | Signal-Monitore: Budget/Deadline/DriveFile echte Emitter | pending | — | — | |
| L23 | Mail-Vollcache (GmailCacheStore + GmailSyncService) | pending | — | — | |
| L24 | Kontakt-Kontext im Assistenten (Airtable Kontakte) | pending | — | — | |

## Block 8 — UI-Politur

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L25 | Favoriten: GRDB projectFavorites + Stern-Button | pending | — | — | |
| L26 | Dunkelmodus-Kontrast + Token-Disziplin | pending | — | — | |
| L27 | Timeline-Tab (Drive/Angebote/Kalender/Audit) | pending | — | — | |
| L28 | Leerzustände & Konsistenz (RecentActivityWidget) | pending | — | — | |

## Block 9 — Härtung & Abschluss

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L29 | Test-Decke (Cold-Start + Unit für alle neuen Stores/Tools) | pending | — | — | |
| L30 | Abschluss: EREIGNISPROTOKOLL + Handoff + DMG | pending | — | — | |
