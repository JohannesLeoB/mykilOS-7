# Offene Zusagen — der ehrliche Stand

**Verankert 2026-07-07 (Johannes, nach wiederholtem Frust: "wieso wird permanent etwas, was ich
klar und deutlich sage, einfach vergessen oder NICHT ANSATZWEISE UMGESETZT???").**

Dieses Dokument ist KEIN Ideen-Sammelbecken (das ist `docs/IDEEN_UND_BACKLOG.md`, bewusst stumm).
Hier stehen NUR Dinge, die Johannes konkret angefragt oder die eine Session konkret zugesagt hat —
mit **verifiziertem** Stand, nicht mit Erinnerung, nicht mit Wunschdenken, nicht mit "Tests grün"
als Beweis. Der Unterschied ist der ganze Sinn dieser Datei.

## Pflicht-Prozess (nicht verhandelbar)

1. **Jede Session liest diese Datei ZUERST**, direkt nach PROZESS_LESSONS.md.
2. **Jede Session, die an einem Punkt arbeitet, aktualisiert den Status hier SOFORT** — nicht
   "irgendwann", nicht am Session-Ende, sondern in dem Moment, in dem sich der echte Stand ändert.
3. **Status ist verifiziert, nicht behauptet.** 🔴 Nicht gebaut / 🟡 Teilweise gebaut (mit genauer
   Angabe was fehlt) / ✅ Gebaut UND von Johannes live geprüft. "Build/Tests grün" ist NIE allein
   Grund für ✅ — das beweist nur, dass der Code nicht kaputt ist, nicht dass die Aufgabe erledigt ist.
4. **Kein Punkt verschwindet stillschweigend.** Wird etwas zurückgestellt, bleibt der Eintrag stehen
   mit Begründung — nie einfach gelöscht, weil er unbequem ist.

---

## 🔴 Aufmaß-Widget (Mac)

**Zugesagt:** 2026-07-06, voller Plan in `docs/handoffs/AUFMASS_WIDGET_PLAN.md`.
**Ist-Stand (verifiziert 2026-07-07):** 0 % in mykilOS macOS gebaut. Von den 5 Bausteinen im Plan
sind nur zwei bereits vorhanden — und beide woanders: das Overlay-Zeichnen-Muster
(`ProjectHeroView.swift`, Fadenkreuz-Picker) und das Laser-/Disto-Protokoll (im **iOS-Satelliten**,
anderes Repo — nicht portiert). Bluetooth-Kopplung, Foto-Empfang iPhone→Mac, die eigentliche
Aufmaß-Canvas und die Persistenz sind alle **🔴 Neubau**, laut der Tabelle im Plan-Dokument selbst.
**Blockiert auf:** Johannes' Entscheidung zum Laser-Modell (Leica Disto welches?) + einem echten
Gerät für den Hardware-Test (kann keine Agenten-Session simulieren).

## 🔴 ClickUp-Aufgaben "wirklich sortieren" — JETZT DEFINIERT (2026-07-07, Johannes)

**Definition (Johannes, wörtlich):** "in Spalten sortieren, sauber in den 'Aufgaben' und auf dem
Übersichts-Hauptscreen zeigen." Konkret: Kanban-artige Spalten (nach Status), sichtbar sowohl im
Aufgaben-Tab (`ClickUpAufgabenSpalte.swift`) ALS AUCH auf dem Haupt-Übersichtsbildschirm (Heute/
Today), nicht nur als Filterliste.
**Ist-Stand:** Nur Filtern (Meine/Alle, Projekt, Prio, Fälligkeit) — KEINE Spalten-/Kanban-Ansicht,
weder im Aufgaben-Tab noch auf der Übersicht. 🔴 Nicht gebaut.

## 🔴 ClickUp-Bearbeitbarkeit + Zuweisen — Johannes 2026-07-07, mit Nachdruck

**Zugesagt/gefordert (Johannes, wörtlich):** "WO IST DIE VERDAMMTE BEARBEITBARKEIT??? ZUWEISEN UND
ERSTELLEN VON AUFGABEN???"
**Ist-Stand, ehrlich aufgeschlüsselt (verifiziert 2026-07-07):**
- Aufgabe **erstellen**: ✅ gebaut (TasksWidget, gegen Testspace-/Go-Live-Gate), aber noch nicht
  von Johannes live geprüft.
- Status **ändern**: ✅ gebaut, gleiches Gate, noch nicht live geprüft.
- **Bearbeiten** (Fälligkeitsdatum, Priorität, Titel, zwischen Listen verschieben, Custom Fields):
  🔴 nicht gebaut. Nur Status + Neuanlage existieren.
- **Zuweisen** (echte ClickUp-Assignees, MENSCH-initiiert über die UI mit Bestätigung — nicht die
  KI, die weist nie zu, das bleibt eiserne Regel): 🔴 nicht gebaut. Bisher bewusst ausgeschlossen,
  weil ohne Go-Live-Freigabe jede Zuweisung eine echte Benachrichtigung an eine echte Person
  auslösen würde. Mit der heute gebauten Go-Live-Whitelist (S10) ist die technische Grundlage für
  ein SICHERES, whitelist-beschränktes Zuweisen jetzt vorhanden — der Zuweisen-Schreibpfad selbst
  ist aber noch nicht gebaut.
**Nächster Schritt:** Bearbeitbarkeit (Fälligkeitsdatum/Priorität mind.) + ein Mensch-bestätigter
Zuweisen-Pfad (gegen dasselbe Gate wie Status/Anlegen) sind die nächsten konkreten Bausteine.

## 🔴 Assistent-Grounding-Gate (S0) — KRITISCH, mit akutem Vorfall

**Zugesagt:** 2026-07-07, als "FUNDAMENT, zuerst" in `docs/handoffs/CLICKUP_IO_ARCHITEKTUR_PLAN.md`
§0, nach einem ersten dokumentierten Vorfall (Assistent erfand eine Mail-Adresse).
**Ist-Stand:** Nicht gebaut. Es gibt nur `AssistantGrounding` (System-Prompt-Kontext, eine
Prompting-Maßnahme) — NICHT den beschriebenen strukturellen Beleg-Speicher/Grenz-Validator, der
unbelegte Werte im Engine-Code (nicht nur per Prompt) zurückweist.
**Akuter Vorfall (2026-07-07, Johannes):** "mein Assistent in der App lügt auch" — ein zweiter,
noch nicht im Detail erfasster Vorfall. **Nächster Schritt: mit Johannes den genauen Fall
festhalten** (was hat der Assistent behauptet, was war die Wahrheit), dann S0 danach bauen, nicht
raten.

---

## Warum diese Datei existiert

Am 2026-07-07 wurde wiederholt "Tests grün, Build grün" als Fortschritt gemeldet, während drei
konkrete Zusagen (Aufmaß, ClickUp-Sortierung, volle ClickUp-Fernsteuerung) faktisch nicht oder nur
teilweise umgesetzt waren, verstreut über mehrere Plan-Dokumente, die niemand zusammenhielt. Diese
Datei ist die Konsequenz: EIN Ort, EHRLICH, PFLICHT zu lesen und zu pflegen.
