# HANDOFF — Fragebogen: echte Provisionierung statt TEST-Sandbox-Testkarte

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS6/
Branch: feat/mykilos8-block-d-provisioning
Build:  ✅ swift build grün
Tests:  ✅ 719 Tests grün (19 neu über beide Teile dieses Handoffs)
Live:   ✅ App-Start clean (kein error/fault/crash im Log), sauber beendet
DMG:    ✅ mykilOS-7.11.0.dmg
Datum:  2026-07-01
```

## Update 2026-07-01 (Teil 2): drei Anlege-Stufen statt einer festen Pipeline

Johannes' Feedback nach Teil 1: „Es muss ein Minimum an Eingabedaten vorausgesetzt sein …
entweder Projekt mit Ordner und allen Triggern anlegen, oder nur als Kontakt speichern, als Lead
anlegen — die Triggerstufe wird im letzten Dialog zur Auswahl angegeben." Über AskUserQuestion
abgestimmt (Kontakt = Google-Kontakt UND Artikel-DB-Kunde; Lead = Rumpf-Ordner unter
`PROJEKTE/_LEADS/`, sofort in der Galerie sichtbar mit Phase „Lead"; Stufe 3 blockiert den Button
hart ohne STR-Nr-fähige Adresse).

**Neu:** `FragebogenTriggerStufe` (Kontakt/Lead/ProjektMitOrdner), gewählt in der
Bestätigungsansicht (nicht vorbelegt). `AppState.erzeugeAusFragebogen(...)` dispatcht auf
`erzeugeNurKontakt` oder `erzeugeKundeUndProjekt(...ordnerModus:)`. Gemeinsame Kunde-Anlage-Logik
in `legeKundeAnFallsNichtVorhanden` extrahiert. `IntakeAdresse` (neuer Helfer) ist die eine
Wahrheit für die atomare Adress-Auflösung — von der UI-Readiness-Prüfung UND der echten
STR-Nr-Bildung gleichermaßen genutzt.

**Adversarial Review (3 Dimensionen) fand 3 Findings, 2 bestätigt + gefixt:**
- **MEDIUM:** Lead-Stufe verlangte keine Adresse, aber die Projektnummer wurde VOR der
  STR-Nr-Prüfung reserviert — ein adresse-loser Lead hätte eine Nummer permanent verbrannt, ohne
  je einen Ordner/Routing-Eintrag zu bekommen (auch nicht sichtbar in der Schaltzentrale, nur
  Konsole). Gefixt: STR-Nr-Prüfung läuft jetzt VOR der Nummern-Reservierung; ein Skip wird jetzt
  auch über `dataFlow.log` sichtbar gemacht.
- **LOW:** Die Schritt-Tableiste blieb während der Bestätigungsansicht klickbar, ohne dass sich
  der Inhalt änderte (widersprüchlicher UI-Zustand: Tab-Highlight wechselt, Karte bleibt gleich).
  Gefixt: Tableiste während `zeigeBestaetigung` deaktiviert + abgedunkelt.
- Verworfen (False Positive): das Handbuch sei nicht aktualisiert — zum Zeitpunkt der Prüfung war
  noch nichts committed, daher kein tatsächlicher Doku/Code-Widerspruch (wurde trotzdem vor dem
  Commit nachgezogen, siehe unten).

Eigener neuer Test fand außerdem einen echten Bug in `IntakeAdresse.aufloesen` selbst: ein Projekt
mit NUR einem Ort (keine Straße) hätte fälschlich die komplette Kunden-Adresse benutzt und den
eigenen Ort verworfen. Gefixt: „Projekt-Adresse vorhanden" heißt jetzt „Straße ODER Ort gesetzt",
nicht nur Straße.

`docs/BENUTZERHANDBUCH.md` (Weichen-Tabelle + Prosa-Sektion) und die zwei live Datenstrom-Handbuch-
Zeilen in Airtable wurden für das 3-Stufen-Modell aktualisiert.

## 0. Auftrag

Nach Block D (TEST-Sandbox-Provisionierung) gab Johannes explizites Feedback beim
Live-Testen: „Die ganze Projekt-Anlegen Logik muss hier rein in den Dialog und nicht
in die Integrationen" — die Drive-Ordner-/Airtable-Provisionierung sollte im
Fragebogen-Dialog selbst passieren, nicht in einer separaten Testkarte in
Integrationen. Vor dem Bauen wurden zwei Design-Entscheidungen mit Johannes über
AskUserQuestion abgestimmt:

| Frage | Johannes' Entscheidung |
|---|---|
| Soll das Fragebogen-Submit einen ECHTEN Drive-Ordner anlegen? | Ja, echte Ordner ab jetzt |
| TEST-Sandbox-Testkarte in Integrationen? | Entfernen |
| Neue Mastermind-Routing-Tabelle beschreiben? | Ja, freigeben |
| „Quelle"-Wert für Fragebogen-Projekte? | Neue Option „Fragebogen" |

## 1. Was gebaut wurde

Der Fragebogen legt bei Bestätigung jetzt in einem Rutsch an:
1. Kunde + Projekt in der Artikel-DB (wie vorher, unverändert in der Grundlogik)
2. Erst-Warenkorb (falls Positionen ausgewählt)
3. **NEU:** echte Projektnummer (`NumberAuthority.nextAndReserve`) + echter
   Drive-Ordnerbaum im echten `PROJEKTE`-Root (nicht mehr `_TEST_PROVISIONING`)
4. **NEU:** Mastermind-Routing-Eintrag (Airtable `Projekte`-Tabelle) — macht das
   Projekt sofort in der App-Galerie sichtbar
5. **NEU:** Fragebogen-PDF-Upload in den neuen `01 INFOS / 07 Fragebogen`-Ordner

Schritte 3–5 sind nicht-fatal (`AppState.provisioniereEchtesProjekt`, `-> String?`,
nie throwing) — ein Fehler dort darf die bereits committeten Kunde/Projekt-Records
nie rückgängig machen.

| Baustein | Datei |
|---|---|
| Geteilter Ordnerbaum-Builder (aus Block D extrahiert) | `MykilosServices/DriveOrdnerbaumBuilder.swift` |
| STR-Nr-Adress-Split (kombiniertes „Straße + Nr."-Feld) | `MykilosKit/Domain/STRNummer.swift` (`splitStrasseHausnummer`) |
| Echte Provisionierung + Dublettenschutz | `MykilosApp/Data/AppState.swift` (`provisioniereEchtesProjekt`, `findeBestehendenKunden`, `findeBestehendesProjekt`) |
| `typecast`-fähiger Airtable-Write (für die neue Select-Option) | `MykilosServices/Airtable/AirtableClient.swift` |
| Whitelist-Erweiterung | `AirtableClient.writableMap["appuVMh3KDfKw4OoQ"]` +`"Projekte"` |
| TEST-Sandbox-Testkarte entfernt | `MykilosApp/Provisioning/ProvisioningTestView.swift` gelöscht, Aufruf aus `SchaltzentrumView.swift` entfernt |
| Neue Airtable-Infrastruktur (live angelegt) | Tabelle `TEST-Projekte` (`tblj1OXFt0nOqgq0P`, Block-D-Live-Test), neue Select-Option „Fragebogen" im `Quelle`-Feld der `Projekte`-Tabelle |

`ProjektProvisioningService`/`ProvisioningLedger` (Block D, TEST-Sandbox) bleiben
bestehen und getestet — nur ihr UI-Einstieg wurde entfernt, die Baum-Logik ist jetzt
geteilt zwischen ihnen und der echten Fragebogen-Provisionierung.

## 2. Adversarial Review — 12 Findings, 8 bestätigt + gefixt, 4 als False Positive verworfen

Multi-Agent-Review (4 Dimensionen: Safety/NO-GO, Korrektheit, Concurrency/Regression,
Datenfluss-Doku) + adversariale Verifikation jedes Fundes.

| # | Schwere | Befund | Fix |
|---|---|---|---|
| 1+6 | HIGH | Kein Dublettenschutz: ein Retry nach transientem Netzwerkfehler (Button reaktiviert sich bei `.fehler`) legt Kunde+Projekt+Drive-Ordner+Routing-Eintrag ein zweites Mal an | Fetch-vor-Create-Dublettenschutz vor Kunde-Anlage (Nachname+E-Mail/Telefon) und vor Projekt-Anlage (Projektname+Kunden-Link) — exakt das Muster aus `ProjektProvisioningService.findeBestehendenRecord` |
| 2 | MEDIUM | Erfolgs-Zusammenfassung zeigt immer „erfolgreich angelegt", auch wenn die echte Provisionierung (Drive+Routing) im Hintergrund lautlos fehlschlug | Zusammenfassung verzweigt jetzt: ohne `driveProjektOrdnerID` erscheint ein expliziter Hinweistext statt eines blanken Erfolgs |
| 3 | MEDIUM | `STRNummer.splitStrasseHausnummer`-Regex erkannte „10 b" (Leerzeichen vor Suffix) und „4/2" (Schrägstrich-Zusatz) nicht — degradierte still zu keiner Hausnummer statt zu warnen | Regex erweitert (`\s+\d+\s?[a-zA-Z]?([/-]\d+\s?[a-zA-Z]?)?$`), 2 neue Tests |
| 4 | LOW | Kundennummer/Suche-Felder nutzten nur das erste Wort des Nachnamens („von Boch" → „von") — zu generisch | Voller Nachname (Leerzeichen entfernt) statt erstem Wort |
| 5 | LOW | Drive-Erfolgs-Log-Eintrag enthielt nicht die tatsächliche Ordner-ID, erschwerte Diagnose bei späterem Airtable-Fehler | Ordner-ID jetzt Teil der Log-Summary |
| 7 | MEDIUM | Adress-Fallback fiel PRO FELD zurück (Straße vs. Hausnummer unabhängig) statt pro Adresse — konnte Projekt-Straße mit Kunden-Hausnummer mischen | Fallback jetzt atomar: ganze Projekt-Adresse ODER ganze Kunden-Adresse, nie gemischt |
| 8 | HIGH | Die tabellarische „Alle Weichen"-Übersicht in `docs/BENUTZERHANDBUCH.md` (separat von der Prosa-Sektion) zeigte weiterhin „Stand 2026-06-30 · 37 Weichen" und listete die 2 neuen Integrations-IDs nicht | Tabelle + Zähler + Datum aktualisiert |

**Verworfen (False Positives, korrekt durch Adversarial-Verifikation erkannt):**
- „Bypass des ProvisioningMode-Gates" — falsch: das Gate ist bewusst auf Block D's
  TEST-Sandbox-Mechanismus beschränkt, nicht ein universelles Schreib-Gate; die
  Fragebogen-Provisionierung ist ein separater, explizit freigegebener Pfad.
- „Mastermind-Write ohne Dublettenschutz retry-bar" — falsch: `provisioniereEchtesProjekt`
  wirft nie, der Button-Retry-Mechanismus kann diesen spezifischen Schritt gar nicht
  erneut auslösen (siehe Fix 1+6 für den tatsächlich reproduzierbaren Fall).
- „Block-D-Doku zeigt noch auf die gelöschte Testkarte" — falsch: bereits korrekt
  aktualisiert, der Verifizierer hatte den Diff falsch gelesen.
- „Nur die Manifest-Ebene wurde dokumentiert, Handbuch fehlt" — falsch: das Handbuch
  WAR bereits aktualisiert (Prosa-Sektion), nur die separate Weichen-Tabelle fehlte
  (das ist Fund #8).

## 3. Datenstrom-Handbuch + Whitelist (live in Airtable)

- Neue Tabelle `TEST-Projekte` (`tblj1OXFt0nOqgq0P`, Mastermind-Base) für Block D's
  Live-Test — 3 Felder (Projektname/Quelle/Projektnummer, alle `singleLineText`).
- Neue Select-Option „Fragebogen" im `Quelle`-Feld der `Projekte`-Tabelle (via
  `typecast: true` beim ersten echten Write angelegt).
- 2 neue Zeilen im Datenstrom-Handbuch (`tblaUVftka0GvXzeU`):
  `DRIVE_FRAGEBOGEN_PROJEKT_ORDNER`, `AIRTABLE_FRAGEBOGEN_PROJEKT_ROUTING`.
- `AirtableClient.writableMap["appuVMh3KDfKw4OoQ"]` um `"Projekte"` erweitert.

## 4. Bekannte, akzeptierte Grenzen (nicht Teil dieses Fixes)

- Es wird **kein** Kunden-Record in der Mastermind-`Kunden`-Tabelle angelegt — das
  Kdnr-/Kunde-Feld in der Galerie bleibt für Fragebogen-Projekte leer, bis das
  gesondert entschieden wird (Mastermind-`Kunden` bleibt bewusst nicht schreibbar).
- `AppState.gebaereTestProjekt` + `provisioningService`/`provisioningLedger` haben
  jetzt keinen UI-Aufrufer mehr (Testkarte entfernt) — bleiben aber getestet
  (`ProvisioningServiceTests`) und nutzbar für zukünftige Dev-Zwecke. **Flagge für
  Johannes:** behalten oder entfernen?

## 5. Tests

- `Tests/MykilosKitTests/NomenklaturTests.swift`: 7 neue Tests (`splitStrasseHausnummer*`)
- `Tests/MykilosServicesTests/DriveOrdnerbaumBuilderTests.swift`: 4 neue Tests (Baum-Aufbau,
  Idempotenz mit/ohne bekannter Root-ID, Fehlerpfad)
- `Tests/MykilosServicesTests/AirtableClientTests.swift`: Whitelist-Test aktualisiert
  (`Projekte` jetzt erlaubt) + neuer expliziter Test dafür
- `erzeugeKundeUndProjekt`/`provisioniereEchtesProjekt` selbst bleiben nicht
  unit-testbar (instanziieren `AirtableClient()`/`GoogleDriveClient()` direkt, kein
  Injection-Punkt) — wie schon vor diesem Change, keine Regression.

## 6. Nächster Schritt

Live-Test mit Johannes: echten Fragebogen ausfüllen und bestätigen, prüfen ob
(a) Drive-Ordner im echten `PROJEKTE`-Root entsteht, (b) das Projekt in der Galerie
auftaucht, (c) ein zweiter Versuch mit denselben Daten wirklich nichts dupliziert.
