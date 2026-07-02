# Slack-Archiv → ClickUp Rekonstruktion — Plan + Autonomer Start 4:30 Uhr

**Erstellt: 2026-07-02, 03:13 CEST · Autor: Claude (Sonnet 5), im Auftrag Johannes.**
Auftrag (verbatim): „Das Slack Archiv in ClickUp komponieren und die Slack-Archive und darin
enthaltene Projekte, die aktuell auch in der Drive in Projekte liegen, analysieren, Aufgaben und
Projekte nachbilden inkl. Aufgaben und vergangenen Aufgaben und Meilensteinen. Als wäre Slack nie
gewesen und die Projekte in ClickUp abgewickelt."

**Gilt uneingeschränkt: [GHOST_PERSONA_REGEL.md](GHOST_PERSONA_REGEL.md)** — nur Testspace
`90128024109`, nie eine echte ClickUp-Assignee-ID, simulierte Zuweisung nur als Ghost-Kürzel
(Jo/Da/Fra/Sen/Jil) im Klartext der Task-Beschreibung, keinerlei echte externe Notifikation.

---

## 1. Quellen

- **Slack-Roh-Export:** `~/Downloads/Studio_Beratung_Slack_Analyse_HANDOFF.zip` →
  `SESSION_HANDOFF/files/original/SLACK Export DATA(1).zip` — Standard-Slack-Export-Format
  (ein Ordner je Kanal, `YYYY-MM-DD.json`-Nachrichtendateien, `channels.json`, `users.json`).
  266 Kanal-Ordner gesamt.
- **Abgeleitete Übersicht (schnell, ohne Neuextraktion nutzbar):**
  `SESSION_HANDOFF/tables/channel_inventory.csv` — Kanal, Typ, Nachrichtenzahl, Datei-Referenzen,
  Datumsspanne, Top-Begriffe je Kanal. 96 als „Projektkanal" erkannt (Präfix `p_<region>_<kunde>_<user>`).
  `SESSION_HANDOFF/tables/term_signal_counts.csv` — Signalwort-Interpretationsregeln (nur
  Start-/Kontext-Hinweis, nie blind als Befund übernehmen).
- **Echte Drive-Projektordner** (Root `1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST`, 34 Ordner via
  Drive-MCP `search_files` mit `parentId = '1Q-H_3JsZfiXosFmxtNgoy0hI3cvZLgST'` abgerufen).

## 2. Abgleich Slack-Kanal ↔ echter Drive-Ordner (deterministisch, Namens-Matching)

**15 von 96 Projektkanälen** sind eindeutig einem AKTUELL in Drive liegenden Projekt zuordenbar
(die übrigen 81 gehören zu Projekten ohne aktuellen Drive-Ordner — vermutlich im bewusst
zurückgestellten `_PROJEKTE_ARCHIV`, NICHT in dieser Runde anfassen):

| Slack-Kanal | Drive-Ordner | Nachrichten | Zeitraum |
|---|---|---:|---|
| `p_hh_fuckner_huetter_se` | `2023_010_Fuckner_Huetter_HOF55` | 478 | 2025-01-03..2026-06-17 |
| `p_l_benjamin_jb` | `2025_014_BenjaminMartin_FUN16` | 426 | 2025-11-03..2026-06-18 |
| `p_hh_neuhaus_dk` | `2024_021_Neuhaus_HOC32` | 331 | 2025-01-03..2026-06-08 |
| `p_hh_heimhuder8_jb` | `2025_001_Heimhuder8_HEI8` | 232 | 2025-01-21..2026-05-11 |
| `p_hh_doehle_dk` | `2024_007_Doehle` | 185 | 2025-01-02..2026-04-20 |
| `p_schw_schneider_dk` | `2025_021_Schneider_DWA27` | 182 | 2025-12-01..2026-06-09 |
| `p_hh_junge_dk_jlb_jb` | `2026_017_JungeSchultzendorff_WRA51` | 169 | 2026-01-15..2026-06-02 |
| `p_hh_neurologie_vinahl_jlb` | `2026_004_Neurologie_Uetersen_GRO50` | 133 | 2026-01-22..2026-06-15 |
| `p_hh_rodewyk_jb` | `2025_018_Rodewyk_FLO32` | 116 | 2025-11-21..2026-06-17 |
| `p_hh_wartenberg_joh` | `2025_022_Wartenberg_ALS46` | 102 | 2025-11-04..2026-06-17 |
| `p_hh_may_heimhuder64` | `2025_015_May_HEI64` | 70 | 2025-11-10..2026-06-09 |
| `p_hh_nathalie_mohadjer` | `2026_025_Mohadjer_PAR` | 13 | 2026-05-20..2026-06-01 |
| `p_mykilos_serienku_che_joh` | `2026_001_MYKILOS_Serienkueche` | 9 | 2026-01-06 |
| `p_hh_schneider_jo` | `2025_021_Schneider_DWA27` (Duplikat-Kanal, alt) | 4 | 2025-01-06..2025-05-24 |
| `p_b_marschner_ps` | `2025_021_Schneider_DWA27` (Fehlzuordnung, prüfen) | 1 | 2025-05-13 |

Matching-Skript (reproduzierbar, python3, keine externen Deps) lag im Sitzungs-Scratchpad —
bei Bedarf neu ableiten: Kanalname-Mittelteil (zwischen Präfix und User-Kürzel) normalisiert
(nur a-z0-9) gegen normalisierten Drive-Ordnernamen als Teilstring-Match.

