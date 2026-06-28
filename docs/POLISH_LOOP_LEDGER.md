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
| L7 | SchaltzentrumView — Live-Anzeige Weichen + letzter Handshake | done | 1af4888 | 225 | SettingsView verdrahtet + KatalogeView-Quote-Fix |
| L8 | Vollständigkeits-Audit (SCHALTZENTRUM_DATENSTROM.md) | done | 40da1bf | 225 | Kein Gap — 3 statische IDs + 5 Tool-Namen abgedeckt; ausstehende Weichen korrekt |

## Block 3 — Artikel-Hirn (Kataloge)

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L9 | Sidebar-Umbau: brands → kataloge; Dashboard → Settings | done | 40da1bf | 225 | AppModule.kataloge + KatalogeView bereits verdrahtet (vorab committed) |
| L10 | KatalogeView: Artikel-Airtable read-only + Suche/Filter | done | 1af4888 | 225 | KatalogeView vollständig (CSV, Search, Table, emptyState, Hover) — vorab committed |
| L11 | search_katalog-Tool im Assistenten | done | 1af4888 | 225 | SearchKatalogTool + Registry.standard — vorab committed |

## Block 4 — Assistent-Vollendung

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L12 | Tool-Transparenz: Quellzeile je Tool-Lauf im Chat | done | 1af4888 | 225 | ToolCallRow + activityLabel(name:inputJSON:) — vorab committed |
| L13 | Gmail-Labels (Ablageort) im Detail-Fetch | done | 1af4888 | 225 | placement(from:) + humanLabel(_:) in SearchGmailTool — vorab committed |
| L14 | Streaming/Activity-Politur | done | d5c1509 | 230 | Cursor ▌ am tippenden Text (isStreaming + displayText) |
| L15 | Capability-Ehrlichkeit + Connect-Check | done | ccc925f | 230 | AssistantCapability + AssistantCapabilityChip — 7 Chips, farbig wenn aktiv |

## Block 5 — Datei-Vorschau

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L16 | Drive-Scope + downloadFileContent | done | e0f0df3 | 233 | thumbnailLink + downloadContent + driveReadonly (inaktiv) + 3 Tests |
| L17 | Preview-Bausteine (FilePreviewView / Renderer) | done | 049f696 | 233 | AsyncImage(thumbnailLink) + SF-Fallback + Browser-Open-Button |
| L18 | Preview verdrahten in Files/Angebote/Material | done | be138dc | 233 | DriveTreeRow Popover → FilePreviewView mit Browser-Open-Button |
| L19 | Mail-Anhänge (format=full + downloadAttachment) | done | 98b956d | 237 | GmailAttachment + format=full + extractAttachments rekursiv + 4 Tests |

## Block 6 — Angebote

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L20 | Angebote-Tab 04/05 getrennt + Suche/Sortierung + Preview | done | 11b2326 | 237 | Suchfeld + Datum/Name-Toggle + Preview-Popover (Icon-Klick → FilePreviewView) |
| L21 | Angebote-Sammler GlobalOffersView über alle Projekte | done | (bereits implementiert) | 237 | Projektliste links + OffersTabView rechts, bereits live |

## Block 7 — Menschen/Projekt-Hirn (Signal-Nervensystem)

| ID | Titel | Status | Commit | Tests | Notiz |
|----|-------|--------|--------|-------|-------|
| L22 | Signal-Monitore: Budget/Deadline/DriveFile echte Emitter | done | f8f27e3 | 238 | CashWidget budgetThresholdCrossed ≥0.9; TasksWidget deadlineNear ≤7 Tage; DriveOfferWatcher driveFileAdded für Nicht-Angebote; +1 GATE-Test |
| L23 | Mail-Vollcache (GmailCacheStore + GmailSyncService) | done | ef09d76 | 243 | GmailCacheStore actor + TTL; SearchGmailTool Cache-Hit vor API; 5 GATE-Tests |
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
