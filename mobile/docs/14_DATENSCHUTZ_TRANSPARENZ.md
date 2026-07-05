# Datenschutz & Transparenz-Doktrin — Sichtbare, bestätigte Macht

**Grundsatz (Johannes, Nacht 04.07.):** „Unsere Power muss immer auch sichtbar
und bewusst bestätigt oder abgelehnt werden können." Gilt für JEDE Fähigkeit
des Satelliten — nicht nur fürs Schreiben (das die RAILs schon regeln), sondern
für jeden Sensor-*Zugriff* selbst.

## Die Erweiterung der bestehenden RAILs

Bisher galt: **Writes** sind gated (Karte→Bestätigung→Audit). Ab jetzt gilt
zusätzlich: **jede sensible Fähigkeits-NUTZUNG** ist sichtbar UND widerrufbar —
auch wenn sie nur liest oder nur lokal bleibt (Mikro, GPS-Speicherung, Kamera-
Dauerlauf, Bewegungsdaten).

## Die vier Mechanismen

1. **Opt-in, nie Opt-out.** Jede Fähigkeit (Standort, Mikro, Bewegung, Kamera-
   Dauererkennung) startet AUS. Der Nutzer schaltet bewusst ein — nicht „schon
   aktiv, bis wer widerspricht".
2. **Sichtbarkeit erzwungen, nicht nur versprochen.** iOS zeigt selbst schon den
   grünen/orangen Punkt bei Kamera/Mikro — wir **verstärken** das, statt es zu
   umgehen: ein sichtbares „Fähigkeiten"-Panel in der App zeigt jederzeit, was
   gerade an ist, mit Klartext-Namen (nicht „Standortdienste", sondern „Ich weiß
   gerade, wo du bist, um Projekte vorzuschlagen").
3. **Bestätigung im Moment, nicht nur beim Erstlauf.** Ein sensibler Fang
   (Mitschnitt-Start, Adress-Vorschlag aus GPS, Foto-Upload) zeigt eine Karte —
   **auch wenn er nur liest.** „Ja, ab in die Drive damit" (Johannes' eigener
   Satz) ist das Muster: nie stillschweigend.
4. **Jederzeit widerrufbar, ein Schalter, keine Odyssee.** Nicht „geh in die
   iOS-Einstellungen, dann App, dann Berechtigung" — ein Kippschalter direkt im
   Fähigkeiten-Panel. Widerruf ist so leicht wie Zustimmung.

## Auditierbarkeit (wie das Mothership es schon lebt)

Jede Aktivierung/Nutzung landet in einem lokal einsehbaren Protokoll — analog
zum `AuditEntry`-Muster des Schiffs. Der Nutzer kann jederzeit fragen: „Was hat
der Satellit diese Woche gesehen/gehört/gespeichert?" und eine ehrliche Antwort
bekommen.

## Warum Apples eigene Mauer uns hilft, nicht behindert

Dass iOS keine Anruflisten an Apps gibt (siehe Peilung „Telefon-Logs"), ist ein
Beleg: **die Plattform denkt in unsere Richtung.** Wo Apple selbst eine Tür
zusperrt, ist das kein Verlust für uns — es ist Bestätigung, dass diese Tür
zubleiben sollte. Die App baut nie eigene Umgehungen um solche Mauern.

## Per-User (Team-Kontext, geerbt)

Alles hier gilt **pro Nutzer isoliert** — Fraukes Fähigkeiten-Panel, Fraukes
Audit-Log, Fraukes Widerruf. Nie teamweit sichtbar, nie zentral einsehbar durch
andere. Deckt sich mit der Mothership-Regel „Mail/Memos/Assistent nie
kreuzlesbar".

## DSGVO-Anker (kurz, kein Rechtsgutachten)

Datenminimierung (Art. 5) → Audio verglüht, Transkript bleibt. Rechtsgrundlage
Einwilligung (Art. 6/7) → Opt-in + jederzeitiger Widerruf. Kein Verzeichnis-
Ersatz, aber die Architektur macht ein Verarbeitungsverzeichnis leicht führbar,
falls das Studio wächst.

## Portfolio ≠ Dokumentation — eigenes Einverständnis (ab 04.07.)

Ein Foto fürs interne Projekt und ein Foto fürs öffentliche Portfolio/Marketing
sind KATEGORIAL verschieden — auch wenn es dasselbe Bild ist. Portfolio-Nutzung
braucht eine EIGENE, separate Bestätigung („Darf das öffentlich/als Referenz
gezeigt werden?"), nie automatisch aus der Projekt-Ablage-Zustimmung mitgezogen.
Eigener Audit-Eintrag, eigener Widerruf.

## Konsequenz für den Ideen-Katalog

Jeder Helper mit Mikro/GPS-Dauerlauf/Kamera-Hintergrund (Werkstatt-Modus,
Ankunfts-Trigger, Transport-Wächter) bekommt beim Bau ZWINGEND diesen Layer —
kein Helper ist von der Sichtbarkeitspflicht ausgenommen, egal wie nützlich.
