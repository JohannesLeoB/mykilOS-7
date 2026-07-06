# 🗺️ Feature-Vision-Index (Stand 2026-07-06)

**Der eine Überblick.** Johannes hat am 2026-07-06 eine zusammenhängende Produkt-Vision ausgelegt —
hier gebündelt, mit Verweis auf die Detailpläne. Alles unter EINEM Prinzip: dem Schaltschrank.
Lebendes Dokument — wächst weiter, wenn neue Stränge dazukommen.

## Das verbindende Prinzip
**[docs/PRINZIP_SCHALTSCHRANK.md](PRINZIP_SCHALTSCHRANK.md)** — jede Verknüpfung ist eine benannte,
umsteckbare Klemme (Quelle → Route → Ziel), nie hart verdrahtet. Gilt für ALLE Stränge unten.

## Die Stränge

| # | Strang | Plan | Fundament | Größe |
|---|---|---|---|---|
| 1 | **Login-Wege & Datenflüsse** — Google-SSO-Eingang, 6 Dienste (OAuth vs. Key), Sevdesk-Budget aus Drive/Warenkorb | [VISION_LOGIN_UND_DATENFLUSS.md](VISION_LOGIN_UND_DATENFLUSS.md) | Google/Clockodo/Airtable/Claude ✅ | mittel |
| 2 | **Datenschutz-Sektion pro User** — was teile ich / gebe ich frei, „KI-aus", Daten-Export | (in Vision-Doc §Nutzerprofil) | Kategorie-Tab da, Inhalt dünn | mittel · Wording nötig |
| 3 | **ClickUp-Datenintegration** — Aufgaben/Fälligkeiten/Meilensteine/Status + 13 Custom Fields | [handoffs/CLICKUP_DATENINTEGRATION_PLAN.md](handoffs/CLICKUP_DATENINTEGRATION_PLAN.md) | Adapter + Tasks-Widget ✅ | mittel |
| 4 | **Ordner-Schema-Editor** — Admin gibt Muster-Struktur an, neue Projekte danach angelegt · + Mail-Anhang→Marker→Unterordner | [handoffs/ORDNER_SCHEMA_EDITOR_PLAN.md](handoffs/ORDNER_SCHEMA_EDITOR_PLAN.md) | ~70 % (Schema/Builder/Store) ✅ | groß · Drive-Write GO |
| 5 | **Scanner-Ausbau** — QR→Link, Visitenkarte→Kontakt, EAN/ART-NO→Katalog→Warenkorb | [handoffs/SCANNER_AUSBAU_PLAN.md](handoffs/SCANNER_AUSBAU_PLAN.md) | Scanner/Kontakte/Wirbelsäule ✅ | mittel-groß |
| 6 | **Aufmaß-Widget** — BT-Laser, iPhone-Foto→Mac, Point-to-Point-Maßlinien, Fullscreen | [handoffs/AUFMASS_WIDGET_PLAN.md](handoffs/AUFMASS_WIDGET_PLAN.md) | Overlay-Muster ✅ · Laser vom Satellit portierbar | groß · Hardware |

## Offene Johannes-Entscheidungen (blocken jeweils einen Strang)
- **Projekt-Status-Definition** (ClickUp-Phase / Lebenszyklus-Stepper / Ableitung) → Strang 3
- **ClickUp-OAuth-App registrieren** (client_id/secret) → Login-Fenster, Strang 1
- **Datenschutz-Freigabe-Texte / Toggle-Semantik** → Strang 2
- **Lager-Ziel-Base** (mykilOS-eigene, Daniels bleibt READ ONLY) + welche Kataloge EAN-durchsuchbar → Strang 5
- **Laser-Modell + Foto-Andock-Kanal** Satellit→Mac → Strang 6
- **Drive-Write-GO** (raus aus Sandbox) → Strang 4

## Empfohlene Bau-Reihenfolge (kleinster Aufwand / größter Nutzen zuerst)
1. **QR→Link** (Strang 5A) + **Mail-Marker-Ausbau** (Strang 4) — Fundament da, in Stunden sichtbar, kein GO nötig.
2. **ClickUp `FieldRoute`-Registry** (Strang 3) — read-only, voll testbar, Schaltschrank-Referenzimplementierung.
3. **Ordner-Schema editierbar** (Strang 4, Stufe 1) — kein Drive-Write, testbar.
4. Größere/GO-/Hardware-Stränge (Scanner-Lager, Aufmaß, echter Drive-Write) — je mit eigener Session + Live-Abnahme.

## Bereits gebaut (2026-07-06, in `main`-Kandidat `feat/multi-user-login`)
Multi-User-Identität komplett + reviewt · Nutzerprofil · Start-Ansicht · 3 UI-Feedback-Fixes ·
Swift-6-Fix. Details: [handoffs/HANDOFF_2026-07-06_SESSION_ABSCHLUSS.md](handoffs/HANDOFF_2026-07-06_SESSION_ABSCHLUSS.md).
