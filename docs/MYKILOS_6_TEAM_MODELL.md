# mykilOS 6 — Team-Modell
### „Persönliches Cockpit, geteilte Instrumente"

Companion zum Produktionsplan. Festgelegtes V1-Team-Modell: **kein Sync-Backend, local-first, jeder seine Identität — geteilt wird über die externen Systeme.**

---

## Das Prinzip in einem Satz

> Jeder im Team hat sein eigenes, persönliches mykilOS auf seinem Mac — eigenes Layout, eigene Notizen, eigene Google-Identität. Aber alle schauen durch ihre Fenster auf dieselben geteilten Instrumente: dieselbe Drive, denselben ClickUp-Space, denselben Kalender. Das Team lebt in den externen Systemen; mykilOS ist die persönliche Linse darauf.

Kein Server. Keine geteilte mykilOS-Datenbank. Keine verteilten Secrets. Die Sicherheitsregeln bleiben unangetastet.

---

## Wer sieht was — die Eigentums-Klarheit

Das Wichtigste, damit später keine Verwirrung entsteht: **was lebt wo.**

### Persönlich — lokal in deinem SQLite, nur auf deinem Mac
- Deine Widget-Anordnung, Größen, angeheftete Widgets
- Deine persönlichen Notizen / Post-Its
- Deine lokalen Entwürfe (Mail-, Termin-Drafts vor Freigabe)
- Deine UI-Präferenzen (Fenstergröße, zuletzt gewähltes Modul)
- Dein eigener Audit-Trail deiner eigenen Aktionen

→ Erscheint **nicht** auf dem Mac eines Kollegen. Das ist gewollt — jeder gestaltet sein Cockpit, wie er arbeitet.

### Geteilt — in den externen Systemen, gesehen durch deine eigene Identität
- Drive-Dateien (Shared Drive)
- ClickUp-Tasks (geteilter Space)
- Kalendertermine (geteilte/freigegebene Kalender)
- Mail-Kontext (deine eigene Mailbox)
- Sevdesk-Angebote, Kontakte

→ Alle sehen dasselbe, weil es in den geteilten externen Systemen liegt. mykilOS hält nur **Referenzen** (IDs), nie die Daten selbst, nie ein geteiltes Passwort. Google/ClickUp/Sevdesk entscheiden über ihre eigene Rechteverwaltung, wer was sieht.

### Geteilt-aber-clever — das Projekt-Manifest (siehe unten)
- Die Verdrahtung „welche Drive-ID / ClickUp-Liste gehört zu welchem Projekt"

→ Reist in den geteilten Instrumenten mit, sodass das Team dieselben Projekte konsistent verdrahtet hat — ohne Backend.

---

## Die geteilte Registry — Airtable als System-of-Record

> **Update (eingepflegt):** Diese Rolle übernimmt **Airtable**. Airtable ist die geteilte Datenbank für Kunden & Projekte — Kundennummer, Projektnummer/Kürzel, Links & Pfade, und über verknüpfte Datensätze die Beziehung Nachtrag → Eltern-Projekt. Es **ersetzt** das unten skizzierte hand-gebaute JSON-Manifest: dasselbe Prinzip (secret-freie Referenzen, von allen gelesen), aber als echte Datenbank statt einer Datei. mykilOS liest die Liste aus Airtable, **cached sie lokal** (Persistenzschicht aus Akt 0), rendert offline-fähig aus dem Cache und synct on-demand. Der Airtable-PAT liegt im Keychain, nie im Repo. Der ursprüngliche Manifest-Gedanke bleibt nur noch als optionales Export-/Fallback-Format gültig.

Das Problem am reinen „jeder lokal"-Modell: Wenn du „Küche Meyer" mit Drive-Ordner `abc123` und ClickUp-Liste `xyz` verknüpfst, müsste ein Kollege diese Verknüpfung von Hand neu anlegen. Bei 30 Projekten wird das Arbeit.

**Die Lösung nutzt eure eigene Architektur-Regel aus:** mykilOS speichert nur Referenzen, keine Secrets. Also ist die komplette „Verdrahtung" eines Projekts nur eine kleine, **secret-freie** JSON-Datei:

```json
{
  "manifestVersion": 1,
  "project": {
    "id": "kueche-meyer",
    "title": "Küche Meyer",
    "phase": "Ausführungsplanung"
  },
  "sources": {
    "driveDrawings":  { "folderId": "1AbC…", "label": "Zeichnungen Meyer" },
    "driveOffers":    { "folderId": "1XyZ…", "label": "Eingangsangebote" },
    "clickup":        { "listId":   "9012…", "label": "Küche Meyer" },
    "calendar":       { "query": "Meyer" },
    "contacts":       [ { "name": "Familie Meyer", "role": "Bauherr" } ]
  },
  "updatedAt": "2026-06-25T10:00:00Z"
}
```

