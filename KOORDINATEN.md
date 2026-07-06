# 🧭 KOORDINATEN — Wer ist wer (Maxime #1)

**Diese Schublade ist die macOS-App. Sie bewegt sich NIEMALS in einen anderen Ordner, ein anderes Repo oder ein anderes Git.**

## Diese App
- **Entity:** mykilOS **macOS** · Version **11**
- **Lokaler Ordner:** `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac`
- **GitHub (origin):** `github.com/JohannesLeoB/mykilOS-macOS`

## Die vier getrennten Schubladen — nie vermischen
| Entity | Lokaler Ordner | GitHub-Repo |
|---|---|---|
| **macOS** (diese) | `mykilOS Mac` | `mykilOS-macOS` |
| iOS | `mykilOS iOS` | `myMini` |
| iPadOS | `mykilOS iPAD` | `mykilOS-iPadOS` |
| browser | `mykilOS Web` | `mykilOS-WWW` |

## Harte Regeln (Maxime #1)
1. **Vor JEDER Aktion** (build/test/commit/push/Agent): `git -C "<repo>" remote get-url origin` MUSS `mykilOS-macOS` enthalten — sonst **SOFORT STOP**.
2. **Nur absoluter Pfad**, nie cwd-relativ. ⚠️ Der Session-`cwd` kann fälschlich auf `mykilOS iOS` zeigen — **ignorieren**, `mykilOS Mac` immer absolut ansprechen.
3. **KEINE** autonomen Bau-Agenten / Commits / Pushes ohne Johannes' explizites GO — es laufen parallele Sessions in den anderen Schubladen.
4. Ein **Pre-Push-Hook** (`.git/hooks/pre-push`, versioniert in `scripts/guard-pre-push.sh`) blockt physisch jeden Push, dessen Ziel nicht `mykilOS-macOS` ist.

## Historie (was tot ist)
- Früher: Ordner `mykilOS6`, Repo `mykilOS-7` — **beide tot**. Am 2026-07-06 migriert auf `mykilOS Mac` / `mykilOS-macOS`, Version 11.
- Backup-Remote `mykilOS7-alt` zeigt noch auf das alte `mykilOS-7` (reine Sicherung, nicht zum Pushen).
