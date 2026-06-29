# Git-Workflow — sauber, signiert, zurückverfolgbar

Die verbindliche Arbeitsweise ab mykilOS 7. Ziel: **jede verstreute Entwicklung
bleibt benannt, signiert und im Gesamtkontext klar** — und zwei Stränge lassen
sich jederzeit sauber wieder vereinen.

---

## 1 · Eine Heimat

| Was | Wo |
|---|---|
| **Kanonisches Repo** | `origin` → github.com/JohannesLeoB/**mykilOS-7** (privat) |
| **Archiv** | `mykilos6-archive` → mykilOS-6 (read-only archiviert, nur Nachschlagen) |
| **Arbeitsordner** | `…/MYKILOS 6/mykilOS6/` (der gelbe Ordner, [[canonical-folder-rule]]) |

Es gibt **kein zweites aktives Repo** mehr. Alles läuft über `origin`.

---

## 2 · Der Stamm und die Äste

```
main ──●────────────●───────────●──────▶   immer grün, immer releasebar
       │v7.0.0🔒     │v7.5.0🔒    │…         Tags = Goldstände, für immer
       └ feat/…      └ feat/mail  └ experiment/…   kurze Äste, dürfen sterben
```

- **`main`** ist heilig: immer grün (`swift build` + `swift test`), nie direkt
  draufcommitten, nie force-pushen. Wächst nur per Merge/Fast-Forward vorwärts.
- **Goldstände** bekommen einen **Tag** (`v7.0.0`, `v7.5.0`, …) — unveränderlich.
  `v7.0.0` ist der Safe-Stand ([docs/SAFE_STATE.md](SAFE_STATE.md)).
- **Jede Arbeit = ein kurzer Ast** von `main`:
  - `feat/…` neue Funktion · `fix/…` Reparatur · `experiment/…` ergebnisoffener Versuch
  - Fizzelt ein Ast aus → einfach löschen. `main` hat es nie gesehen.

---

## 3 · Zwei Stränge vereinen

**Mergen** — beide Stränge bleiben sichtbar, sie treffen sich:
```bash
git checkout main
git merge --no-ff feat/xyz      # Merge-Commit zeigt: hier kam der Ast rein
```
Nutze das, wenn du *sehen* willst, dass parallel gearbeitet wurde.

**Rebasen** — ein Strang geht im anderen auf, eine glatte Linie ("ein Glied im
anderen"):
```bash
git checkout feat/b
git rebase feat/a               # b's Commits werden auf a neu aufgesetzt
git checkout feat/a && git merge feat/b   # jetzt fast-forward, kein Knick
```
Nutze das, wenn ein Versuch nahtlos Teil des anderen werden soll, als wäre es
immer eine Linie gewesen.

> Faustregel: **rebase, solange ein Ast noch privat ist** (aufräumen, glätten).
> **merge, sobald etwas geteilt/gepusht** wurde (Historie ehrlich lassen).
> Vor jedem Vereinen: beide Äste grün getestet.

---

## 4 · Signiert & beschriftet (jeder Commit)

- **Kryptografisch signiert** (SSH): `commit.gpgsign = true`, `gpg.format = ssh`,
  Key `~/.ssh/id_ed25519_signing`. GitHub zeigt **„Verified"** (nach einmaliger
  Key-Registrierung, s. u.). Beweisbare Urheberschaft.
- **Conventional Commits** als Betreff: `feat:` `fix:` `chore:` `docs:` `refactor:`
  `test:`. Maschinen- und menschenlesbar.
- **Strang-Nummer** im Betreff, wo es passt (`S25`, `L30`), damit der Commit auf
  das Ereignisprotokoll zeigt.
- **`Co-Authored-By:`** für KI-Beteiligung — Attribution zusätzlich zur Signatur.

Beispiel:
```
feat(mail): S26 — Mail-Lesefenster mit Anhang-Drag&Drop

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

### GitHub „Verified" scharfschalten (einmalig, dein Handgriff)

Der Signing-Key liegt bereit, ist aber noch nicht bei GitHub registriert. Eines
von beiden:

```bash
# Variante A — gh-Scope nachladen, dann registrieren:
gh auth refresh -h github.com -s admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519_signing.pub --type signing --title "mykilOS signing (Mac)"
```
**Variante B** — GitHub → Settings → *SSH and GPG keys* → *New SSH key* →
Key type **Signing Key** → den Inhalt von `~/.ssh/id_ed25519_signing.pub` einfügen.

> Hinweis: Für das Verified-Abzeichen muss die Commit-E-Mail
> (`johannesleoberger@icloud.com`) als **verifizierte E-Mail** im GitHub-Konto
> hinterlegt sein. Sonst signiert Git zwar, GitHub zeigt aber „Unverified".

---

## 5 · Die Schleife mit Claude (so bleibt alles im Kontext)

1. **Strang benennen** → Claude zweigt `feat/…` von `main` ab.
2. **Ein Task → ein Ast → grün** (`swift build` + `swift test`) → **ein signierter
   Commit** (Conventional + S-Nummer + Co-Author) → push nach `origin`.
3. **Eine Zeile ins [Ereignisprotokoll](EREIGNISPROTOKOLL.md)** (wer/was/wann/Ast)
   und ggf. in den [POLISH_LOOP_LEDGER](POLISH_LOOP_LEDGER.md).
4. **Grün & gewollt** → in `main` mergen/rebasen, bei Goldstand neuen Tag setzen,
   Ast löschen.
5. **Ausgefizzelt** → Ast löschen. Kein Schaden, `main` unberührt.

---

## 6 · Was nie passiert

- ❌ Direkt auf `main` committen oder `main` force-pushen.
- ❌ Tags `v7.0.0` / Goldstand-Tags verschieben oder löschen.
- ❌ Paralleles zweites Repo oder dauerhaftes Arbeiten in `~/Desktop/CLAUDE/`-Worktrees.
- ❌ Unsignierte Commits.
- ❌ Einen Ast in `main` bringen, der nicht grün ist.