**Wie es läuft:**
1. Das Manifest liegt an einem bekannten Ort **in der geteilten Drive** (z. B. `/_mykilos/projekte/kueche-meyer.json`).
2. Kollegin B öffnet mykilOS → die App liest das Manifest aus der geteilten Drive → „Küche Meyer" ist sofort verdrahtet.
3. B sieht das Projekt **durch ihre eigene Identität** gerendert: ihre Tokens, ihre Rechte. Hat sie keinen Zugriff auf einen Ordner → sauberer „Berechtigung nötig"-Zustand.

**Die eiserne Regel dazu:** Das Manifest enthält **niemals** Tokens, API-Schlüssel oder Auth-Material — nur Referenzen und Labels. Damit ist es sicher in der geteilten Drive ablegbar. Es importiert auch **keine Daten** — es setzt nur die Referenzen. Die echten Daten fließen weiter read-only durch jede Person einzeln, mit allen Review- und Audit-Regeln intakt.

→ So bekommt das Team konsistente Projekt-Setups, ohne dass mykilOS einen Server braucht. Die Projektdefinition reist in den geteilten Instrumenten selbst mit.

---

## Identität — leicht, aus dem Google-Login abgeleitet

mykilOS 6 braucht keinen eigenen Account-Mechanismus. Die App weiß „ich bin Johannes" aus der eingeloggten Google-Identität. Diese Identität:
- stempelt `ownerUserID` auf deine lokalen Layouts (das Feld existiert im Modell schon: `WidgetLayoutSnapshot.ownerUserID`),
- ist der Actor in deinem Audit-Log (wenn später Writes passieren, steht „Johannes hat X gebucht" mit seiner Identität).

Leichtgewichtig, abgeleitet — kein zweites Login, kein mykilOS-Passwort.

---

## Rollen — ehrlich eingeordnet

Das Rollen-Modell existiert im Code (`StudioRole`, `RoleAccessLevel` visible/reduced/hidden, `RoleActionState` allowed/reviewGate/blocked). Ohne zentrale Verwaltung gilt für V1 ehrlich:
- Rollen formen die **lokale UI** — was eine Person an Modulen/Aktionen sieht, wie aufgeräumt ihr Cockpit ist.
- Die **echte Sicherheitsgrenze** für produktive externe Writes ist nicht mykilOS' lokale Rolleneinstellung, sondern die **Rechteverwaltung des externen Systems** selbst. Genau dasselbe elegante Prinzip wie bei Drive: das externe System ist der wahre Türsteher.

Eine zentral durchgesetzte Rollenverwaltung („nur Johannes darf produktive Writes auslösen, geräteübergreifend erzwungen") bräuchte ein Backend — und ist damit eine bewusste Zukunftsoption, kein V1-Versprechen.

---

## Team-Defaults — ein Startpunkt, kein Live-Sync

„Team-Defaults" lassen sich backend-frei lösen: ein Default-Layout als **importierbarer Seed** (kann ebenfalls als Manifest in der geteilten Drive liegen). Eine neue Kollegin bekommt damit ein sinnvolles Start-Cockpit, das sie dann personalisiert. Das ist ein Samen, kein laufender Abgleich.

---

## Auswirkung auf den Produktionsplan

Diese Entscheidung fügt **keinen neuen Akt** hinzu (kein Backend). Sie schärft bestehende:
- **Akt 1 (Erstes Zuhause):** leichte Identität aus dem Google-Login; `ownerUserID` wird gestempelt.
- **Akt 1/3:** kleines Feature „Projekt-Manifest exportieren/importieren" (lesen aus bekanntem Drive-Ort). Secret-frei, getestet.
- **Akt 3 (Integrationen):** funktioniert pro Person von Natur aus — jeder seine OAuth, jeder seine Sicht.

**Die Tür bleibt offen:** Sollte später echte geteilte mykilOS-Ebene gewünscht sein (Team-Layouts live, zentrale Rollen, gemeinsamer Audit-Trail), ist das ein sauber abgrenzbarer **Akt 6 — Team-Sync** (kleines Backend / CloudKit / geteilte Config-DB). Die V6-Architektur verbaut diesen Weg nicht — sie macht ihn nur nicht zur Voraussetzung.

---

## Zusammengefasst

| Dimension | V1-Antwort |
|---|---|
| Identität pro Person | ✅ eigener Google-Login, eigener Keychain |
| Geteilte Drive / ClickUp / Kalender | ✅ über externe Rechte, mykilOS hält nur Referenzen |
| Geteilte API-Schlüssel | ⚠️ pro Rechner in den Keychain, nie in Dateien |
| Konsistente Projekt-Setups im Team | ✅ über das secret-freie Projekt-Manifest |
| Geteilte Layouts / Notizen / Audit | ❌ persönlich (gewollt) — Zukunftsoption Akt 6 |
| Zentrale Rollendurchsetzung | ❌ extern getürsteht — Zukunftsoption Akt 6 |

**Persönliches Cockpit. Geteilte Instrumente. Sicher, ehrlich, ohne Server.**
