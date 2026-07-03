# mykilOS — Datenkanäle, Ins & Outs, Grenzen

**Kurz & deutlich: welche Daten wohin fließen, was NIE hinausgeht, und wo die harten Grenzen sind — global und je Nutzer.** Stand 2026-07-03.

---

## Grundprinzip

- **Local-first.** Es gibt keinen zentralen Server. Jede Person hat ihr eigenes mykilOS auf ihrem Mac; Daten liegen lokal (GRDB-Datenbank) und Geheimnisse ausschließlich im **macOS-Schlüsselbund**.
- **Farbe = Quelle.** Jede Kachel zeigt, woher ihre Daten kommen — man erkennt die Quelle, bevor man liest.
- **Signale sind Vorschläge.** Nichts wird automatisch geschrieben. Schreibende Aktionen laufen immer über **Aktions-Karte → Bestätigung → Audit-Protokoll**.

---

## Die Datenkanäle

| Kanal | Richtung | Was fließt | Harte Grenze |
|---|---|---|---|
| **Google Drive** | ← liest | Projekt-Ordner, Dateien, Angebots-PDFs | Geteilter Drive nur **lesend**; Kopie nur in ausdrücklich genanntes Ziel |
| **Google Kalender** | ← liest | Termine (Projekt-/Team-Kalender) | Eintrag nur über Browser-Bestätigung, kein stiller API-Write |
| **Google Kontakte** | ← liest | Kontakt-Suche | read-only |
| **Google Mail** | ← liest | E-Mails, Labels (Suche) | **Senden noch nicht aktiv**; kein Auto-Versand |
| **Airtable — Mastermind** (`appuVMh3KDfKw4OoQ`) | ↔ liest & schreibt | Projekt-/Kunden-Routing, Datenstrom-Handbuch | Schreiben nur append/gated; **nie DELETE** |
| **Airtable — Artikel/Daniel** (`appdxTeT6bhSBmwx5`) | ← liest | Preisliste, Artikel | **Nur lesen. Daniels Bestand nie ändern/löschen.** |
| **Clockodo** | ← liest *(Buchen geplant)* | Zeiteinträge, Stundensätze | **Datensensitiv → Private Area, nur eigene Daten** |
| **ClickUp** | ↔ liest & schreibt | Aufgaben je Projekt | Schreiben **nur im Testspace `90128024109`**, Ghost-Namen, keine echten Zuweisungen/Notifikationen |
| **Sevdesk** | über Postbox | Ist-Umsatz / Belege | **Nie direkt** — weder lesend noch schreibend. Nur über die Einweg-Airtable-Postbox (append-only) |
| **Claude / Anthropic** | ↔ Assistent | Kontext rein, Vorschläge raus | Schreibaktionen nur bestätigt; API-Key im Schlüsselbund |

---

## Ins & Outs

**Was hineinkommt (Lesen):** Drive-Dateien, Kalender, Kontakte, Mail, Airtable-Projekte/-Artikel, Clockodo-Zeiten (eigene), ClickUp-Aufgaben, Sevdesk-Belege (nur über Postbox).

**Was hinausgeht (Schreiben):** in die **eigene** Airtable-Mastermind-Base (Projekte/Kunden/Warenkörbe, gated), in den **ClickUp-Testspace** (Ghost), ins **lokale** GRDB + Audit-Log. Jeder Schreibvorgang läuft über einen Store, ist sichtbar (SaveState) und protokolliert.

**Was NIE hinausgeht:**
- Kein direkter Sevdesk-Zugriff (nur Postbox).
- Kein DELETE in Airtable — Inaktivierung nur über Status-/Archiv-Feld.
- Kein Schreiben in Daniels Artikel-Base.
- Keine externe Mail/Notifikation ohne ausdrückliche Bestätigung.

---

## Globale Limits & Schranken

- **Airtable:** 100.000 API-Aufrufe/Monat · max. 5 Aufrufe/Sekunde je Base · 50.000 Datensätze je Base. Automatische „aiText"-Felder werden vermieden (kosten KI-Credits).
- **Polling gedrosselt:** Hintergrund-Abfragen (z. B. Drive-Wächter) laufen in ruhigen Intervallen, nicht permanent.
- **Assistent (LLM):** Token-Verbrauch je Antwort im Blick; Kontext schlank, Prompt-Caching. Kosten sind ein Design-Kriterium.
- **Keine Automatik nach außen:** Mail-Versand und Benachrichtigungen sind immer bestätigungspflichtig.

---

## Je Nutzer (Datenschutz-Grenzen)

- **Geheimnisse pro Person isoliert:** jeder Token/API-Key liegt im eigenen Schlüsselbund-Fach (`com.mykilos6.<dienst>.<userID>`), nie teamweit geteilt.
- **Private Bereich:** Clockodo-Zeiten, Stundensätze und persönliche Zugänge sind **ausschließlich nutzereigen** — nie in geteilten Logs, nie für andere sichtbar.
- **Keine Quer-Einsicht:** Mail, Notizen und Assistent-Chat einer Person sind für andere Teammitglieder **nie** lesbar. Der Assistent spricht Kolleg:innen nie an, als wäre er der Nutzer.
- **Admin nur mit Zustimmung:** ein Admin-Zugriff auf fremde Daten geht nur mit **aktiver Freigabe der betroffenen Person** im Moment (2FA-artig) — kein stehender Hintertür-Zugang.
- **Geteilt vs. privat:** Drive, Kalender, ClickUp und Airtable-Projekte sind fürs Team sichtbar. Persönliche Daten (Clockodo, eigene Tokens) sind es nie.

---

*mykilOS ist so gebaut, dass jede Person dem Werkzeug blind vertrauen kann: die eigenen Daten bleiben die eigenen, nach außen geht nur, was ausdrücklich bestätigt wurde, und die teuersten/riskantesten Wege (Sevdesk, Löschen, fremde Bestände) sind hart verriegelt.*
