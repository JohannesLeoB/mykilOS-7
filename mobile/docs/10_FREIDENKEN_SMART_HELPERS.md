# Freidenken — App-Funktionen & Smart Helpers

**Mandat Johannes (Nacht 04.07.): „feel free to think free. Was unmöglich ist, ist okay."**
Organisiert entlang des echten Tages. Ehrliche Tags:
**[JETZT]** geht heute (v0) · **[v0.5]** Kurzbefehle/Bordmittel · **[v1]** native App ·
**[SPÄTER]** braucht Infrastruktur (z. B. Push/Server) · **[HARDWARE]** braucht Zusatzgerät ·
**[❌]** vermutlich unmöglich/verboten — trotzdem notiert, weil ehrlich.

---

## 🌅 Morgens

- **Morgen-Brief über AirPods/CarPlay** — gesprochen: Termine, Drive-Puls, offene
  Anker („Fahrstuhl-Maß fehlt bei vonBoch"). [JETZT als Chat / v1 als Audio]
- **Lock-Screen-Puls-Widget** — 3 Zahlen, bevor du entsperrst: Termine · heiße
  Projekte · wartende Angebote. [v1]
- **Wetter-Weiche für Montagen** — Außenaufmaß/Lieferung morgen? WeatherKit warnt
  heute Abend: „Regen ab 11 Uhr — Zeitfenster morgens." [v1]

## 🚗 Unterwegs

- **CarPlay-Modus:** nur Ohren und Stimme — Brief hören, Zeit fangen, „bring mich
  zum nächsten Termin" (Maps-Handoff). [v1]
- **Ankunfts-Trigger (Geofence):** Auto hält beim Kunden → Live Activity öffnet
  leise: „Schmidt · letzte Notiz · Fragebogen offen?" [v1]
- **Diktat-Nachbereitung:** nach dem Termin ins Lenkrad sprechen — ich strukturiere
  zu Protokoll + Follow-ups. [JETZT]

## 🏗️ Auf der Baustelle / beim Kunden

- **Projekt-Kamera** (★3-Design von Johannes): im Kontext geboren, „ja ab in die
  Drive damit", Kanon-Schublade 02/06/09, EXIF-Beweiskette. [v1, nach Freigabe]
- **Rundgang-Bestandsaufnahme:** Foto-Serie → Geräteakten (Typenschild-Pfad
  BEWIESEN: BEJUBLAD-Live-Beweis ③) + Material-Kandidaten → Bestandsliste →
  DeviceCatalog-Match → Kostenschätzung. [JETZT Fotoserie / v1 AR-Labels live]
- **Aufmaß-Formular mit Laser-Tackern:** BLE-Wert springt ins aktive Feld, Hände
  bleiben am Werkzeug. [v1 + vorhandene Leica/Bosch]
- **Triple-Maß-Doktrin eingebaut:** App zeigt IMMER, aus welcher Toleranz-Stufe
  ein Maß stammt (Foto/AR/Laser) — Werkmaß nur aus Laser. [v1]
- **NFC-Projektanker:** NFC-Sticker im Musterordner/an der Baustellen-Mappe —
  iPhone dranhalten → Projekt öffnet. Kein Suchen, kein Tippen. [v1, Sticker ~0,30 €]
- **Einbau-Checks per ARKit:** Ist der montierte Korpus im Lot/waagerecht? Kamera
  drauf, Abweichung in Grad/mm angezeigt. Werkzeug bleibt Pflicht, aber die
  Doku ist gratis. [v1, Genauigkeit prüfen]
- **Abnahme-Zeremonie:** Mängel diktieren → nummeriertes Protokoll + Fotos +
  **Pencil-Unterschrift des Kunden** auf dem iPad → PDF (lokal, Belegführung-
  extern-Regel beachtet). [v1]
- **dB-Messung bei Geräte-Abnahme** („der Geschirrspüler ist zu laut") — Mikrofon
  misst, Protokoll notiert. Grobwert, kein Eichgerät — ehrlich labeln. [v1]

## 🪚 In der Werkstatt

- **Werkstatt-Modus:** Hände voll Leim → alles per Stimme. Timer je Projekt,
  „Zuschnitt Schmidt fertig", Materialrest fotografieren → Lagerliste. [v1]
- **Projekt-Timer als Live Activity:** läuft sichtbar auf dem Lock Screen /
  Dynamic Island; Stopp → Vorbuchung in die Postbox. [v1]
- **Reststück-Gedächtnis:** „Eiche 38mm, 1,2×0,4, Regal C" — Foto + Maß → beim
  nächsten passenden Zuschnitt schlägt die App den Rest vor. Nachhaltigkeit,
  die Geld spart. [v1]

## 🤝 Team (5–8, per-User isoliert)

- **Übergabe-Stafette:** „Daniel übernimmt Montage Loidl" → er bekommt Projekt-
  Brief mit genau seinen Infos (Gewerke-Brief-Prinzip). [v1]
- **Wer-ist-wo NUR opt-in:** Standort-Teilen je Tag aktiv einschaltbar, nie
  stillschweigend. Privacy-RAIL. [v1]
- **Postbox-Wochenschluss:** Freitag zeigt jedem NUR die eigenen Vorbuchungen
  zum Prüfen → dann erst Handbuchung in Clockodo. [JETZT als Chat-Ritual / v1 UI]

## ✨ Delight (jeden Tag neu überraschen)

- **Fundstück des Tages:** aus dem `_PROJEKTE_ARCHIV` (200+ Projekte, 8 Jahre!)
  morgens EIN altes Foto: „Weißt du noch — Treppenmöbel 2019?" Studio-Gedächtnis
  als tägliche Freude. [v1; Archiv-Parser nötig — bewusst zurückgestellte Zone,
  nur LESEN, nie umbenennen]
- **Küchen-Geburtstage:** 1 Jahr nach Abnahme → „Familie Doehle kocht seit heute
  einem Jahr" → Anlass für Service-Anruf/Karte. Kundenpflege mit Seele — und
  ein ehrlicher Service-Umsatz-Kanal. [v1]
- **Richtfest-Momente:** Meilenstein erreicht (Korb→Angebot→Auftrag) → kleine
  Konfetti-Sekunde. mykilOS-Orange, versteht sich. [v1]

## 📡 Braucht Infrastruktur — ehrlich [SPÄTER]

- **Echte Push-Nachrichten** („neues Angebot im Drive-Ordner erkannt") — braucht
  APNs = Developer-Account + einen kleinen Server ODER die local-first-Variante:
  Hintergrund-Fetch beim App-Öffnen. Local-first passt besser zur DNA.
- **Live-Sync zwischen Geräten** — bewusst NICHT bauen; Airtable/Drive sind der
  Sync. Kein eigenes Backend, Doktrin bleibt.

## ❌ Die Unmöglich-Ecke (notiert, weil du sagtest: okay)

- **Anrufe automatisch mitschneiden/transkribieren** — in Deutschland ohne
  ausdrückliche Zustimmung **strafbar (§ 201 StGB)**. Machbar wäre: NACH dem
  Gespräch diktierte Zusammenfassung. Die Grenze ist Gesetz, nicht Technik.
- **Wand-Durchleuchtung** (Leitungen HINTER der Wand sehen) — iPhone-Sensorik
  kann das nicht; braucht Spezialhardware (Ortungsgerät). [HARDWARE, nicht iPhone]
- **Wärmebild** (Kältebrücken, Fußbodenheizung finden) — nur mit Aufsteck-Kamera
  (FLIR/InfiRay, ~300 €). Als HARDWARE-Anbau denkbar, nativ unmöglich.
- **Telefon-Anruflisten lesen** — iOS gibt Drittanbieter-Apps bewusst KEIN
  API dafür (kein Recents-Zugriff, seit jeher). Kein Claude-Verbot — Apples
  eigene Privatsphäre-Mauer, die unsere Doktrin bestätigt statt behindert.
  Alternative: Kontakt-Ereignis per Diktat fangen („Schneider angerufen,
  erledigt") — der Mensch ist hier der ehrlichere Sensor.
- **mm-genaues Aufmaß aus reinem Foto** — bleibt physikalisch Unfug. Dafür gibt
  es die Drei-Toleranzen-Doktrin.

---

## Die Meta-Regel über allem

Jeder Helper gehorcht dem Dreitakt (Fang→Versteh→Verräum), dem Nie-Raten
(Kandidaten-Karte), den RAILs (gated Writes, per-User, Postbox) und der
Kosten-RAIL (lean). **Ein Helper, der beeindruckt, aber nicht verräumt, fliegt raus.**
