# Staub-Kartierung — Flugroute durch die Airtable-Milchstraße

**Vorbereitet 2026-07-03 spät · wartet auf Johannes' Connector-Klick.**
Epistemik: Alles hier ist Sternenstaub in Verdichtung, kein Kanon (Johannes).
Lese-Modus: schema-tolerant, verstehen statt bewerten, Bedeutung > Layout.

## Bekannte Nebel (aus Schiffs-Doku `@dababdb`, read-only erhoben)

| Base | ID | Erwartung | Satelliten-Frage |
|---|---|---|---|
| **Mastermind** | `appuVMh3KDfKw4OoQ` | System-of-Record: Kunden/Projekte/Clockodo-*/Kalkulation/Datenstrom-Handbuch | Wo liegen **Adressen**? (Adress-Lücke fürs „Hinfahren") · Wie sieht der Projekt-Graph live vs. Git-Kopie aus? |
| **Adapter Clockodo** ★1 | `appuQDCFGLmjo2L6T` | Zeitbuchungen (`tbllYkxcHzI2YMUqn`), „Vorgebucht", append-only | Exakte Felder für Playbook 02 (Schema abschreiben) |
| **Backup Base** | `app56DTbSoqPvZhom` | Write-Shadow-Log, live (Block A) | Nur verstehen — Muster für Satelliten-Writes? |
| mykilOS_Projekte | `appWI2qj9cc6Muu3b` | „Buchhaltungs-Share", fast leer + 1 DEPRECATED | Nur Inventur |
| mykilOS_Onlineshop & Verkauf | `app2XOhOxXfkLtGVC` | ungeprüft | Nur Inventur |
| mykilOS_Fragebogen & Projekt IN | `appYE7GnC4bcfTBTX` | ungeprüft | Intake-Bezug? (Playbook-04-Nähe) |
| mykilOS_Handelswaren | `appDj4wH4WDQfziDZ` | leer | Nur Inventur |
| mykilOS_TRESOR | `appyD6BxJ5Qw9p98V` | ? | Nur Inventur — klingt nach Secrets-Nähe: besonders vorsichtig, nichts zitieren |
| mykilOS_Datenweichen | `appGugtieBPgbIekk` | Datenstrom-Handbuch-Nähe | Weichen-Verständnis |
| mykilOS_App Entwicklung | `appfPsOHxuGbQBQ6y` | Dev-Notizen | Nur Inventur |

## Tabu-Zonen (werden NICHT angeflogen)

- `appkPzoEiI5eSMkNK` — alte geteilte Base: **„nie anfassen"** → wir lesen sie nicht mal.
- `appdxTeT6bhSBmwx5` — Daniels Artikel-DB: nur-lesen wäre erlaubt, aber ohne konkreten
  Anlass bleiben wir draußen (fremde Werkstatt).

## Ablauf (wenn die Schranke offen ist)

1. `list_bases` — stimmt die Karte? Gibt es unbekannte Nebel?
2. Je Base: `list_tables_for_base` (nur Schema, keine Massen-Records).
3. Records nur dort, wo eine Satelliten-Frage es braucht (Adressen, Zeitbuchungen-Felder).
4. Befunde → Star Map; Playbook 02 bekommt die echten Feld-Namen.
5. **Keine Writes. Nirgends. Nie.** (Airtable-Connector wird ausschließlich lesend benutzt.)

## ⚠️ Befund 2026-07-03 ~23:30: Freigabe-Kanal dieser Session defekt

Mehrere Airtable-Aufrufe scheiterten sofort mit „requires approval", ohne dass bei
Johannes je ein Freigabe-Dialog erschien. Gleiches Muster wie die allererste
Frage-Karte der Session („Tool permission stream closed"). → Kein Bedienfehler;
der Prompt-Kanal dieser Session ist gebrochen.

**Plan:** Durchmusterung in einer FRISCHEN Session fliegen. Dort beim ersten
Airtable-Aufruf die Freigabe („immer erlauben") setzen. Diese Flugroute + der
Briefkasten-Ledger + die Basis-Sicherung machen das Andocken nahtlos.

**Nachtrag Nacht 03./04.07.:** Auch `send_later` (Wecker/Trigger) scheitert am
defekten Freigabe-Kanal dieser Session — Morgen-Brief-Automatik ebenfalls auf
frische Session vertagt. Dort dann beide Freigaben in einem Rutsch setzen
(Airtable lesen + Scheduling).
