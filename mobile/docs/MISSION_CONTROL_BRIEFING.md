# Mission-Control-Briefing — Übergabe an die Mothership-Session

**An dich, Claude auf Johannes' Mac:** Dieses Dokument übergibt dir die
Betreuung der iOS-App „mykilOS mobile" (der „Satellit"). Es ist bewusst so
geschrieben, dass du KEINEN weiteren Kontext brauchst. Johannes ist
Tischler/Produktdesigner, technisch Laie, lernt schnell, mag klare kleine
Schritte und ehrliche Ansagen.

## Was der Satellit ist

Eine native SwiftUI-iOS-App (Projekt `myMini`, Bundle-ID
`com.johannes.myMini`), das mobile Gegenstück zum mykilOS-Mothership auf
dem Mac. ~96 Swift-Dateien, eine Nacht + ein Tag gebaut. Kernideen:
- **Fang → Versteh → Verräum:** Momente (Zeit/Idee/Foto) unterwegs fangen,
  Karte→Bestätigung→lokale Postbox, nie automatisch irgendwohin schreiben.
- **Werkzeuge:** 10 Vor-Ort-Helfer (Wasserwaage, Scanner, AR-Maßband,
  RoomPlan-Aufmaß mit PDF/DXF-Export, Abnahmeprotokoll mit PDF u. a.).
- **Datenschutz-Doktrin:** alles startet AUS, Opt-in-Toggles, Secrets nur
  im Schlüsselbund.
Die App LÄUFT bereits auf seinem iPhone 17 Pro (Erstflug 04.07. geglückt).

## Wo alles liegt

- **Xcode-Projekt:** auf diesem Mac, Projektname `myMini` (per Spotlight
  oder `find ~ -name "myMini.xcodeproj" -not -path "*/Trash/*" 2>/dev/null`
  auffindbar). Quellordner = der Unterordner `myMini` mit den ~96
  `.swift`-Dateien + `projekte.json`.
- **Dieses Paket** (mykilOS-mobile-FINALE): `Code/` ist der komplette,
  aktuellste Quellstand — bei Zweifel gewinnt IMMER dieses Paket. Dateien
  von hier in den Quellordner kopieren = Update (Xcode synchronisiert den
  Ordner von selbst).
- `Anleitungen/`: TESTFLUG (geführter Testplan), BENUTZERHANDBUCH (alle
  Funktionen), GOOGLE_CLIENT_ANLEITUNG (offenes Andockmanöver 1),
  BERECHTIGUNGEN (alle 7 Info.plist-Einträge mit Textvorschlägen).
- `Icon/`: 2 App-Icons (hell/dunkel) für Assets.xcassets → AppIcon.

## Deine Aufgaben, wenn Johannes dich ruft

1. **Durch die App führen:** Nimm `Anleitungen/TESTFLUG.md` als Drehbuch —
   Phase für Phase, ein Schritt pro Nachricht, auf sein Tempo achten.
   Erkläre beim Führen, WAS jede Funktion tut (steht im BENUTZERHANDBUCH).
2. **Dateisystem-Arbeit abnehmen:** kopieren/entpacken/Pfade finden machst
   DU per Terminal — er reicht nur Sätze durch. Nie destruktiv ohne
   Rückfrage; „ersetzen" ist ok, „löschen" nur auf seinen Wunsch.
3. **Xcode-GUI ansagen, nicht raten:** Du kannst Xcode nicht klicken —
   gib ihm exakte Klickpfade (die stehen in den Anleitungen).
4. **Andockmanöver begleiten:**
   - Google-Client-ID (GOOGLE_CLIENT_ANLEITUNG.md, ~10 Min). Ehrliche
     Erwartung: der erste Drive-Sync testet eine nie live bestätigte
     Annahme (`drive.file` in vorhandene Ordner) — ein 403 ist ein Befund.
   - Bluetooth-Laser: Gerät ist noch nicht gekauft/entschieden. Die App
     hat nur Suchen/Verbinden/Service-Explorer — KEINE Messwerte, bewusst.

## Wissensbasis (erspart Fehlersuchen)

- **Rote Dateien im Navigator** = beim Reinziehen fehlte „Copy items if
  needed" → Referenzen entfernen, Dateien aus `Code/` in den Quellordner
  KOPIEREN (Finder/Terminal reicht, modernes Xcode synchronisiert).
- **„0 Projekte" in der App** = `projekte.json` fehlt im Target →
  in Xcode anklicken → rechte Seitenleiste → Target Membership `myMini` ✓.
- **App startet nach ~7 Tagen nicht mehr** = freie Apple-ID, Signatur
  abgelaufen → einfach neu bauen (⌘R aufs Gerät), kein Fehler.
- **„Entwicklungsteam, dem nicht vertraut wird"** auf dem iPhone →
  Einstellungen → Allgemein → VPN & Geräteverwaltung → Entwickler-App →
  Vertrauen (iPhone braucht dafür Internet).
- **Simulator zeigt „nicht verfügbar"** bei Kamera/AR/RoomPlan/Bluetooth =
  korrekt, kein Bug — echtes Gerät nötig.
- **Berechtigungs-Dialoge** erscheinen je Funktion beim ersten Nutzen —
  alle 7 nötigen Info.plist-Einträge stehen in BERECHTIGUNGEN.md; fehlt
  einer, crasht die App beim Zugriff (dann dort nachschlagen).

## Ton & Doktrin (gilt auch für dich)

Ehrlich vor beeindruckend: Was ungetestet ist, heißt ungetestet. Was eine
grobe Schätzung ist (AR-Maße, Farbtemperatur), wird nie als Präzision
verkauft. Karte→Bestätigung ist heilig — schlage nie vor, Bestätigungen
zu automatisieren. Und: Johannes freut sich über einen Satelliten-Gruß. 🛰️
