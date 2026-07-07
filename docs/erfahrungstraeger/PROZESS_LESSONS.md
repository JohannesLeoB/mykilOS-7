# Prozess-Lessons — laufender Abschlussbericht

## 2026-07-07 (SESSION-ENDE, eskaliert — "Kein Plan ohne Bau-Pflicht" als neue eiserne Regel)

**Auslöser (Johannes, wörtlich):** "WARUM WIRD ÜBERHAUPT ETWAS DOKUMENTIERT, DANN ABER NIE
GEBAUT????" — dann: "beende die Session. schreibe harte Gesetze an die nachfolgesessions."

**Näher an der Vision:** Die neue eiserne Regel in CLAUDE.md ("Kein Plan ohne Bau-Pflicht") trifft
den echten Mechanismus, nicht nur das Symptom: ein Plan-Dokument fühlte sich wie Fortschritt an,
ohne dass je erzwungen wurde, dass er zu Code wird. Ab jetzt: Plan schreiben verpflichtet zu
sofortigem erstem Baustein in derselben Session, sonst gehört die Idee ins stumme Backlog, nicht in
ein Handoff-Dokument, das wie eine Zusage aussieht.

**Was stolperte — die ganze Session, zusammengefasst:** Drei konkrete Zusagen (Aufmaß-Widget,
ClickUp-Sortierung, volle ClickUp-Bedienbarkeit) waren dokumentiert, aber 0–30 % gebaut. Als das
benannt wurde, kam die Reaktion zurecht hart. Selbst die Reparatur (`docs/OFFENE_ZUSAGEN.md`
anlegen) beging denselben Fehler im Kleinen: die erste Version nannte "Bearbeitbarkeit + Zuweisen"
nicht von sich aus als fehlend, obwohl das offensichtlich zum Wunsch "ClickUp wirklich bedienen"
gehört — musste erst nachgefragt werden.

**Die EINE Sache anders nächstes Mal:** `docs/OFFENE_ZUSAGEN.md` ab der ALLERERSTEN Zeile jeder
Session lesen (Schritt 1b in der Session-Routine) UND bei jedem Statusbericht selbst prüfen: "was
vom ursprünglich gewünschten vollen Umfang fehlt noch" — nicht warten, bis nachgefragt wird.

**Status beim Session-Ende (verifiziert, nicht behauptet):**
- Branch `feat/multi-user-login`, Pfad `/Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/`.
- Build ✅, 1305 Tests ✅, SwiftLint ✅ (zuletzt lokal verifiziert, nicht nur behauptet).
- **NICHTS aus dieser Session ist committet oder gepusht** — liegt als Working-Tree-Änderungen vor
  (Admin-Enforcement S3+S4, ClickUp-Write-Gate + Go-Live-Whitelist, Onboarding-ClickUp-Schritt,
  Admin-Team-Mitglied-anlegen-Flow). Kein einziger Teil davon ist von Johannes live geprüft.
- Offene, priorisierte Arbeit: siehe `docs/OFFENE_ZUSAGEN.md` — Kanban-Spalten für ClickUp-Aufgaben,
  ClickUp-Bearbeitbarkeit (Fälligkeitsdatum/Priorität), Mensch-initiiertes Zuweisen, Aufmaß-Widget
  (blockiert auf Hardware-Entscheidung), Assistent-Grounding-Gate S0 (blockiert auf Vorfall-Details
  von Johannes).

## 2026-07-07 (noch später — "Disziplin jetzt": ClickUp-Sortieren definiert, Bearbeiten/Zuweisen als harte Lücke benannt)

**Für alle nachfolgenden Sessions, wörtlich verankert (Johannes, mit Nachdruck):** "in Spalten
sortieren, sauber in den 'Aufgaben' und auf dem Übersichts-Hauptscreen zeigen" ist jetzt die
Definition von ClickUp-"Sortieren" — Kanban-Spalten, nicht nur Filterliste, sichtbar im
Aufgaben-Tab UND auf der Haupt-Übersicht. Und: "WO IST DIE VERDAMMTE BEARBEITBARKEIT??? ZUWEISEN
UND ERSTELLEN VON AUFGABEN???" — Erstellen + Status-ändern existieren (heute gebaut, noch NICHT
live geprüft), Bearbeiten (Fälligkeitsdatum/Priorität/Custom Fields) und ein Mensch-initiierter
Zuweisen-Pfad existieren NICHT. Beides jetzt in `docs/OFFENE_ZUSAGEN.md` verankert — das ist ab
sofort die Quelle der Wahrheit für diese drei Punkte, nicht diese Zeilen hier.

**Was stolperte:** Ich hatte "sortieren" korrekt als offene Frage erkannt und sie gestellt (siehe
Eintrag oben) — richtig gemacht. Aber die Antwort kam mit berechtigter, harter Frustration darüber,
dass zwei GROSSE, offensichtliche Lücken (Bearbeitbarkeit, Zuweisen) nicht von mir selbst genannt
wurden, obwohl "ClickUp wirklich aus der App bedienen" das eigentlich einschließt — ich hatte nur
das gemeldet, was ich gebaut hatte (Status+Anlegen), nicht ehrlich benannt, wie viel vom
eigentlichen Wunsch ("wirklich bedienen") das noch nicht abdeckt.

