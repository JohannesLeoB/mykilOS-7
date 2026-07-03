# Rollender Plan — Studio-OS-Integration + Heute/Projekt-Politur

**Erstellt: 2026-07-02 · Autor: Claude (Opus 4.8) im Auftrag Johannes · Status: Vorschlag.**
Grundlage: Screenshot-Katalog (S01–S21), Code-Abgleich von 19 UI-Wünschen, ClickUp-„Studio-OS"-
Handoff, Artikel-Research-Paket S17, Schätzkonfigurator-Plan. Verbindliche Reihenfolge unten;
Phasen sind modular und einzeln abnehmbar.

---

## 0. Leitprinzip (warum diese Reihenfolge)

> **Daten vor Politur. Wireframe vor Pixeln.**

Die Projekt-Übersicht/-Detailseiten und „Heute" wirken tot, weil sie **Rohre statt Arbeit**
zeigen (Audit-/Sync-Log statt Aufgaben, Termine, Projektbewegung). Die belebenden Daten kommen
großteils aus **ClickUp** (operative Aufgabenwahrheit) — das ist noch nicht verdrahtet
(S08: `httpError 401`). Deshalb: **erst ClickUp-Datenschicht + Wireframe, dann Politur.**
Ausnahme: dev-/Demo-Altlasten und kaputte Fehlerzustände sind unabhängig und werden **sofort**
bereinigt (Phase 0).

Rollen (aus dem Studio-OS-Handoff, verbindlich):
mykilOS = Cockpit/Review · ClickUp = Aufgaben/Status/Meilensteine · Drive = Akte ·
Airtable = Stammdaten-Staging · Sevdesk = Finance · Clockodo = Zeiten. Nie Rollen vermischen.

---

## 1. Bestandsaufnahme (Code-belegt)

**Vollständig fehlend:** Mail-Senden · Mail-Aktionen (gelesen/Stern/Archiv/Löschen) ·
editierbares Projekt-Hero-Bild.
**Teilweise:** Heute-Cockpit (kein Kalender/ClickUp/Clockodo-Zusammenzug) · Artikel-Detail-Modal ·
Warenkorb-Zuweisungen · Kontakte-Widget (read-only Google) · Teamkalender (keine Farbe/Edit).
**Screenshot-Befunde:** S07 Layout-Bug (Dropdown überlagert Kontakte) · S08 ClickUp-401 roh ·
Dev-Flächen sichtbar (S01 Signal-Demo, S17 Test-Sandbox, S19 Signal-Log, evtl. S13 Modell-Zeile).

---

## 2. Phase 0 — Aufräumen + Fehlerzustände (JETZT, unabhängig)

Kein Wireframe nötig, kein Risiko für die Datenarchitektur.

**0.1 Dev-/Demo-Flächen ausblenden (hinter Debug-Flag, nicht löschen)**
- „Signal-Demo drücken um Signale zu simulieren" (HEUTE ZÄHLT) → nur bei `#if DEBUG` / Settings-Schalter.
- ✅ **Erledigt (2026-07-02):** „Test-Projekt gebären / TEST-Sandbox" (S17) → `ProvisioningTestView`
  ist jetzt `#if DEBUG`-gated in `SchaltzentrumView.swift`, aus Produktions-UI raus.
- „Signale dieser Sitzung"-Panel (S19) → Debug-Flag.
- „CLAUDE · AUTO · SONNET"-Zeile (S13) → nur aktuelles Modell zeigen, Rest weg (Johannes bestätigt).

