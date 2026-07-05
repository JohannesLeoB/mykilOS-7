# Bumerang-Flotte — Torwächter-Karte

**Status: Orchestrierungs-Modell (Leitplanke) + datierter Snapshot. Kein aktiver Bau-Auftrag.**

Johannes' Modell **„viele Bauer, ein Gate"** (aufgesetzt 2026-07-05). Die self-contained
Kits liegen auf `~/Desktop/mykilOS BOOMERANGS/boomerangs/` (ephemer — Kits werden an ihre
Zielsysteme verschickt). Diese Datei verankert die **durable** Struktur im Repo, damit sie
den Desktop überlebt. Der **volatile Live-Stand** wird in der Session/im Assistenten-Gedächtnis
geführt, nicht hier (Snapshot unten kann veralten).

## Rollen

- **Torwächter / Main Actor** = Claude Code im kanonischen Ordner (der einzige mit
  Swift-Toolchain). Fängt jeden Rückkehrer, verifiziert **selbst** (Diff auf der Platte lesen,
  `swift build`+`test` selbst fahren, adversarial durchgehen), entscheidet
  **integrieren / nachbessern / ablehnen**. **Merge nach `main` nur auf Johannes' ausdrückliches
  GO.** Voller Vertrag: die 6 Kit-Dateien in `claudecode-next-main-actor/`.
- **5 Satelliten** bauen autonom, weit weg, je auf eigenem Branch/Kanal — **nie self-merge**.

## Die Flotte

| Satellit | System | Job (kurz) | Rückkehr | Gate |
|---|---|---|---|---|
| `codex-ordner-schema-editor` | Codex | FolderSchema v2 + visueller Baum-Editor (Alt bleibt unangetastet) | Branch `feat/ordner-schema-editor` + PR | GO |
| `claudecode-kalender-cache-widgets` | Claude Code | `CalendarCacheStore` + AppState-Anschluss + Home-Kalender-Widget + Mini-Mode-Puls | Branch `feat/kalender-cache-widgets` + PR | GO |
| `uisoul-design-system` | Claude Code | Inventar jeder UI-Einheit (Token-Sprache?) — Rückgrat der Theme-Arbeit | `INVENTORY.md` + `PLAN.md` im Repo | GO (früh) |
| `claudedesign-theme-editorial` | Claude Design | Look-only Theme „Standard vs. Editorial" (kein Layout, kein Code) | Mockups + Token-Tabelle + Doc | GO, Torwächter übersetzt |
| `chatgpt-bro-konventionen` | ChatGPT web | Konventionen für 2 sandboxed KI-„Bros" (ClickUp-Testspace, Airtable-Sandbox) | 2 Markdown-Docs | **STOP** bis Johannes Bro-Job definiert |

## Doktrinen (projektweit, aus jedem `GUARDRAILS.md`)

- **Torwächter:** Vertrauen wird durch Verifikation verdient, nicht durch Behauptung. Nichts
  landet unverifiziert in `main`.
- **Interior-Build-Charter:** Kits bauen am Innenleben der App; externe Systeme (Airtable-SoR,
  ClickUp-Produktivraum, Sevdesk, Drive) sind Outer Limit — read-only / nur über saubere Adapter.
- **System-Integration Stück für Stück:** kein Big-Bang-Merge, ein Bumerang nach dem anderen
  (Beppo).

## Snapshot 2026-07-05 (volatil)

- **Läuft nur:** die Kalender-Cache-Web-Session (Cloud, Sonnet). **Off-script:** Branch
  `claude/new-session-hn4kqs` statt `feat/kalender-cache-widgets`, Etappe 4 (Mini-Mode-Puls)
  übersprungen, auf **veralteter Basis** (von `main`, ohne den Mini-Mode-Strang von
  `feat/plaene-katalog`) → Einfangen = **Reparatur, kein glatter Merge.** Plan: push-then-kill,
  echte Entscheidung nach Wochenlimit-Reset (Fr 10.7.).
- Andere 4 Satelliten: **nicht gestartet / nichts zurück.** ChatGPT auf **STOP** (wartet auf
  Johannes).
- 9 Worktrees unter `~/Desktop/CLAUDE/_mykilOS/` = **Altlasten (ignorieren).**
- **PR #3** (`feat/plaene-katalog`) = Johannes' echter aktueller Branch. **PR #1** = DRAFT-Doku.

Durable Quell-Docs (ephemer, auf dem Desktop): `HANDBUCH.md`, `BOOMERANGS_README.md`.
