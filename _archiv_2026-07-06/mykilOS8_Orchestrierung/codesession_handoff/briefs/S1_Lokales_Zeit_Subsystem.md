# Brief · S1 — Lokales Zeit-Subsystem

**Modell:** Sonnet 4.6, high thinking · **Gate:** keins (rein lokal) · **Abhängigkeit:** S0 bestätigt · **Schreibt extern:** NEIN.

## Auftrag
Baue die gesamte lokale Zeiterfassung — UI + Zustand + Persistenz, ohne jeden externen Write. Liefert sofort Nutzen und ist die Grundlage für S2/S3.

## Umfang
- **Projekt-Timer** auf der Projekt-Detailseite: Start/Stopp, großes lesbares Display.
- **Single-Instance-Invariante:** genau ein `aktiverTimer` in der lokalen DB, nie zwei gleichzeitig. Wechsel bei laufendem Timer → **nachfragen** (Default; siehe offene Frage).
- **Pause vs. Stopp:** Pause hält (Slot belegt, weiterführbar), Stopp beendet das Segment (Slot frei).
- **3–5 Kostenstellen-Buttons**, projektabhängig — Quelle ist das Airtable-Projektfeld (in S1 ggf. read-only gemockt/aus lokalem Cache, echte Anbindung in S2). Kostenstelle-Wechsel bei laufendem Timer beendet sauber das Segment und startet ein neues.
- **Sidebar-Pille:** minimal, Play/Pause, Projekt + Kostenstelle + tickende Zeit. Läuft nichts → nichts anzeigen.
- **Puls-Erinnerung:** Intervall in User-Settings (Default 60 Min, lokal). Ganze Sidebar pulsiert; Klick → minimaler Check-in („läuft weiter" startet die Erinnerungs-Uhr neu / „stoppen" → Buchung).
- **Doppelte Buchungs-Bestätigung:** Stopp → Übersichts-Karte → expliziter zweiter „Ja, buchen" → erst dann committet in den lokalen Store.
- **Lokal editierbares Zielkontingent** je Projekt mit Herkunfts-Flag (`auto`/`manuell`); Feldgerüst hier, Befüllung in S2.

## Tests (Pflicht)
Single-Instance-Invariante; Pause-hält/Stopp-beendet; Kostenstellen-Wechsel verliert keine Zeit; Erinnerungs-Uhr-Reset; doppelte Bestätigung committet erst im zweiten Schritt.

## Design
Farbe **Sage** (Zeit). Entwürfe: `entwuerfe/mykilOS_Stundentimer_Entwurf.html`, `entwuerfe/mykilOS_Timer_Erinnerung_Bestaetigung_Entwurf.html`. Design-Tokens, kein Hardcoding.

## Offene Fragen (falls unbeantwortet → Johannes fragen)
- Timer-Wechsel zwischen Projekten: auto-umschalten oder nachfragen?
- Puls bei Ignorieren: dauerhaft oder nach ~5 Min beruhigen bis zur nächsten Marke?