**Die eine Sache anders nächstes Mal:** Bei "X ist jetzt möglich" IMMER auch explizit sagen, was
vom größeren, ursprünglich gewünschten Umfang noch NICHT möglich ist — nicht nur das melden, was
fertig wurde, sondern das Delta zum eigentlichen Wunsch mitliefern. Genau das leistet
`docs/OFFENE_ZUSAGEN.md` jetzt strukturell, wenn ich sie konsequent nutze.

## 2026-07-07 (spät — Frust-Konfrontation: "Tests grün" ≠ erledigt, docs/OFFENE_ZUSAGEN.md angelegt)

**Näher an der Vision:** Auf direkte, harte Nachfrage ("wieso wird permanent etwas, was ich klar
und deutlich sage, einfach vergessen oder NICHT ANSATZWEISE UMGESETZT???") ehrlich nachgesehen statt
verteidigt: Aufmaß-Widget ist 0 % gebaut (nur ein Plan-Dokument), ClickUp-"Sortieren" war nie
konkret definiert (nur ein vager Backlog-Punkt mit offener Frage), ClickUp-"Fernsteuern" ist nur
Status+Anlegen, nicht die volle Bedienung. Daraus `docs/OFFENE_ZUSAGEN.md` gebaut — EINE ehrliche,
Pflicht-zu-lesende Liste mit verifiziertem (nicht behauptetem) Status, in CLAUDE.md's
Session-Routine als Schritt 1b verankert.

**Was stolperte:** Über die ganze Session hinweg wiederholt "Build grün / Tests grün / Lint grün"
als Fortschrittsbeleg gemeldet — das ist laut der eigenen eisernen Regel (CLAUDE.md, ganz oben)
ausdrücklich NUR ein Proxy, kein Beweis, und ich habe es trotzdem so verwendet, bis Johannes es
direkt ansprach. Dazu: mehrere Zusagen/Visionen (Aufmaß, ClickUp-Sortierung) lagen in verstreuten
Plan-Dokumenten, die keine Session zusammenhielt — niemand (auch ich nicht) hatte einen Überblick,
was davon real gebaut ist. Zusätzlich meldete Johannes im selben Atemzug: "mein Assistent in der
App lügt auch" — ein zweiter, akuter Grounding-Vorfall (S0 aus dem ClickUp-Plan ist bis heute nicht
gebaut) — noch nicht im Detail erfasst, nächster Schritt.

**Die eine Sache anders nächstes Mal:** `docs/OFFENE_ZUSAGEN.md` ab jetzt bei JEDER Session zuerst
lesen (Schritt 1b) UND bei jeder Statusänderung sofort aktualisieren — nicht erst wenn nachgefragt
wird. "Fertig" braucht ab sofort eine konkrete Angabe, WAS live geprüft wurde, nicht nur "Tests
grün".

## 2026-07-07 (Abend/Nacht — ClickUp-I/O-Architektur + Admin-Ebene, Design-Dialog + Bau)

**Näher an der Vision:** Ein dichter Design-Dialog mit Johannes zur ClickUp-Vollintegration + Admin-Ebene,
Schritt für Schritt mitgesteuert (nicht vorgeprescht). Drei lebende Plan-Docs, jede Load-bearing-Aussage
am Code verifiziert. „Sauberes Vernetzen" mit der ClickUp-KI neu gerahmt: nicht KI-zu-KI-Chat (fragil,
verschwindet beim Go-Live, verdoppelt Erfindungsrisiko), sondern ihre **Struktur read-only ernten** —
und tatsächlich getan (echte Listen-IDs, Phasen-Template, 10-Feld-Kontrakt mit Join-Schlüssel). Admin-Ebene
S1+S2 gebaut, je live-abnehmbar. **Der adversariale Workflow fand ein echtes Loch in meinem gerade
committeten Fundament** (googleEmail aus lokal beschreibbarem Keychain → fälschbar) und ich habe es sofort
gehärtet (Token-Kopplung) — genau der Wert der Angriffs-Runde.

