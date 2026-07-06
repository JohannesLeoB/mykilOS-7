# 📐 Aufmaß-Widget — Startplan (Johannes 2026-07-06)

**Ziel:** Ein Aufmaß-Widget auf dem Mac: **Bluetooth-Laser** gekoppelt, **iPhone-Foto an den Mac**
geschickt, dann per **Point-to-Point-Klick auf dem Foto Maßlinien zeichnen** und die Linie **mit dem
Maß des gekoppelten Lasers befüllen**. **Fullscreen-Modus.** Referenz: die **Aufmaß-Funktion des
iOS-Satelliten** (gleiche DNA).

```
Regel:  Schaltschrank — Laser = Quelle (Maß), Maßlinie = Ziel; Laser-Typ steckbar (Adapter).
        Hardware-Test braucht echtes Gerät (Johannes). Satellit-Protokoll wiederverwenden.
```

## Ist-Stand

| Baustein | Wo | Stand |
|---|---|---|
| **Overlay-Zeichnen auf Foto** (Point-Picker) | `Sources/MykilosApp/Detail/ProjectHeroView.swift` (Fadenkreuz-/Fokus-Picker) | ✅ Muster da |
| **Laser + Disto-Protokoll** | **iOS-Satellit** (`LeicaDistoProtokoll`, `LaserAdapter`) — anderes Repo | ✅ existiert, portierbar |
| **Bluetooth-Kopplung (CoreBluetooth)** auf Mac | — | 🔴 Neubau |
| **Foto-Empfang iPhone → Mac** (Satellit-Andock-Kanal) | — | 🔴 Neubau (fehlt auf Mac) |
| **Aufmaß-Canvas + Fullscreen** | — | 🔴 Neubau |

## Bauplan (klein, in Reihenfolge)

1. **Disto-Protokoll teilen/portieren.** `LeicaDistoProtokoll` (Foundation-only) vom Satelliten in
   eine gemeinsame Kit-Schicht heben (oder verbatim portieren) — **eine Quelle für beide Häuser**.
2. **`LaserPort` (Schaltschrank-Adapter).** Protokoll `LaserMeasuring { verbinde(), letztesMaß:
   AsyncStream<Double> }`. Leica-Disto = erster Adapter; anderer Laser-Typ = anderer Adapter, kein
   Umbau der Canvas.
3. **CoreBluetooth-Kopplung (Mac).** `CBCentralManager` → Disto koppeln, Messwerte lesen. Renderstates
   (suchen/gekoppelt/getrennt/Fehler). Entitlement `com.apple.security.device.bluetooth` prüfen.
4. **Foto-Empfang Satellit → Mac.** Der fehlende Andock-Kanal: iPhone schickt Foto, Mac empfängt.
   (Kanal-Design mit dem Satelliten abstimmen — gleicher Andock wie andere Satellit-Daten.)
5. **Aufmaß-Canvas (Fullscreen).** Foto + Point-to-Point-Linien-Overlay (ProjectHeroView-Muster):
   Klick A → Klick B → Linie. Aktive Linie **befüllt sich mit dem letzten Laser-Maß** (aus dem
   AsyncStream). Mehrere Linien, Werte editierbar, exportierbar (Projekt/Drive).
6. **Persistenz** je Projekt (Cold-Start-Test): Linien + Maße überleben Neustart.

## Schaltschrank-Sicht
Laser (Quelle) → Maßlinie (Ziel) ist eine **steckbare Route**: die aktive Linie „lauscht" auf den
Laser-Stream. Neuer Laser-Typ = neuer `LaserPort`-Adapter, sonst nichts. Deckt sich mit dem
FieldRoute-/Port-Muster (ClickUp, Scanner). Der Satellit teilt das Protokoll → EIN Aufmaß-Kern,
zwei Oberflächen (Mac klick-getrieben, iPhone am Gerät).

## Offen für Johannes
- **Welcher Laser** (Leica Disto Modell / BLE-Profil)? Bestimmt den ersten Adapter.
- **Foto-Andock-Kanal** Satellit→Mac: gleiches Transport wie geplant für andere Satellit-Daten?
- Hardware-Test nur mit echtem Gerät möglich — Live-Abnahme durch Johannes.
