# 🏁 Handoff — Migration auf mykilOS-macOS + Version 11 (2026-07-06 abend)

## ⚠️ ZUERST: `KOORDINATEN.md` lesen (Maxime #1)
macOS-App = Ordner **`mykilOS Mac`**, Repo **`mykilOS-macOS`**, Version **11**. Vor JEDER Aktion `origin` prüfen (muss `mykilOS-macOS` sein). Nie in einen anderen Ordner/Repo/Git. Volle Regeln + 4-Schubladen-Landkarte: `KOORDINATEN.md`.

## Was diese Session gemacht hat (alles committed + gepusht auf `mykilOS-macOS`)
- **Repo-Umzug:** origin `mykilOS-7` → `mykilOS-macOS` (alt als Remote `mykilOS7-alt` gesichert). Lokaler Stand war identisch, kein Force nötig.
- **Version 11:** README-Titel auf „mykilOS 11"; Referenzen `mykilOS-7`→`mykilOS-macOS`, `mykilOS6`→`mykilOS Mac` (versions-sicher — DMG-Versionsnamen wie `mykilOS-7.11.0.dmg` bewusst geschont).
- **Ballast archiviert:** `HYPERBUILD.md`, ZIPs, `mykilOS8_Orchestrierung` → `_archiv_2026-07-06/`.
- **Harte Sperre:** `KOORDINATEN.md` + Pre-Push-Guard-Hook (`.git/hooks/pre-push`, versioniert in `scripts/guard-pre-push.sh`) blockt physisch jeden Push ≠ `mykilOS-macOS` + CLAUDE.md-Maxime-Header.
- **ClickUp Brain-Brief:** `docs/clickup/hello_brain.md`.
- Commits: `645b98c` (Migration), `6c64051` (Sperre). Branch `feat/multi-user-login`.

## Offen / Rest
- **Handoff-Archivierung:** veraltete (mykilos8-Blöcke, alte Feature-Handoffs) → `docs/handoffs/_archiv/`; den Rest kann die nächste Session final sortieren.
- **Version im Code:** dist-Builds heißen noch `10.0.0-alphaXX` — nächster Build als `11.0.0`.
- **ClickUp-Vision** (unverändert wertvoll): stiller Zwilling + Stichtags-Schalter · App = Kommandozentrale (Neues-Projekt-Maske → Drive-Ordner + ClickUp-Projekt aus Templates) · Brain-Konsultation via `docs/clickup/hello_brain.md` (Johannes = Copy-Paste-Draht, Brain = Design-Zeit-Berater). Details: `docs/handoffs/CLICKUP_DATENINTEGRATION_PLAN.md`.
- **ClickUp-MCP read-only auslesen** (echte Feld-Slugs) wartet auf Johannes-GO.

## Vibe + Feedback (Pflicht laut `[[logs-carry-vibe-feedback-memory]]`)
- **Vibe:** harter Tag — Ordner-/Repo-Verwechslung (ich saß im `mykilOS iOS`-Ordner, nannte mich „Satellite"), Vertrauensbruch. Am Ende sauber vollständig auf `mykilOS-macOS`/v11 migriert + hart gesperrt.
- **Feedback Johannes→mich:** Maxime #1 (nie falscher Ordner/Repo, hart gesperrt); keine Schluderigkeit; keine autonomen Agenten (parallele Sessions); kein „Hypermode"-Gerede mehr.
- **MEMORY:** `[[mykilos-arbeitsumgebung]]` auf `mykilOS Mac` / `mykilOS-macOS` aktualisiert.

## STARTPROMPT nächste Session
> Ordner (EINZIG): `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac`. Zuerst hart prüfen: `git -C "<repo>" remote get-url origin` MUSS `github.com/JohannesLeoB/mykilOS-macOS` sein — sonst STOP, nichts tun. Nur absoluter Pfad (Session-cwd kann fälschlich `mykilOS iOS` sein — ignorieren). Lies `KOORDINATEN.md` (Maxime #1), `CLAUDE.md`, diesen Handoff. Branch `feat/multi-user-login` (auf mykilOS-macOS, gepusht, sauber). KEINE autonomen Agenten/Commits/Pushes ohne Johannes' explizites GO — parallele Sessions in den anderen Schubladen. Danach dirigiert Johannes ClickUp (Zwilling/Brain) + den Bau-Rückstand, koordiniert.