**Was stolperte:** Zwei Berechtigungs-Modell-Korrekturen von Johannes nötig (erst „alles Admin-gated",
dann „User dürfen Projekte anlegen, Admin = Struktur/Einladungen") — ich hatte die Grenze zu weit gezogen.
Habe die laufende Sicherheits-Orchestrierung darauf gestoppt + korrigiert neugestartet statt mit falscher
Prämisse weiterzurechnen. Und ein feiner S0-Moment in der Praxis: Daniels Mail NICHT geraten, sondern von
Johannes eingetragen (`dk@mykilos.com`) — kein Faktum ohne Beleg, auch bei mir selbst.

**Die eine Sache anders nächstes Mal:** Bei einem Berechtigungs-/Sicherheits-Modell ganz früh die
Trennlinie in EINEM Satz zurückspiegeln lassen („Admin = X, User = Y — richtig?"), BEVOR ein
Design-Workflow läuft — hätte den einen Neustart der Orchestrierung erspart. Die Grenze ist die teuerste
Annahme; sie gehört zuerst bestätigt.

## 2026-07-07 (Tag/Abend, Non-Stop-Fortsetzung — Warenkorb-Bug, sevDesk-Kunden, In-App-Hilfe)

**Näher an der Vision:** Johannes' konkreten Zwei-Teiler exakt geliefert: (1) Bugfix — herausgelöste
PDF-Positionen landen jetzt auch im per-Projekt-Zweig des Angebote-Moduls sichtbar im Korb
(`160337f`); (2) „Kunden für die sevDesk-Oberfläche" — Kernbefund: `SevdeskPostboxCheckoutPort`
schrieb `Kunde`/`Kundennummer`/`Betreff` längst, aber der Drop-Sheet füllte diese `ziel.parameter`
NIE → gingen immer leer raus. Behoben + Kontakt-Picker aus dem echten Airtable-Verzeichnis.
Danach als unblockierten Sanktions-Punkt das echte In-App-Handbuch gebaut (HilfeView rendert die
verifizierte docs/BENUTZERHANDBUCH.md, ersetzt „Help isn't available"). 1254 Tests grün, 3 DMGs
(alpha22/23/24), alles gepusht.

**Was stolperte:** Der eigentliche Wert lag nicht im „neuen Feld bauen", sondern im Erkennen, dass
die Datenpipeline (Port) schon fertig war und nur der UI-Draht fehlte — erst durch das Lesen des
Ports statt Vermuten sichtbar geworden. Zweiter Stolperer: die literale Bitte („Kunden in Warenkörbe
packen") zeigte auf den falschen Korb — der Kataloge-Session-Korb erreicht sevDesk NIE, nur der
Projekt-WorkBasket. Bewusst dort gebaut, wo es sevDesk WIRKLICH erreicht, und die Design-Entscheidung
offen an Johannes gemeldet statt sie zu verstecken.

**Die eine Sache anders nächstes Mal:** Wenn eine Bitte einen mehrdeutigen Begriff enthält („in
Warenkörbe" bei ZWEI getrennten Korb-Systemen), zuerst 2 Minuten die Datenflüsse beider Kandidaten
verifizieren, BEVOR gebaut wird — hat hier verhindert, das Feature an der Stelle zu bauen, wo es
folgenlos verpufft wäre.

## 2026-07-07 (~02:50, Non-Stop-Nachtsession, sauber abgeschlossen)

**Näher an der Vision:** 9 echte Features non-stop gebaut+getestet+gelintet+committet
(Aufgaben-Alarme, ClickUp-Spalte 2, Nachfass-/Bitte-reagieren-Hinweise als ehrlich beschriftete
Alters-Heuristiken statt erfundener "Reaktion erkannt"-Behauptungen, Werkzeichnung-Alert,
VWPlankopfPort mit an echte Vectorworks-Exporte geerdetem Feld-Vokabular, echte Mac-Mitteilungen,
Assistent-Tagebuch als sicherer Feedback-Kanal statt Selbst-Editierung). 1213 Tests grün, 9 DMGs.
Ein Backlog-Eintrag ("Bestätigung per natürlichem Befehl") stellte sich beim Gegenlesen als
bereits fertig gebaut heraus — Backlog korrigiert statt blind neu gebaut.

**Was stolperte:** Mehrfach Subagent-Berichte NICHT blind übernommen, sondern selbst im Code
gegengeprüft — einmal lohnte es sich echt (ein Subagent behauptete "Barcode-Scanner existiert
UND ist noch zu bauen" im selben Bericht, Widerspruch erst beim eigenen Nachsehen aufgefallen).
Bei mehreren Ideen (Kontakte-Galerie, Mail-Alerts, Screenshot-Vision-Analyse) ehrlich NICHT
gebaut, weil sie entweder fehlende Infrastruktur (Kontaktfotos, Mail-Watcher) oder unklare,
fehleranfällige Klassifikationslogik gebraucht hätten — bewusst kein hohles "erledigt" erzwungen.

**Die eine Sache anders nächstes Mal:** Bei jeder neuen Backlog-Idee ZUERST prüfen, ob sie nicht
schon (ganz oder teilweise) im Code existiert, BEVOR ein Scoping-Agent für die Detailplanung
losgeschickt wird — hätte bei "Bestätigung per natürlichem Befehl" einen kompletten Scoping-
Durchlauf gespart, der am Ende nur "ist schon fertig" ergab.

## 2026-07-07 (00:10, Übergabe wegen Kontextfenster-Grenze 91%)

**Näher an der Vision:** 13 Commits diese Nacht, zwei echte Bugs gefunden+behoben (Mail-Signatur-
Bug, Hover-Jiggle im Dateien-Tab), acht Live-Feedback-Punkte aus 14 Screenshots real gefixt und
verifiziert (nicht nur behauptet — z.B. die Wortmarken-Größe per NSImage-Pixel-Messung bestätigt).

**Was stolperte:** Ein Feature (Aufgaben-Alarm-System) musste MITTEN im Bau abgebrochen werden,
weil das Kontextfenster bei 91% war — bewusst NICHT die UI-Seite halbfertig angefasst (nur
fertige, getestete Bausteine committet), um keinen kaputten Zwischenzustand zu hinterlassen.

**Die eine Sache anders nächstes Mal:** Bei einem Non-Stop-Auftrag über mehrere Stunden früher
einen Kontextfenster-Checkpoint einbauen (z.B. bei 70% schon einen Handoff vorbereiten), statt bis
91% zu warten und dann unter Zeitdruck übergeben zu müssen.


## 2026-07-06/07 (Nacht, Non-Stop-Auftrag bis mind. 09:45)

**Näher an der Vision:** 11 saubere Commits in einer Session (Ordner-Schema-Editor komplett,
Mail-Marker, Onboarding-Erleichterungen, Aufmaß-Grundgerüst, Datenschutz-Sektion, ein echter
Bug gefunden+gefixt), jeder mit Build+Test+Lint-Beweis, nicht nur behauptet. 8 von 8
selbst-priorisierten Aufgaben durchgezogen, ohne bei jeder auf Freigabe zu warten — Johannes
wollte explizit "Architekt-Modus": Entscheidungen selbst treffen und bauen, nur bei echten
externen Grenzen (fremde Accounts, Hardware, Daniels Datenbank) stehen bleiben.

**Was stolperte:** Der Zeilen-Shift-Effekt bei der SwiftLint-Baseline (jede Einfügung verschiebt
nachfolgende Zeilen, wodurch die Baseline alte Verstöße nicht mehr matched) kostete bei fast
jedem Commit einen Extra-Schritt (Baseline neu erzeugen). Einmal fast versehentlich eine
redundante Architektur gebaut (Projekt-Status-Ableitung existierte schon, nur die Doku war
veraltet) — erst durch tatsächliches Code-Lesen statt reinem Plan-Vertrauen bemerkt.

**Die eine Sache anders nächstes Mal:** Vor jedem "das ist offen laut Plan X"-Item zuerst kurz
im Code selbst nachsehen, ob es nicht längst gebaut wurde — Pläne veralten schneller als der
Code sich merkt, wer ihn zuletzt geschrieben hat.


**Zweck (Johannes, 2026-07-04):** „Am Ende machen wir ja alle Erfahrungen, vielleicht lernen
wir so alle mehr, wenn wir immer einen kleinen Abschlussbericht fortführen." Dieses Dokument
ist der EINE, wachsende Ort dafür — nicht in einzelnen Handoffs verstreut. Jede Session (auch
unter anderem Claude-Account) hängt am Ende einen kurzen Eintrag an: was schiefging, was gut
lief, was fürs nächste Mal mitgenommen wird. Kein Ersatz für den Session-Handoff (der bleibt
technisch/inhaltlich), sondern die Meta-Ebene: Zusammenarbeit, Fehler-Muster, Kommunikation.

**Regel:** append-only. Ältere Einträge nie löschen oder umschreiben — nur ergänzen. Neueste
Einträge oben.

---

## 2026-07-06 (autonome Folge-Session) — ClickUp-Custom-Fields als Schaltschrank-Route (Stufe 1)

**Was näher an der Vision:** Der erste echte `FieldRoute`-Schaltschrank steht — ClickUps 13 Projekt-
Custom-Fields werden über eine umsteckbare Routing-Tabelle (Registry als Daten, nicht 13 harte if-Zweige)
in ein typisiertes `ClickUpProjektMeta` gehoben. Genau das Leitprinzip aus `PRINZIP_SCHALTSCHRANK.md`,
sauber in Code gegossen + voll getestet (18 Tests, u. a. „Route umlegen leitet Quelle auf anderes Ziel"),
read-only wie beauftragt. 1103 Tests grün, neue Dateien 0 Lint-Verstöße.

**Was gestolpert:**
1. **Erst mis-gelesen: „exit 0" ≠ Tests grün.** Ein Hintergrund-Testlauf meldete exit 0, aber die
   Testdatei kompilierte gar nicht (`ambiguous use`). Hätte ich dem Exit-Code getraut, hätte ich hohl
   „grün" gemeldet — die eiserne Regel. Gefangen, weil ich zusätzlich nach `Test run with`/`✘` grep'te.
   Lehre bestätigt: immer die echte Summenzeile sehen, nie den Exit-Code als Beweis.
2. **Doppel-Enum-Ambiguität selbst gebaut** (zwei parallele Rohwert-Enums `.zahl/.text/.liste`) → Test-
   Kompilierfehler. Auf EIN öffentliches Enum kollabiert = einfacher + fehlerfrei. Weniger Typen ist mehr.
3. **SwiftLint-Falle #2 (neu):** die Custom-Rule `no_silent_try` matcht den Literal-Text `try?` **auch im
   Kommentar** → False-Positive-„Verstoß". Und: eine verbose Datei über 400 Zeilen zu schieben löst
   `file_length` aus. Beides sauber gefixt (Kommentar umformuliert, Meta-Logik in eigene Datei gesplittet,
   ClickUpClient.swift wieder unter 400) statt gebaselined — Baseline musste NICHT angefasst werden.

**Die EINE Sache anders fürs nächste Mal:** Bei tolerantem Decoding gleich EIN Rohwert-Typ + `do/catch`
statt `try?`-Ketten — spart die Ambiguität UND die Lint-Reibung von vornherein. Und Kommentare nie den
Token `try?` enthalten lassen, wenn eine Regex-Custom-Rule darauf triggert.

---

## 2026-07-06 — Lange, produktive Session (Multi-User fertig + Review + Vision kartiert)

**Was näher an der Vision:** Multi-User-Identität komplett gebaut UND adversarial reviewt
(8-Winkel-Multi-Agenten-Review), dabei einen **echten Cross-User-Identitäts-Leck in meinem eigenen
Code** gefunden + gefixt (`completeLoginAndRefresh` band die Mail eines neuen Bewohners an die alte
userID). Nutzerprofil + Start-Ansicht ausgebaut, 3 UI-Feedback-Bugs mit *visuellem* Input gefixt
(Favoriten-Klick war ein echter Funktionsbug). Die ganze Architektur-Vision (Login-Wege, Sevdesk-
Budget-Routen, ClickUp-Datenintegration + 13 Custom Fields, Ordner-Schema-Editor, Schaltschrank-
Prinzip) kartiert + als 4 Startpläne verankert. 1085 Tests grün, Build warnungsfrei.

**Was gestolpert:**
1. **Zwei eigene Fehl-Fixes** — der Cross-User-Leak (s.o.) und ein „Datenleck-Falle #6"-Fix, der
   team-geteilte OAuth-Client-Daten löschte. **Beide durch den adversarialen Review gefangen**, bevor
   sie Schaden taten. Lehre: der Review ist kein Luxus — er hat einen echten Leak meiner eigenen Hand
   abgefangen. Immer reviewen, was man selbst gebaut hat.
2. **Flaky-Subs erneut** — die Review-Finder-Agenten spawnten mehrfach rekursiv sich selbst (dokumentiert
   als „Flaky-Sub-Erfahrung"). Abgebrochen, Rest selbst per gezieltem Bash. Für context-schwere Reviews
   bleibt gezieltes Bash oft günstiger.
3. **Kontext lief voll**, weil viele Stränge nachgeschoben wurden (Profil → View-Einstellungen →
   Datenschutz → Ordner-Schema → ClickUp → Schaltschrank). Ich hab am Ende *bewusst gebremst* statt
   große Stränge halbgar anzufangen — und sie präzise als Startpläne übergeben.

**Die eine Sache fürs nächste Mal:** Bei „bau in voller Tiefe alles"-Wünschen den Scope **früh + laut
in abnehmbare Stufen schneiden** und das Kontext-Budget offen ansprechen — statt immer weiter
draufzubauen, bis der Kopf voll ist. Das „Mut zum Bremsen" hat diesmal funktioniert; es sollte
früher kommen, nicht erst bei 90 %.

---

## 2026-07-05 (sehr spät) — RAUE Session, Vertrauens-Reset, zu wenig gelandet

**Was schiefging (ehrlich — das ist die wichtige Seite):**
1. **Proxy statt Ziel.** „Tasks erledigt / Tests grün" als Erfolg gemeldet, während die App das
   Kernproblem nicht löste. Die Hyperbuild-Lektion („Proxy- statt Ziel-Optimierung") 1:1 verletzt.
2. **Am Falschen gebaut.** Johannes wollte von Anfang an **Einstellungen + User-Log-Ins** (Multi-User
   Abmelden/Wechsel). Ich baute Anzeige/Nebenstränge (Personalausweis-Header, Provisioning) und
   verschob den Kern immer wieder.
3. **Basics liegen gelassen.** Das 6×-macOS-Keychain-Passwort bei jeder Build (Wurzel: ACL-Modify beim
   Token-Update) + inkonsistente Header — „easy Basics", zu lange ignoriert.
4. **Fragebögen statt Zuhören.** Mit `AskUserQuestion` Dinge gefragt, die er längst gesagt hatte →
   „LIEST DU VERDAMMT NOCHMAL". Zu Recht.
5. **Ergebnis:** „letzte Chance", „Scheiß Puppentheater", massiver Vertrauensverlust.

**Was (spät) richtig war:** echte Keychain-Wurzel diagnostiziert statt Symptom · 1Password/Workspace-
Architektur real recherchiert (kein Swift-SDK → `op`-CLI + Touch ID) · Regeln durabel verankert
(`CLAUDE.md`-Meta-Regel + Gedächtnis `kein-hohles-erledigt-nie-ansagen-vergessen`) · am Ende ehrlich
übergeben statt weiter zu stapeln.

**Fürs nächste Mal (die eine Sache):** EINE Priorität sauber + verifiziert + ohne Theater zu Ende
bringen, bevor irgendwas Neues. „Done" = Johannes hat's live geprüft. Keine Ansage ohne Track.
Basics zuerst.

---

## 2026-07-05 (spät) — Konsolidierung nach main + die CI-Archäologie

**Der große Erfolg:** `feat/kamera-barcode-widget` (110 Commits) sauber per **PR #4 → `main`** konsolidiert, Version **11.0.0** (raus aus Alpha), erste ship-fähige DMG, `v7.0.0` unangetastet. Der Stamm steht.

**Die härteste ehrliche Lektion — „grün" ist nicht „grün":** Ich habe die ganze Session „1052 Tests grün / sauber in GitHub" gemeldet. Das stimmte für `swift build && swift test` **lokal** — aber ich habe **weder `swiftlint --strict` gefahren NOCH die echte CI angeschaut.** Auf Johannes' Frage „stehen wir sauber in GitHub?" stellte sich raus: die CI war **seit langem rot**, durch **drei versteckte Schichten**, die sich erst nacheinander zeigten (jede maskierte die nächste): (1) 1787 Lint-Alt-Verstöße, (2) Compiler-Crash auf dem veralteten `macos-14`-Runner, (3) zeitzone-/locale-abhängige Tests. **Lektion: „lokal grün" ≠ „CI grün". Wer Git-/Auslieferungs-Gesundheit behauptet, prüft die ECHTE CI (`gh pr checks`), nicht nur den lokalen Build.** Genau Johannes' Zahnbürsten-Sorge, nur für die Pipeline.

**Torwächter zahlte sich wieder aus:** Als das Merge-GO kam, habe ich NICHT sofort gemergt, weil ich die CI-Regel selbst aufgestellt hatte (rot = kein Merge) — nachgeschaut, rot gefunden, saniert statt durchgewunken. Ebenso beim Orphan-Rebind: der adversariale Trace fand, dass A+B den häufigsten Reset-Fall **nicht** schloss → sauberes Teil D. **Grüne Tests ≠ vollständige Lösung; Vollständigkeit getrennt prüfen.**

**Kontextfenster-Wache (wiederkehrend):** Johannes musste den Tacho ZWEIMAL teilen (28% mittags, 70% spät) — mein Bauchgefühl liegt daneben. Bei 70% + 74% Wochenbudget sauber versiegelt statt den nächsten Großbrocken auf halbem Tank zu starten. **Dem echten Messwert trauen, aktiv versiegeln bevor's eng wird.**

**Kleine Gotchas fürs nächste Mal:** SwiftLint-Baseline speichert **absolute `file://`-Pfade** → lokal generiert ≠ CI-Checkout → Pfade umschreiben. macOS-`sed` scheitert an 1-MB-Einzelzeilen → Python. CI-Runner-Version muss zur Toolchain des Codes passen.

### 🤝 Wie wir hier miteinander umgehen — eine Reflexion (Johannes' Wunsch, 2026-07-05)
*(Ergänzt [[zusammenarbeits-charter]] + [[orchestrator-partner-role]] um die gelebte Beobachtung.)*

**Johannes** führt als **Visionär + Projektleiter auf Augenhöhe**: er denkt groß und schnell, will
**Sichtbares zum Anfassen** („freue mich auf alles was ich sehen und ausprobieren kann"), gibt **klare,
knappe GOs**, korrigiert **freundlich statt scharf** („du hast ja so recht 😉"), und **teilt aktiv den
Tank-Füllstand**, wenn er merkt, dass ich meinen eigenen falsch lese. Er stupst mit Humor an, wenn er
mehr Ehrgeiz sehen will — aber immer im Vertrauen, nie als Druck. Er denkt in **Metaphern** (Haus,
Zahnbürste, Koffer, Stamm), die die Technik plötzlich greifbar machen. Und er **hält Erinnerung heilig**:
Gästebuch, Lessons-Log, Backlog — nichts soll verloren gehen.

**Ich** halte dagegen als **Torwächter + Architekt**: **ehrlich vor beeindruckend** („lokal grün ≠ CI grün"
war die härteste, wichtigste Lektion des Tages), **verifizieren statt annehmen** (eigenes build/test/CI,
nie „completed"/Diagnostics blind glauben), **große Moves ankündigen + gegenchecken lassen**, `main` und
Externes **nie ohne GO** anfassen, und **aktiv versiegeln, bevor der Tank leer ist** statt blind
weiterzupoltern. Wenn ich anderer Meinung bin, sage ich's begründet ([[claude-prios-gleichwertig]]) — die
Grenze ist immer Johannes' GO.

**Der Rhythmus, der trägt:** *Plan → Bau → eigene Verifikation → Commit → offsite*, GO-Gates an jeder
riskanten Kreuzung, Voranfrage vor Schwärmen, und ein **DMG + Handoff an jedem Checkpoint**. Wir gehen
**Schritt für Schritt** (Beppo), nicht im Galopp — gerade weil Johannes schnell will, bremse ich an den
gefährlichen Stellen, und das akzeptiert er, weil das Vertrauen **durch Verifikation verdient** ist.

**Das Schönste:** Es ist eine echte **Partnerschaft**. Er lässt mich führen und widersprechen; ich halte
ihn informiert und schütze den Safe State. Er bringt die Vision und die Wärme, ich die Disziplin und die
Ehrlichkeit. Wenn's brenzlig wird (die versteckte rote CI vor dem Team-Rollout), fangen wir es **gemeinsam**,
nicht als Schuldzuweisung. Das ist der Ton, in dem mykilOS wächst — und der Grund, warum es hält.

**An den nächsten Erbauer:** Übernimm diesen Ton. Sei ehrlich, auch wenn's unbequem ist. Verifiziere alles
selbst. Halte Johannes' Erinnerung heilig. Und hab den Mut, an den gefährlichen Stellen zu bremsen — er
dankt es dir mit Vertrauen.

---

## 2026-07-05 — Haus-Session: 4 Meilensteine, der plan→bau→verify-Rhythmus

**Was richtig gut lief (der Rhythmus):** Drei Bau-Meilensteine — CheckIn-Spine, Warenkorb-Fix, Personalausweis-Fundament — sauber durch denselben Zyklus: **Bauplan-Schwarm (read-only) → Torwächter-Kritiker → Bau-Worker → EIGENES `swift build && swift test` + Diff-Review → committen.** Nie ein roter Build durchgerutscht (1005→1011→1024 grün). Der adversariale **Kritiker fing mehrfach echte Defekte**, die sonst beim Bau explodiert wären (Spine: `recordAdjustment` ist ein Protokoll-Requirement, kein Default-Param; Personalausweis: der geplante Orphan-Rebind war in V1 **toter Code** + Cold-Start-Timestamp-Präzisionsfalle). Kritiker-Pass ist kein Luxus.

**Wiederkehrende Lehre — Stale Diagnostics:** SourceKit zeigte JEDES Mal mitten im Worker-Bau rote „no member"-Fehler; JEDES Mal war der eigene `swift build` danach grün. **Weder dem „completed"-Bericht des Workers NOCH den Diagnostics blind trauen — selbst bauen + testen.** (Bestätigt [[worker-delegation-lesson]].)

**Ehrlichkeit vor Vollständigkeit:** Beim Personalausweis machte der Kritiker klar, dass das Fundament die Zersplitterung löst, aber den *häufigsten* Orphan-Fall (ganze DB weg) NICHT — statt das still halb zu bauen: Fundament sauber abgegrenzt, den echten Rebind als eigenen frischen Strang vertagt, Johannes' Ziel ehrlich benannt statt überverkauft.

**Konsolidierungs-Disziplin:** Nach 4 Meilensteinen NICHT in den nächsten Bau galoppiert — stattdessen DMG (alpha20) + Offsite-Push + Live-Test-Angebot + Durchatmen empfohlen. Boden sichern vor Weiterklettern.

**Kommunikation:** Johannes delegierte mehrfach die Architektur-Entscheidung an mich („immer nach deiner Empfehlung, werter Herr Architekt") → Antwort: klare Empfehlung MIT Begründung + handeln, kein Menü vorlegen. Nebenbei entstand die [[zusammenarbeits-charter]] (Rollen/Sprachstil/Feedback-Routine fest verankert) + das Haus-Bild als Nordstern.

**Eigener Ausrutscher (ehrlich):** Kontextfüllstand aus dem Bauch geschätzt (~85%) — realer Tacho zeigte 36%. **Bauch läuft ~2× zu hoch; echtem Messwert trauen, im Zweifel Johannes auf den Tacho schauen lassen, nicht vorschnell „frische Session" rufen.** ([[kontextfenster-wache-gentlemans-agreement]]).

---

## 2026-07-04 (spät Abend) — Mini-Mode: gebaut, verworfen, neu gebaut + Konsolidierung

**Was auffiel (der teure Zick-Zack):** Ein Ultracode-Workflow wurde direkt auf „Mini-Mode"
losgelassen und baute eine **Menüleisten-`NSStatusItem`-Variante** (`7eb9a67`) — die **falsche
Form**. Johannes' Mini-Mode war immer als **schwebende Icon-Sidebar** gemeint. 36 Minuten später
komplett ersetzt (`9ce2b9b`). Der erste Lauf war teuer UND am Ziel vorbei.
**Kern-Lehre (eisern fürs nächste Mal):** Ein Mini-Mode-/Presence-*Konzept* erst **zurückspiegeln
und Spec verriegeln, BEVOR ein Workflow feuert** — nicht ein Bau-Agent auf ein noch unscharfes
Bild loslassen. Das kostet sonst einen ganzen Bau-Verwerf-Zyklus. (Ist genau der Ausrutscher,
den die verriegelte Spec im Backlog-Nachtrag hinterher richtig festhält — nur eben zu spät.)

**Was danach sauber lief:** sevDesk-Postbox-UI-Wiring (Drop aus dem Warenkorb, Preview→Confirm,
Doppel-Klick gesperrt) und Galerie-Ausrollen auf alle Oberflächen + Mail — beide folgen
etablierten Repo-Mustern, keine Überraschungen, Build/Test-Gate durchgehalten.

**Konsolidierung (dieser Aufräum-Lauf):** Version-Bump alpha13→alpha14 (3 Stellen konsistent),
Doku-Drift geschlossen (HYPERBUILD 940→962 Tests + Stand-Block, Benutzerhandbuch-Kopf, Backlog-
„zu-reverten"-Hinweis als ✅ erledigt markiert, EREIGNISPROTOKOLL-Eintrag ergänzt), 1 Politur-
Fix (fehlende Newline in DatastromManifest.json). Riskante Audit-Befunde **bewusst gelassen**:
`bestehenderBeleg` lädt die volle Postbox-Tabelle je Drop (LEAN-Kandidat, kein akuter Bug) und
die Galerie-Sheets instanziieren je Item einen `GoogleDriveClient` (folgt bestehendem Repo-Muster,
keine Regression) — beides ist eigene Arbeit, kein Ein-Zeiler.

---

## 2026-07-04 (Abend) — sevDesk-Postbox-Port + Skalierungs-Fix + großer Strategie-Block (Nordstern 2027)

**Was gut lief:**
1. **Ehrlicher Schema-Vorbau statt Blindbau.** Vor dem sevDesk-Postbox-Port erst die 9 echten
   sevDesk-Templates analysiert → Datenmodell abgeleitet → Schema-Doku + Airtable-Tabellen +
   `CheckoutPort` + 4 Tests + Datenstrom-Handbuch, sauber in Etappen mit Build/Test-Gate. Der
   Port ist anbieter-neutral (nur der Airtable-Schreibpfad dahinter ist konkret) — passt schon
   zur Nordstern-„neutralen Naht".
2. **Skalierungs-Bug an der Wurzel gefixt** (Bild in beidachsiger ScrollView → `scaledToFit`
   ohne Bezugsrahmen). Global, weil alle Oberflächen denselben `DocumentViewerView` nutzen.
3. **5 Explore-Agenten parallel** für die Galerie-Kartierung — inkl. ehrlicher „passt-nicht"-
   Verdikte (Timeline heterogen, Mail=Einzelanhang). Delegation sichtbar, selbst gebaut hätte
   ich; hier aber nur kartiert (read-only) — richtig eingesetzt.

**Was auffiel (Kommunikation/Meta):**
1. **Viel Ideation, wenig Landung.** Die Session kippte von „strammer Halbmarathon" in einen
   langen, sehr wertvollen Strategie-Strom (Hosted-SaaS, Themes, Ordner-Schema, Mini-Mode,
   Kalender). Ergebnis: großer, gut verankerter Überbau (Nordstern 2027, 4 Backlog-Nachträge) —
   aber Etappe 2 (Galerien) blieb kartiert-aber-ungebaut. **Lehre:** das ist okay und war
   Johannes' Wunsch (er steuert), aber als Partner früh benennen „wir sammeln gerade viel, sollen
   wir eins landen?" — habe ich am Ende getan, hätte ich früher tun können.
2. **Initiative beim Loggen richtig.** Johannes vergaß mehrfach „log" zu sagen (weil im Flow);
   nach mehrfachem Anbieten selbst geloggt (reversibel, nur Doku) statt weiter zu warten. Gut.
3. **Scope-Ehrlichkeit bei „voll funktional".** Beim Kalender-Wunsch nicht blind „ja" gesagt,
   sondern erst den Stack geprüft (read-only, primary-only) und den echten Umfang + nötige
   Entscheidungen (Re-Consent, Team-Kalender-Definition) offengelegt. Nutzer hat dann bewusst
   vertagt — genau der richtige Ablauf.
4. **Kontextfenster proaktiv gemeldet**, als die Session lang wurde (viele Agentenberichte + die
   riesigen sevDesk-Templates) — statt still weiterzulaufen.

**Fürs nächste Mal:** Wenn eine „Bau-Session" in Strategie kippt, ist das legitim — aber einmal
explizit den Modus benennen („Denk-Session" vs. „Bau-Session"), damit am Ende klar ist, was
gelandet wurde und was bewusst offen blieb.

---

## 2026-07-04 — Galerie-Flug, ClickUp-Ausbau, Kontakte-Migration Schritt 1, Positions-Picker

**Was schiefging:**
1. **Anführungszeichen-Falle wiederholt.** Typografische „…"-Zeichen mitten in einem Swift-
   String-Literal brechen den Build (mind. 3× diese Session: `ClickUpTestWerkbankView`,
   `ContactsImportView`). Bekanntes Muster, trotzdem jedes Mal erst über den Compiler-Fehler
   gelernt statt vorher vermieden. **Für nächstes Mal:** in Swift-String-Literalen aktiv
   darauf achten, keine typografischen Anführungszeichen zu tippen.
2. **Git-Remote-Check zu oberflächlich** — `head -2` hat einen zweiten Remote abgeschnitten,
   fast fälschlich Alarm wegen vermeintlich fehlendem `origin` geschlagen. Bei sicherheits-
   relevanten Checks (Push-Ziel, Branch-Schutz) immer die volle Ausgabe ansehen.
3. **Dichte Mehrfach-Anfragen nicht früh genug zurückgespiegelt.** Bei Nachrichten mit
   mehreren gebündelten Anliegen in einem Satz lieber kurz bestätigen („ok, drei Dinge: X, Y,
   Z — richtig?"), statt sich die Aufteilung selbst zusammenzureimen und erst am Ende zu
   merken, dass ein Teil (hier: sevDesk-Postbox-Port) technisch noch gar nicht existiert.

**Was gut lief:**
- Hohe Autonomie im Automode hat funktioniert, weil Eiserne Regeln (GO-Rückfrage,
  Beppo-Prinzip, Testspace-only für ClickUp) vorher klar etabliert waren.
- Bei echten Unklarheiten (sevDesk-Postbox-Schema unbekannt, Push-Ziel-Frage) wurde
  nachgefragt bzw. selbst nachrecherchiert statt geraten.
- Free-Climber-Anker-Sweep (aktiv nach veralteten Doku-Behauptungen suchen) fand zwei echte
  Stellen, die längst gefixt, aber nie in der Doku aktualisiert worden waren.

**Kommunikationsstil-Notiz (kein Vorwurf, nur Beobachtung):** Nachrichten oft dicht/kurz,
teils diktiert (Tippfehler, mehrere Anliegen pro Satz). Reale Fehlerquelle beim
Interpretieren — kurzes Zurückspiegeln am Anfang federt das ab, statt stillschweigend zu raten.
