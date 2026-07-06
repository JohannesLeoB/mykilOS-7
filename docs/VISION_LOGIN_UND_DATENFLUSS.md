# 🔐 Vision — Login-Wege, Nutzerprofil & Datenflüsse

**Lebendes Dokument.** Johannes' zusammenhängende Architektur für Identität, Anmeldung und
Datenzufluss, festgehalten 2026-07-06 (Nacht/Vormittag). Wächst weiter — hier steht das *Bild*,
bevor gebaut wird. Bau-Reihenfolge + Status unten.

```
Pfad:   /Users/johannesleoberger/Claude/Projects/mykilOS/MYKILOS 6/mykilOS Mac/
Branch: feat/multi-user-login
Regel:  Ziel zuerst · klein bauen · Johannes prüft jede Stufe live · nichts extern ohne GO
```

## Der eine Eingang

> **Zugang IN die App = dein Google-Konto (SSO).** Ein Login, um überhaupt in mykilOS zu kommen.
> Beim Neustart persistiert die Anmeldung — du gibst sie nicht jedes Mal neu ein.

## Die sechs Dienste — zwei Klassen

Nicht alles läuft gleich. Dienste mit eigenem OAuth machen ihren **Selbst-Login** (Browser-Fenster,
kein Secret in mykilOS). Dienste mit nur einem Key bekommen eine **Maske** (oder liefern später aus
1Password).

| Dienst | Wie man sich anmeldet | mykilOS speichert | Klasse |
|---|---|---|---|
| **Google** | SSO (Eingang), OAuth | Tokens (Keychain, persistent) | Selbst-Login ✅ steht |
| **ClickUp** | Login-**Fenster** (OAuth), eigener Account je Bewohner | nur zurückkommendes Token | Selbst-Login 🔨 Umbau Token→OAuth |
| **Clockodo** | Maske in der App: **Mail + API-Key** ¹ | Mail + Key (Keychain) | Key-Maske ✅ steht |
| **Sevdesk** | Durchgangs-**Fenster** zu sevdesk.de | **NICHTS** — kein Key, kein API | Nur Durchgang 🔨 API raus |
| **Airtable** | Team-PAT (geteilt) | PAT (Keychain, geteilt) | Key ✅ steht |
| **Claude** | Anthropic API-Key | Key (Keychain) | Key ✅ steht |

¹ Clockodo hat **kein** OAuth-Login-Fenster — die API kennt kein „Mail+Passwort". Der API-Key
(≠ Login-Passwort) steht in den Clockodo-Einstellungen.

**Sevdesk = „bleibt Hausmeister":** kein persönlicher Zugang pro Bewohner, keine gespeicherten
Schlüssel, kein API-Zugriff — nur ein Fenster zum manuellen Anmelden. Deckt sich mit der eisernen
Regel „Sevdesk nie lesen/schreiben, nur über den Briefkasten".

## Sevdesk-Budget → Cash-Widget (ohne API)

Das Cash-Widget (Ist vs. Budget) bezieht das **Budget** künftig NICHT mehr per Sevdesk-API, sondern
auf einem von zwei mykilOS-internen, read-only Wegen:

1. **Datei:** die Auftragsbestätigung als **PDF im Projekt-Drive-Ordner** → mykilOS liest read-only
   (bestehende `DriveOfferWatcher` / Angebote-Linie).
2. **Briefkasten:** die Auftragsdaten des **„gekauften" Warenkorbs** — direkt auf der Wirbelsäule:
   - „gekaufter Warenkorb" = `WorkBasket` im Status **`.bestaetigt`**
   - „Briefkasten mit Auftragsdaten" = **CheckoutPort / Sevdesk-Postbox**
   - → Budget = Auftragswert dieses bestätigten Warenkorbs

Sevdesk reicht also nur Dokumente/Daten rüber; mykilOS schreibt nie zurück. (Eigener späterer
Strang „Cash-Widget-Neubau".)

## Nutzerprofil & Datenschutz (neu, Johannes 2026-07-06)

- **Nutzerprofil vertiefen:** die Settings-Ebene ist zu flach. Ein „richtiges, schönes"
  Nutzerprofil — mehr als Name/Rolle: Geburtsdatum, weitere Personendaten. (Was genau → beim Bau
  konkretisieren; lokal-first, im Personalausweis verankert.)
- **Datenschutz-Einstellungen pro User:** jeder Bewohner steuert selbst, **was er teilt / was nicht
  / was er freigibt**. Baut auf der bereits dokumentierten Per-User-Isolations-Regel auf (Mail/
  Memos/Chat/Clockodo nie kreuzlesbar) — jetzt als **sichtbare, editierbare UI**. ⚠️ Die konkreten
  Freigabe-/Rechtstexte + Toggle-Semantik brauchen Johannes' Wording (keine eigenmächtigen
  Rechtstexte — so im Backlog verankert). Wunsch aus dem Backlog dazu: einzeln toggelbar (opt-in/
  opt-out, kein Blanko-Konsens), globaler „KI komplett aus"-Schalter, „meine Daten exportieren"
  (DSGVO Art. 15/20).

## Bau-Reihenfolge & Status

| # | Stufe | Baubar autonom? | Status |
|---|---|---|---|
| 1 | Vision festhalten (dies) | ✅ | ✅ erledigt |
| 2 | Nutzerprofil vertiefen (Geburtsdatum & Co. + schöne Ebene) | ✅ voll | 🔨 in Arbeit |
| 3 | Datenschutz-Sektion pro User (UI-Gerüst) | 🟡 UI ja, Texte = Johannes | ⬜ |
| 4a | Loopback-OAuth-Server dienstneutral machen (Refactor) | ✅ voll | ⬜ |
| 4b | ClickUp Token→OAuth-Login-Fenster | 🟡 braucht ClickUp-App-Reg (client_id/secret) von Johannes | ⬜ |
| 5 | Sevdesk API→Durchgangs-Fenster (Cash-Widget entkoppeln) | ✅ (Widget-Neubau später) | ⬜ |
| 6 | 1Password-Autofill für Key-Masken (Clockodo/Airtable/Claude) | 🟡 Phase 2, `op`-Prototyp zuerst | ⬜ |

**Johannes-Input, den ich später brauche:** (a) ClickUp-OAuth-App registrieren (client_id/secret),
(b) Datenschutz-Freigabe-Texte + welche Profilfelder genau, (c) Live-Abnahme je Stufe.

**Bereits geklärt (2026-07-06, `op`-Test):** 1Password = Firmen-Business (`mykilosgmbh.1password.com`),
Vaults `Employee` (persönlich) + `MK Team` (geteilt); `op`-CLI läuft ohne TTY-Hang. Details:
Chat-Verlauf + `HANDOFF_2026-07-05_SPAET2` §7.5.
