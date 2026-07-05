# Prozess-Lessons — laufender Abschlussbericht

**Zweck (Johannes, 2026-07-04):** „Am Ende machen wir ja alle Erfahrungen, vielleicht lernen
wir so alle mehr, wenn wir immer einen kleinen Abschlussbericht fortführen." Dieses Dokument
ist der EINE, wachsende Ort dafür — nicht in einzelnen Handoffs verstreut. Jede Session (auch
unter anderem Claude-Account) hängt am Ende einen kurzen Eintrag an: was schiefging, was gut
lief, was fürs nächste Mal mitgenommen wird. Kein Ersatz für den Session-Handoff (der bleibt
technisch/inhaltlich), sondern die Meta-Ebene: Zusammenarbeit, Fehler-Muster, Kommunikation.

**Regel:** append-only. Ältere Einträge nie löschen oder umschreiben — nur ergänzen. Neueste
Einträge oben.

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
