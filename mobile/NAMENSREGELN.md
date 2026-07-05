# NAMENSREGELN — nie wieder Versions-Chaos

*Fuer Johannes. Damit es nie wieder `App_final`, `App_final2`,
`App_wirklich_final` und zwoelf Zips gibt.*

## Die goldene Regel

**Git ist dein Versionsverlauf. NICHT der Dateiname, NICHT der Ordnername,
NICHT ein Zip.**

Jede Datei hat **einen** Namen — fuer immer. Aendert sich der Inhalt, bleibt
der Name. Der alte Stand ist nicht weg: er steckt in der Git-Historie.

## Verboten

- ❌ `ContentView 2.swift`, `ContentView_neu.swift`, `ContentView_final.swift`
- ❌ Ordner wie `Projekt_alt/`, `Projekt_KOPIE/`, `Backup_Juli/`
- ❌ Zwoelf Zips (`KOMPLETT-3`, `-4`, `-5` ...) nebeneinander im Download

## Erlaubt / richtig

- ✅ Eine Datei, ein Name. Aenderung -> speichern -> `git commit`.
- ✅ "Wie war es gestern?" -> `git log` / in GitHub die History ansehen.
- ✅ Etwas ausprobieren, das schiefgehen koennte? -> ein **Branch**
  (`git switch -c experiment-xyz`), nicht eine Kopie-Datei.
- ✅ EIN Repo pro App. Der Satellit lebt in `mykilos-mobile`, die Mothership
  in `mykilOS-7`. Fertig.

## Der eine Merksatz

> Wenn du je einen Dateinamen mit "2", "neu", "final", "kopie" oder einem
> Datum ergaenzen willst — **stopp**. Das macht Git fuer dich. Committe
> stattdessen.

## Wie wir ab jetzt liefern (Satellit)

- **Kein Zip-Pingpong mehr.** Sobald `mykilos-mobile` auf GitHub liegt,
  arbeiten alle Sessions direkt am Repo (Branch + Commit + Pull Request).
- Ein Zip gibt es nur noch fuer den **allerersten** Import ("Seed"). Danach:
  git.

## So machst du aus diesem Ordner das Repo (einmalig, am Mac)

```bash
cd mykilos-mobile
git init
git add .
git commit -m "Seed: Satellit-Grundstand"
# dann auf GitHub ein leeres Repo "mykilos-mobile" anlegen und:
git remote add origin https://github.com/JohannesLeoB/mykilos-mobile.git
git branch -M main
git push -u origin main
```

Ab da ist GitHub die Wahrheit — und das Chaos vorbei.
