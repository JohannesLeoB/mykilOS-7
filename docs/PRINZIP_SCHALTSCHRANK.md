# 🔌 Prinzip: Der Schaltschrank (Johannes 2026-07-06)

**Leitprinzip für ALLE Verknüpfungen in mykilOS.** Verbindlich für jede neue Weiche/Route —
insbesondere den ClickUp-Custom-Field-Übertrag, die Sevdesk-/Drive-/Airtable-Wege und künftige.

## Das Bild

Ein Schaltschrank verdrahtet nicht Gerät-an-Gerät fest. Er hat **Klemmen mit festen Nummern**;
die Brücke zwischen zwei Klemmen ist **gesteckt, nicht gelötet**. Man kann später umstecken, eine
Ader auf eine andere Klemme legen oder eine neue Quelle andocken — **ohne die Enden umzubauen**.

Übertragen auf mykilOS:

> **Jede Verknüpfung ist eine benannte, umsteckbare Klemme — nie eine harte Code-Verdrahtung.**

## Die vier Regeln

1. **Quelle und Ziel sind entkoppelt** (Port/Adapter). Kein `if feldName == "Budget" { projekt.budget = … }`
   direkt im Code — Quelle liefert *typisierte Werte*, Ziel *nimmt sie entgegen*, die **Zuordnung
   dazwischen ist Konfiguration**.
2. **Jede Klemme hat eine stabile ID** (`routingID` / `integrationID`), nie den Klartext-Namen als
   Schlüssel (Namen ändern sich, IDs bleiben — bestehende CLAUDE.md-Regel).
3. **Die Verdrahtung ist eine Registry, kein Code** — eine persistente, (perspektivisch) editierbare
   Routing-Tabelle. Umlegen = Tabellen-Eintrag ändern, nicht neu kompilieren.
4. **Zentral registriert + sichtbar** — jede Weiche steht im Datenstrom-Handbuch (`tblaUVftka0GvXzeU`)
   und wird über `DataFlowLogger.log(integrationID:)` protokolliert.

## Was es konkret für den Custom-Field-Übertrag heißt

**NICHT:** 13 harte `if`-Zweige, die ClickUp-Felder auf mykilOS-Felder mappen.
**SONDERN:** eine `FieldRoute`-Registry —

```
FieldRoute { routeID, quelle: ClickUp-Field-ID, ziel: mykilOS-Slot, transform?, aktiv }
```

— sodass „Budget (€) → Cash-Widget" morgen zu „Budget (€) → Sevdesk-Briefkasten" oder „→ neues
Feld X" wird, indem man EINE Route-Zeile umlegt. Neue Custom Fields = neue Route-Zeile, kein Code.
Der Adapter liest `custom_fields` schon generisch (`CustomFieldEntity`) — die Registry entscheidet,
wohin. Gleiches Muster für Sevdesk-Budget-Wege (Datei ODER Warenkorb-Briefkasten) und Drive.

## Bestehende Bausteine, die den Schaltschrank schon verkörpern

- **`ClickUpRouting`** (`Sources/MykilosKit/Domain/ClickUpRouting.swift`) — Routing-Zeilen mit IDs.
- **Datenstrom-Handbuch** (Airtable) + **`DataFlowLogger`** — zentrale Weichen-Registrierung.
- **Port-Protokolle** (CheckoutPort, KalkulationsEngineProviding, DriveOrdnerProvisioning) —
  Quelle/Ziel entkoppelt, Adapter injizierbar.
- **`OrdnerKonnektor`** / `NomenklaturStore` — Slot→Ordner als umlegbare Zuordnung (Ordner-Schema).
- **Referenz-Felder** (`clickUpListID`, `driveFolderID`) — IDs, keine harten Namen.

## Konsequenz für die Pläne
- `CLICKUP_DATENINTEGRATION_PLAN.md` — der Custom-Field-Übertrag wird als `FieldRoute`-Registry gebaut.
- `ORDNER_SCHEMA_EDITOR_PLAN.md` — Schema + Konnektoren sind schon umlegbar (Slot→Ordner).
- `VISION_LOGIN_UND_DATENFLUSS.md` — Sevdesk-Budget-Wege (Datei/Briefkasten) als steckbare Routen.
