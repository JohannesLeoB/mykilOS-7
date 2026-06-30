# HANDOFF — Zusammenarbeit & Arbeitsbaum (für externe Mitwirkende & Agenten)

```
Repo:    https://github.com/JohannesLeoB/mykilOS-7  (privat)
Stand:   mykilOS 7.7.0 (Tag v7.7.0)
Gilt für: Daniel Klapsing, Codex, ausgelagerte Claude-Code-Sessions, jeden fremden Agenten.
```

> Verbindliche Kurzregeln stehen in **[AGENTS.md](../../AGENTS.md)** (oben). Dieses Dokument
> erklärt die Zusammenarbeit im Detail. Lebender App-Stand: **CLAUDE.md** + **HYPERBUILD.md**.

## 1. Rollen & Rechte

| Person/Agent | Domäne | Repo-Rechte |
|---|---|---|
| **Johannes Leo Berger** | **Die App** (Swift/SwiftUI/mykilOS). Owner. | Voll. **Nur er committet App-Code & merged nach `main`.** Baut die App real weiter. |
| **Daniel Klapsing** | **Backend**: Airtable-Schema, Sevdesk (via Make.com), Datenbanken, Datenverträge. | **Lesen · Branches anlegen · ausprobieren (Tryout).** KEIN Merge nach `main`, kein „echtes" App-Weiterbauen. |
| Codex / andere Claude-Sessions | ausgelagerte Coding-Blöcke | Nur auf Branches, PR an Johannes. Nie direkt `main`. |

**Kernprinzip:** App-Hoheit = Johannes. Backend-Hoheit = Daniel. Beide treffen sich an der
**Airtable-Schnittstelle** (System-of-Record). Niemand außer Johannes verändert `main`.

## 2. Wie Daniel (Backend) andockt

Daniel braucht die App-Codebasis NICHT zu kompilieren. Sein Arbeitsbereich ist Airtable/Make/Sevdesk.
Im Repo dockt er so an, wenn etwas die App betrifft (neue Tabelle, geändertes Feld, neuer Datenstrom):

1. **Branch anlegen:** `backend/<thema>` (z. B. `backend/sevdesk-angebot-felder`).
2. Änderung **dokumentieren** (nicht App-Code schreiben): Tabellen-/Feld-IDs, Richtung, Trigger
   in einer Notiz/Markdown unter `docs/` ODER direkt im **Datenstrom-Handbuch** (Airtable
   `tblaUVftka0GvXzeU`). Die App liest IDs als Referenzen — sie dürfen sich nicht still ändern.
3. **Pull Request** an Johannes. Johannes prüft, ob die App nachziehen muss, und merged.
4. **Niemals** Tabellen/Felder löschen oder umbenennen, von denen die App liest, ohne vorher PR +
   Absprache — sonst bricht der App-Sync hart.

## 3. Arbeitsbaum-Disziplin (alle Agenten)

- **Ein kanonischer Ordner**, nie dauerhaft in Desktop-Worktrees arbeiten.
- **Parallele Agenten = isolierte git-Worktrees** (`isolation: worktree`). Zwei Agenten/Prozesse
  im selben Arbeitsbaum führen zu Commits auf dem falschen Branch (ist real passiert).
- **`main` nie direkt, nie force.** Feature-Branch → grün (`swift build` + `swift test`) → PR → Johannes merged (Fast-Forward bevorzugt).
- **Signierte Commits**, Conventional Commits. Claude-Arbeit: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- **Versionierung:** Nur Johannes hebt die Version + baut DMG. App-Bundle/DMG tragen die Versionsnummer im Namen.
- **Push/Release nur mit ausdrücklicher Freigabe von Johannes.**

## 4. Datenschutz / NO-GOs (siehe AGENTS.md)
Sevdesk nie aus der App · Airtable nur CREATE/PATCH, nie DELETE/Overwrite (append-only) ·
`appkPzoEiI5eSMkNK` tabu · Secrets nur Keychain · EK-Preise/Kundendaten nie ins Repo.

## 5. Safe State
Tag `v7.0.0` (Commit `e629e84`) ist die unantastbare Rückfallebene. Nie verschieben/löschen.
`./script/recall_safe_state.sh` ruft ihn frisch auf.
