# Downlink-Doktrin — Wie der Satellit zum Schiff funkt

**Stehender Auftrag (Johannes, Nacht 04.07.):** Immer mitprüfen, (a) was das
Mothership BRAUCHT und (b) wie/was/wann/warum der Satellit zurückfunkt.

## Das Grundgesetz des Funks

1. **Nie direkt ins Schiff.** Tank A bleibt unberührbar — kein Code, kein Repo-Write.
   Der Funk läuft ausschließlich über die **geteilte Umlaufbahn** (Airtable/Drive),
   die das Schiff ohnehin abhört.
2. **Daten, nie Befehle.** Der Satellit liefert Rohstoff (Zeiten, Fotos, Maße,
   Antworten) — er erzeugt NIE Aufgaben für Menschen (Eiserne Regel: Aufgaben nur
   Mensch→Mensch) und stößt NIE Schiffs-Prozesse direkt an.
3. **Append-only + gated.** Jeder Funk-Spruch ist ein neuer Datensatz nach
   Karte→Bestätigung. Nichts wird überschrieben, nichts gelöscht.
4. **Der Empfänger existiert schon:** DriveOfferWatcher-Muster (Schiff pollt
   Ordner), Adapter-Base (Schiff liest Postbox), Registry-Sync (Schiff liest
   Airtable). Neue Downlinks folgen diesen drei Empfangsmustern — kein neues
   Funkgerät erfinden.

## Die Funk-Grammatik (WAS → WOHIN → WANN → WARUM)

| WAS der Satellit fängt | WOHIN er funkt | WANN | WARUM das Schiff es braucht |
|---|---|---|---|
| **Zeiten** („4h CAD") | Adapter-Base Zeitbuchungen ✅ existiert | sofort nach Bestätigung | Wochenschluss, Stundenprotokoll, später Kalkulations-Realdaten |
| **Feld-Fotos** (Rohbau/Abnahme/Mängel) | Drive-Kanon 02/06/09 (★3, nach Freigabe) | sofort, gated Dialog | Projektakte; DriveOfferWatcher-Muster kann Signale draus machen |
| **Aufmaße** (AR + Laser) | strukturierte Notiz im Projektordner / künftige Aufmaß-Postbox | am Termin-Ende (Paket, nicht tröpfelnd) | CAD-Zubringer, schaetze-Futter, Werkplanung |
| **Fragebogen-Antworten** (Ersttermin) | die bestehende Intake-Pipeline des Schiffs (V10-Straße!) | sofort nach Kundengespräch | daraus macht das Schiff Kunde+Projekt+Erst-Korb — die Kette EXISTIERT |
| **Adressen/Kontakte** (an der Tür bestätigt) | Airtable Kunden — gated ContactActionCard-Muster (existiert im Schiff!) | sofort, mit Karte | schließt die Adress-Lücke → Geofence, Hinfahren, Gewerke-Briefe |
| **Bestandslisten/Geräteakten** | Projektnotiz (Drive) + perspektivisch Airtable-Tabelle | Rundgang-Ende | DeviceCatalog-Match → Ersatzklassen → Kalkulation |
| **Ideen** | Ideen-Topf (Tank B), Ziel-Heimat offen | sofort | Studio-Backlog speist sich aus dem Feld |
| **Foerderungs-Belege** (Vorher/Nachher) | gebuendeltes Beleg-Paket (foerderrelevant markiert) | bei Bedarf | KfW/BAFA-Foerderantraege brauchen nachvollziehbare Dokumentation |

## Was das Schiff JETZT braucht (Stand `dababdb` — Teil des Reality-Checks ab sofort)

- **Block I:** Schneider-Live-Lauf durch Johannes (Gate vor 10.0.0) — kein
  Satelliten-Job, aber der Satellit erinnert nicht, er *weiß* es nur.
- **M3/M4:** ClickUp-Listen-IDs + sevdeskRef/Budget in Airtable — **feld-fangbar!**
  Wenn Johannes unterwegs entscheidet, kann der Satellit es gated eintragen.
- **Adressen** in Kunden-Records — der Satellit kann sie AN DER TÜR bestätigen
  und einfunken (bester Ort der Welt dafür: man steht ja davor).
- **Stundensätze** (Clockodo-Leistungen) — Johannes-manuell, merken.

## Ritual-Erweiterung (ab sofort Teil des Reality-Checks)

Beim `fetch` auf Tank A zusätzlich prüfen: **Was braucht das Schiff gerade?**
(offene Gates, M-Aktionen, Lücken) → in die Star Map, ggf. als Feld-Fang-Chance
markieren. Der Satellit fliegt nie nur für sich.
