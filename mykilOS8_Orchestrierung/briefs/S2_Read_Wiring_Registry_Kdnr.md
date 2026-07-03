# Brief · S2 — Read-Wiring + Registry-Kdnr

**Modell:** Opus 4.8 (Designpass: Kdnr-Erweiterung + Sevdesk-Kontrakt) → Sonnet 4.6 (Implementierung) · **Gate:** keins (nur Lesen + lokales Feld) · **Abhängigkeit:** S1 · **Schreibt extern:** NEIN.

## Auftrag
Verbinde die Lese-Quellen und schließe den Soll/Ist-Loop — ohne externen Write.

## Umfang
- **ExternalMappingRegistry:** `Kdnr` als zweiten kanonischen Schlüssel neben `kunde`-Token + Projektnummer einführen (Modell in `02_Kanonisches_Modell.md`). Designpass zuerst — Kunden- vs. Projektebene sauber trennen.
- **Soll-Stunden** aus Sevdesk `Order`/`OrderPos` lesen (strukturierte Angebotsposition, kein PDF). **Datenqualitäts-Check:** an einer Stichprobe echter Angebote prüfen, ob Montagestunden als eigene quantifizierte Position geführt werden; falls nicht, an Johannes zurückmelden.
- **Kostenstellen** live aus dem Airtable-Projektfeld (löst den Mock aus S1 ab).
- **Ist-Stunden** aus Clockodo **aggregiert/anonymisiert** je Kostenstelle/Projekt. Prüfen, ob Clockodo gruppierte Reports liefert oder client-seitig aggregiert werden muss — **bevor** etwas Personenbezogenes gespeichert/angezeigt wird.
- **Verkaufsbalken in %** im Geld-Widget (Indigo), rollend; > 100 % → Coral. **Zielkontingent** aus Soll initialisieren, manuelle Edits **pinnen** (Herkunfts-Flag).

## Tests (Pflicht)
Registry löst Kdnr↔Token↔Projekt korrekt auf; Sevdesk-Positions-Parsing; Aggregation ist anonym (kein Personenbezug); Verkaufsbalken-% korrekt; manuelles Zielkontingent überlebt ein Re-Read.

## Design
Geld-Widget Indigo, Risiko Coral. Entwurf: `entwuerfe/mykilOS_ClickUp_im_Projekt_Entwurf.html` (Widget-Sprache).