**0.2 Fehlerzustände härten**
- ClickUp `httpError(401)` (S08) → sauberer `.permissionRequired`-Zustand („Berechtigung nötig ·
  in Einstellungen verbinden"), wie bei den Google-Clients. Nie rohen HTTP-Code zeigen.
- Alle Widget-Renderstates auf leere/nicht-verbundene Quellen prüfen (Kalender/Cash „Noch leer").

**0.3 S07 Layout-Bug** — Dropdown/Kontextmenü überlagert Kontakte-Inhalt, Text abgeschnitten. Fix +
Screenshot-Gegenprüfung (Build-grün ≠ Layout-korrekt).

**Tests:** Renderstate-Test ClickUp-401 → permissionRequired; Snapshot/Layout-Check S07 (manuell);
Cold-Start unberührt. **Abnahme:** kein Dev-Text in Produktions-Build, kein roher HTTP-Fehler, S07 sauber.

---

## 3. Phase 1 — ClickUp-Datenschicht (Studio OS)

Baut direkt auf Block A–D (ExternalMappingRegistry, ProvisioningLedger, ClickUpRouting,
ProjektProvisioningService — bereits im Branch). Ziel: **Aufgaben/Status/Meilensteine aus ClickUp
lesen** und als Projekt-Signale/Health ins Cockpit geben. Read-first, Karte→Bestätigung→Audit.

- ✅ **Erster Baustein erledigt (2026-07-02):** ClickUp-**Schreibpfad** in der Sandbox
  (`ProvisioningStep.clickUpStruktur`) — Liste + 8 Standard-Tasks idempotent im echten
  Testspace-Ordner `_TEST_PROVISIONING`. 793 Tests grün. Details: HANDOFF_MYKILOS8_BLOCK_D.md §7.
  **Noch offen:** Live-Verifikation (Johannes verbindet ClickUp-PAT + löst einmal im DEBUG-Build
  aus) + Verdrahtung in die ECHTE Projekt-Anlage (`provisioniereEchtesProjekt`, eigene Session).
- **1.1** ClickUp live verbinden (Token/Keychain, per-User) → Tasks je Projekt lesen (ListID-Mapping
  aus ExternalMappingRegistry). Kein Schreiben in v1.
- **1.2** Projekt-Health/Phase aus ClickUp ableiten (offene/fällige Tasks, Meilensteine) → Signal.
- **1.3** „Letzte Aktivität" umbauen: statt Audit-Log echte **Projektbewegung** (Task erledigt, neue
  Datei, Angebot rein). Audit-Log wandert in einen technischen Bereich (Einstellungen/Diagnose).
- **1.4** (optional, später) Webhook-Rückfluss (ClickUp-Task ändert sich → Signal) — braucht Backend;
  in local-first bis dahin Polling wie beim DriveOfferWatcher.

**Tests:** ClickUpClient URL/Parser (bestehend) + Mapping-Test (ListID→Projekt) + Signal-Ableitung
(Fake-Client) + Cold-Start Health. **Abnahme:** ein Projekt zeigt echte ClickUp-Aufgaben + Health;
401 sauber; keine ungefragten Writes.

---

## 4. Phase 2 — Wireframe: Heute + Projekt-Übersicht/Detail (mit Johannes)

**Bevor** poliert wird, die Informationsarchitektur festlegen (verhindert Doppelarbeit + Layout-Drift).

- **Heute:** Was gehört in „HEUTE ZÄHLT"? Vorschlag: Termine heute · fällige ClickUp-Aufgaben ·
  Timer/Clockodo-Stand · offene Alerts/Reviews. „Letzte Aktivität" = echte Projektbewegung.
- **Projekt-Übersicht:** welche Widgets in welcher Anordnung (Health, Aufgaben, Teamkalender,
  Kontakte, Cash, Dateien-Kurz, Angebote-Kurz). Teamkalender-Widget neu (Farbe + Klick→Edit).
- **Projekt-Detail-Tabs:** Übersicht/Assistent/Zeit/Dateien/Angebote/Timeline/Material — Inhalt je Tab schärfen.

**Ergebnis:** ein abgestimmtes Wireframe/Skizze (kein Code). Abnahme: Johannes bestätigt Layout je Seite.

---

## 5. Phase 3 — Funktions- + UI-Politur nach Wireframe

Erst jetzt Pixel/Interaktion, einmal und richtig.

- **3.1 Heute-Cockpit** mit echtem Inhalt (Phase-1-Daten).
- **3.2 Teamkalender-Widget** (farbcodiert nach Kalender, Klick→Detail/Edit — Kalender-Schreibpfad).
- **3.3 Kontakte-Widget** projekt-zugewiesene Airtable-Kontakte (nach Google→Airtable-Import, s. u.),
  klick/zuweis/editier/Mail (Nav-Brücke `mailComposeRequest` existiert schon).
- **3.4 Projekt-Hero-Bild** editierbar (Upload/Import pro Nutzer, lokal + optional Drive).
- **3.5 Artikel-Detail-Modal** (Klick auf Produkt → volle Info; Anker für Anreicherungs-Overlay).

**Tests:** je Widget alle Renderstates; Cold-Start Hero-Bild + Kontakt-Zuweisung; Kalender-Edit gated.

---

## 6. Parallelstränge (eigene Sessions, nicht in der Hauptsequenz)

- **Mail-Vollausbau** (Senden + Aktionen): braucht `gmail.send`/`modify`-Scope → **Google Re-Consent (M2)**;
  Senden mit hartem Bestätigungs-Gate (NO-GO im Code ist aufgehoben, Johannes). Eigener Branch.
- **Artikel-Anreicherung (S17-Paket):** review-gated Overlay in UNSERER Schicht (GRDB, Join per
  Artikelnummer/EAN), Daniels Base bleibt read-only. Bilder = Kandidaten mit Rechteprüfung;
  Händlerpreise NIE als Anker. Vorlauf: Google→Airtable-Kontakt-Import (Dubletten/Vollständigkeit).
- **Schätzkonfigurator:** nativ auf KalkulationsEngine statt separater JS-App; Taxonomie aus dem Plan übernehmen.
- **Slack-Brain:** Studio-Slack-Historie → Beratungs-Insights (eigener Strang).
- **Warenkorb=Checkout-Wirbelsäule** (universeller Picker + Router): siehe [WARENKORB_CHECKOUT.md](WARENKORB_CHECKOUT.md).

---

## 7. Optimierungen (querschnittlich)

- Widget-Renderstate-Konsistenz: kein roher Fehlercode je wieder (ein zentrales `.permissionRequired`-Mapping).
- Layout-Drift-Guard: jede Übersicht-/Detail-Änderung gegen Screenshot prüfen (Build-grün ≠ Layout-ok).
- Poll-Sparsamkeit: ClickUp/Drive-Polling gebündelt, nicht pro Widget.
- Assistent bereits gehärtet (Timeout/Deadline/Cancel/Distillation) — beibehalten.

---

## 8. Offene Entscheidungen (Johannes)

1. Reihenfolge bestätigen: Phase 0 sofort, Politur erst nach ClickUp + Wireframe?
2. „kann das weg?"-Screenshots — Freigabe je Dev-Fläche (Q&A-Runde).
3. Modell-Statuszeile (S13) sichtbar lassen oder weg?
4. Mail-Vollausbau + M2-Re-Consent jetzt anstoßen oder später?