**Die letzten beiden Zeilen (`p_hh_schneider_jo`, `p_b_marschner_ps`) sind schwach/fraglich**
(Kollision auf denselben Drive-Ordner wie `p_schw_schneider_dk`, sehr wenige Nachrichten) —
**im ersten Durchlauf auslassen**, nur die oberen 11 eindeutigen, nachrichtenreichen Matches
bearbeiten.

## 3. Entschieden (Claude, da Rückfrage technisch fehlschlug — reversibel, im Rahmen der
erteilten Testspace-Vollmacht, dokumentiert statt stillschweigend)

1. **Zielort:** neuer, dedizierter ClickUp-Ordner **„88 Slack-Archiv (historisch)"** im
   Testspace (`90128024109`) — NICHT vermischt mit den echten, aktiven Projekten in
   „01 Kundenprojekte". Begründung: 11 Projekte auf einmal in die aktive Liste zu kippen würde
   die Übersicht für echte, laufende Arbeit stören; ein eigener Ordner ist jederzeit prüf-/
   löschbar und macht „das ist eine Rekonstruktion" auf einen Blick klar.
2. **Umfang Start 4:30 Uhr: NUR 1 Pilotprojekt** (`Doehle`, 185 Nachrichten — mittlere Größe,
   guter Kompromiss aus Aussagekraft und Prüfaufwand), NICHT alle 11 auf einmal. Nach dem Piloten
   pausieren und Ergebnis für Johannes sichtbar machen (nicht stillschweigend weiterziehen) —
   „kontrollierter Start" heißt: einen geprüften Baustein liefern, nicht die ganze Nacht
   unbeaufsichtigt durchschreiben.

## 4. Ablauf je Projekt (Pilot + spätere 10)

1. Rohe Slack-Nachrichten des Kanals lesen (`<kanal>/YYYY-MM-DD.json`, Format: Array von
   `{user, type, text, ts, ...}`; `user_profile.name` enthält oft schon das Kürzel z. B. `jo`).
2. Signale extrahieren nach der bestehenden Methodik (siehe `term_signal_counts.csv` +
   Studio-OS-Handoff §13.1): Aufgaben-Muster („bitte", „kannst du", „müssen wir"), Blocker
   („offen", „fehlt", „wartet auf"), Status/Meilenstein („freigegeben", „bestellt", „bezahlt"),
   Finance („Rechnung", „Anzahlung", „Schlussrechnung"), Akte/Datei-Signal („Drive", „hochgeladen").
   Jeder Fund bekommt einen Beweisgrad (stark/mittel/schwach/konflikt) — NIE ein Signalwort
   blind als Task übernehmen, nur explizite, im Kontext eindeutige Aufgaben/Meilensteine.
3. In ClickUp anlegen (im Ordner „88 Slack-Archiv (historisch)"):
   - Eine Liste je Projekt, Name = `<Drive-Ordnername>` (z. B. `2024_007_Doehle`), Beschreibung
     nennt Quelle „Rekonstruiert aus Slack-Archiv (Kanal `p_hh_doehle_dk`), historisch, keine
     Live-Synchronisation" — klar als Rekonstruktion gekennzeichnet, auch wenn strukturell wie
     ein normales Projekt.
   - Tasks = extrahierte Aufgaben/Meilensteine, chronologisch, **Status meist „Erledigt"**
     (es sind vergangene, abgeschlossene Vorgänge) außer erkennbar offene Punkte.
   - **Ghost-Zuweisung** falls aus dem Slack-Text ein Verantwortlicher erkennbar ist: als
     Klartext-Zeile in der Task-Beschreibung (`Ghost-Zuweisung (simuliert, NICHT real): Jo`),
     NIE über das `assignees`-Feld (Eiserne Regel).
   - Fälligkeitsdatum NUR falls aus dem historischen Kontext ableitbar (z. B. Montagetermin
     genannt) — ohne echten Assignee unkritisch (siehe Ghost-Persona-Regel §4).
4. Nach dem Piloten: kurzer Bericht (was wurde angelegt, wie viele Tasks, welche Beweisgrade,
   Stichproben-Zitate) — KEIN automatisches Weiterziehen zu den restlichen 10 ohne Prüfung.

## 5. Für die 4:30-Uhr-Session — Startprompt-Kern

```
Lies zuerst CLAUDE.md (Eiserne Regeln, insbesondere Ghost-Persona) und
docs/ops-clickup-mykilos8/SLACK_RECONSTRUCTION_PLAN.md vollständig.
Extrahiere ~/Downloads/Studio_Beratung_Slack_Analyse_HANDOFF.zip neu in den Scratchpad
(der alte Scratch von 03:13 Uhr existiert in dieser Session nicht mehr).
Baue GENAU EIN Pilotprojekt (Doehle, Kanal p_hh_doehle_dk ↔ Drive-Ordner 2024_007_Doehle)
gemäß Abschnitt 4 des Plans. Danach STOPPEN und einen klaren Bericht liefern — nicht mit
den restlichen 10 Projekten weitermachen. Ghost-Persona-Regel gilt ausnahmslos.
```

## 6. Offen für Johannes (nach dem Piloten zu entscheiden, nicht vorher)

- Qualität/Format des Piloten prüfen — passt der Detailgrad?
- Danach: alle 10 restlichen bearbeiten, oder weitere anpassen?
- Die zwei fraglichen Kanäle (`p_hh_schneider_jo`, `p_b_marschner_ps`) — ignorieren oder klären?
