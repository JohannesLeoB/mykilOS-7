# Airtable PAT-Cleanup — S17

**Status:** Dokumentiert, manueller Schritt ausstehend (Johannes führt Änderungen in Airtable durch)

---

## Problem

Der aktuelle PAT im Keychain (`com.mykilos6.airtable` / `pat`) hat zu weite Scopes:

- `data.records:write` auf **ALLE** Bases — auch auf die Artikel-DB `appdxTeT6bhSBmwx5` (READ ONLY laut Charter)
- Zugriff auf den Workspace **"MYKILOS SCHATZ"** (`mykilos Datenbank Zuliefererpreise Schätzung`) — alter mykilO$$-Tryout, irrelevant für mykilOS 6
- **"Alle aktuellen und zukünftigen Bases"** als Scope — zu breit

---

## Was Johannes in Airtable-Settings ändern soll

1. Airtable → Developer Hub → Personal Access Tokens → `mykilOS 6 Mastermind`
2. **"Alle Ressourcen"-Scope entfernen** → explizit nur noch:
   - Mastermind-Base `appuVMh3KDfKw4OoQ` (read + **write** — Kalkulations-Port schreibt hier!)
   - Artikel-DB `appdxTeT6bhSBmwx5` (nur read — **kein write**)
3. **Workspace "MYKILOS SCHATZ" entfernen**
4. Optionaler nächster Schritt: separaten Read-Only-PAT für Artikel-DB anlegen
   (`data.records:read` + `schema.bases:read` only) → dann Mastermind-PAT ganz ohne
   Artikel-DB-Zugriff konfigurieren.

---

## ⚠️ Wichtig: Mastermind-Schreibrechte BEHALTEN

Der Kalkulations-Port schreibt nach Mastermind `appuVMh3KDfKw4OoQ`:
- `AirtableClient.createRecord` → Tabellen `Kalkulationen`, `Kalkulations-Positionen`, `Eingehende-Angebote`

→ `data.records:write` auf Mastermind darf beim Scope-Schnitt NICHT entfernt werden.

---

## Was S17 Code-seitig sichert

- `AirtableError.invalidBaseID(String)` — verhindert künftige Fehl-Speicherungen von PAT im Base-ID-Feld
- `AirtableAuthService.connect` validiert: `trimmedBase.hasPrefix("app") && (15...22).contains(count)`
- Artikel-DB-Schutz ist zusätzlich Code-only (Statut 5 im Team-Charter): `AirtableClient.fetchRecords` liest `baseID` aus den Credentials — alle Schreib-Caller in der App zeigen explizit auf `appuVMh3KDfKw4OoQ`.

---

## Nach dem PAT-Update testen

```bash
./script/build_and_run.sh
# → Settings → Airtable → Verbinden (bestehende Credentials bleiben, da nur Scopes geändert)
# → Sync starten → sollte grün durchlaufen
```

Falls zwei PATs (Mastermind + Artikel-DB getrennt): `AirtableAuthService` braucht
ein optionales `artikelPAT`-Feld in `AirtableCredentials` — separater S18/S19-Task.
