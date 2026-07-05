# Handgepäck-Audit — Ausliefer-Bereitschaft an Teammitglieder (2026-07-05)

*Read-only Audit vor dem Test-Ship. Verifiziert am echten Bundle, nicht nur am Code.*

**Kernbefund: Die App reist sauber. KEINE kritische Zahnbürste** (nichts, das auf einem
fremden Mac crasht/blockiert). Jeder lokale Datenpfad hat einen Fallback.

## 🟢 Reist korrekt mit (im Bundle verifiziert)
- `AppIcon.icns`, `mykilos-wordmark-*.svg`, `DatastromManifest.json`, `studio_brain.json` (Assistenten-Wissen, 138 KB)
- **31 echte Projekte + 30 Kunden** einkompiliert in `InitialProjectSeed.swift` → Cold-Start zeigt sofort Projekte, ohne Login/Netzwerk
- `db.sqlite` wird beim ersten Start selbst erzeugt (crash-sicher)
- Keychain-Secrets: jeder Tester füllt selbst über den Wizard (kein hartkodierter Secret; nur Placeholder)

## 🟡 Grenzfälle (fremder Mac = schlechter, aber kein Crash)
1. **Kalkulations-Korpus fehlt** — die drei Loader (`BrainSeedProvider`, `DeviceCatalog`,
   `ScopeSignatureCatalog`) suchen einen hartkodierten „gelben" Pfad
   `~/Claude/…/_Daten/Kalkulation/…` + Application Support → auf fremdem Mac **leer** →
   Fallback auf einkompilierte `BaselineAnchorProvider`. **App läuft, Schätzungen aber nur
   grob (Baseline) statt echter 3.383-Beobachtungen-Korpus.** BEWUSSTES DESIGN: der Korpus ist
   Geschäftsgeheimnis, darf NIE ins Repo/Bundle. → Produkt-Entscheidung: Tester echte Schätzungen?
   Dann Export/Import-Mechanismus (`DeviceCatalog.importCatalog(from:)` existiert schon; für die
   zwei anderen CSVs noch nicht). Sonst Baseline belassen.
2. **Marken-Schrift (ABC Monument Grotesk)** nicht im Bundle (Dinamo-Lizenz) → Fallback SF Pro.
   Kein Crash, nur weniger CI-Look. Bewusst.
3. **Lokal materialisierte Drive-Dateien** (`LocalDriveRootResolver`) → Fallback `webViewLink`
   (Browser), wenn Google Drive Desktop fehlt. Per-User erwartbar.

## Nicht-App (shippt nicht)
- Nächtlicher Backup-LaunchAgent `script/com.mykilos.backup-local-data.plist` hat absoluten
  `/Users/johannesleoberger/…`-Pfad — ist NICHT im `.app`/DMG, nur Dev-Automation.

## Packliste (vor dem Ship zu klären)
1. **Kalkulations-Modul:** Tester echte Schätzungen nötig? Ja → Korpus-Export/Import. Nein → Baseline reicht. *(einzige echte Produkt-Entscheidung)*
2. **Marken-Schrift:** nur falls exakter CI-Look fürs Testen zählt → Lizenz + `.otf` bündeln. Sonst System-Fallback.
3. **Sonst nichts** — DB, Seeds, Wissensbasis, Icon, Manifest, Wordmark, Projektdaten reisen mit; Credentials füllt der Tester selbst.

## Kleiner Aufräum-Hinweis (nicht blockierend)
Der hartkodierte „gelbe" Korpus-Pfad in den drei Loadern ist auf fremden Macs bedeutungslos
(degradiert sauber). Falls der Korpus je mitreisen soll: Import auf Application Support zielen
(portabel), nicht auf den gelben Pfad. Eigener kleiner Strang.
